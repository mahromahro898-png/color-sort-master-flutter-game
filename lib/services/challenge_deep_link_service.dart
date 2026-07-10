/// ══════════════════════════════════════════════════════════
///  challenge_deep_link_service.dart
///  Serviço de Deep Linking - Gerenciamento de rotas externas (Cold/Warm Starts) e transição fluida para o modo multiplayer (Matchmaking)
/// ══════════════════════════════════════════════════════════
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../screens/game_screen.dart';
import 'challenge_service.dart';

class ChallengeDeepLinkService {
  ChallengeDeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static bool _initialized = false;

  static Future<void> init() async {
    // Prevenção de inicialização múltipla (Singleton Behavior estrito)
    if (_initialized) return;
    _initialized = true;

    // Captura do payload inicial caso o aplicativo tenha sido aberto através do link a partir do estado encerrado (Cold Start)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // Inscrição reativa na stream para capturar Deep Links enquanto o aplicativo já está em execução (Warm/Hot Start)
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  static Future<void> _handleUri(Uri uri) async {
    // Validação estrita de esquema e host para mitigar execuções indevidas (Security & Payload Validation)
    if (uri.scheme != 'colorsort') return;
    if (uri.host != 'challenge') return;

    final matchId = uri.queryParameters['id'];
    if (matchId == null || matchId.isEmpty) return;

    try {
      await ChallengeService.joinChallenge(matchId);

      final snapshot = await ChallengeService.challengeRef(matchId).get();
      final data = snapshot.data();

      if (data == null) return;

      final level = data['level'] as int? ?? 80;

      // Injeção segura no Event Loop: Garante que a navegação (Routing) ocorra apenas quando a árvore de widgets estiver estabilizada, evitando exceções de ciclo de vida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = rootNavigatorKey.currentContext;
        if (context == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              startLevel: level,
              isChallengeMode: true,
              challengeMatchId: matchId,
            ),
          ),
        );
      });
    } catch (e) {
      debugPrint('DEEP LINK CHALLENGE ERROR: $e');
    }
  }
}