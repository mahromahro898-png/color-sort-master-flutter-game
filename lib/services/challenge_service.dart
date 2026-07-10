/// ══════════════════════════════════════════════════════════
///  challenge_service.dart
///  Serviço Multiplayer (Backend as a Service) - Gerenciamento de estado sincronizado via Firebase Firestore com controle transacional rigoroso
/// ══════════════════════════════════════════════════════════
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeService {
  ChallengeService._();

  static final _firestore = FirebaseFirestore.instance;

  // Gerenciamento de Identidade Local (Local Persistence / UUID Generation)
  static Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? playerId = prefs.getString('challenge_player_id');

    if (playerId == null) {
      playerId =
      'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      await prefs.setString('challenge_player_id', playerId);
    }

    return playerId;
  }

  static String generateMatchId() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  static DocumentReference<Map<String, dynamic>> challengeRef(String matchId) {
    return _firestore.collection('challenges').doc(matchId);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchChallenge(
      String matchId,
      ) {
    return challengeRef(matchId).snapshots();
  }

  // Criação de Sala (Matchmaking Host) - Configuração do estado inicial
  static Future<String> createChallenge({
    required int level,
    required int seed,
  }) async {
    final matchId = generateMatchId();
    final uid = await getCurrentUserId();

    await challengeRef(matchId).set({
      'matchId': matchId,
      'level': level,
      'seed': seed,
      'status': 'waiting',
      'hostId': uid,
      'guestId': null,
      'hostTimeMs': null,
      'guestTimeMs': null,
      'winnerId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return matchId;
  }

  // Conexão de Oponente (Matchmaking Guest) - Uso de transações (Atomic Operations) para evitar Race Conditions na concorrência
  static Future<void> joinChallenge(String matchId) async {
    final uid = await getCurrentUserId();
    final ref = challengeRef(matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Challenge not found');
      }

      final data = snapshot.data()!;
      final status = data['status'];
      final hostId = data['hostId'];
      final guestId = data['guestId'];

      if (hostId == uid) {
        return;
      }

      // Validação rigorosa de estado e integridade
      if (guestId != null && guestId != uid) {
        throw Exception('Challenge already has opponent');
      }

      if (status != 'waiting' && status != 'playing') {
        throw Exception('Challenge is not available');
      }

      transaction.update(ref, {
        'guestId': uid,
        'status': 'playing',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Submissão de Resultados (Game Loop Resolution) - Garantia de consistência de dados através de blocos transacionais
  static Future<void> submitFinishTime({
    required String matchId,
    required int timeMs,
  }) async {
    final uid = await getCurrentUserId();
    final ref = challengeRef(matchId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Challenge not found');
      }

      final data = snapshot.data()!;
      final hostId = data['hostId'];
      final guestId = data['guestId'];

      final bool isHost = uid == hostId;
      final bool isGuest = uid == guestId;

      // Proteção de Endpoint (Authorization check / RBAC simplificado)
      if (!isHost && !isGuest) {
        throw Exception('User is not part of this challenge');
      }

      final fieldName = isHost ? 'hostTimeMs' : 'guestTimeMs';

      transaction.update(ref, {
        fieldName: timeMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final hostTime = isHost ? timeMs : data['hostTimeMs'];
      final guestTime = isGuest ? timeMs : data['guestTimeMs'];

      // Resolução determinística da partida no servidor após o recebimento dos dois payloads
      if (hostTime != null && guestTime != null) {
        final winnerId = hostTime <= guestTime ? hostId : guestId;

        transaction.update(ref, {
          'winnerId': winnerId,
          'status': 'finished',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}