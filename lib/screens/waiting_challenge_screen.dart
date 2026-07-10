/// ══════════════════════════════════════════════════════════
///  waiting_challenge_screen.dart
///  Tela de Espera do Modo Desafio (Matchmaking) - Sincronização em tempo real via Streams com Firestore
/// ══════════════════════════════════════════════════════════
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/challenge_service.dart';
import 'game_screen.dart';

class WaitingChallengeScreen extends StatefulWidget {
  final String matchId;

  const WaitingChallengeScreen({
    super.key,
    required this.matchId,
  });

  @override
  State<WaitingChallengeScreen> createState() => _WaitingChallengeScreenState();
}

class _WaitingChallengeScreenState extends State<WaitingChallengeScreen> {
  bool _openedGame = false;

  void _openGame(Map<String, dynamic> data) {
    // Guarda de estado para prevenir navegação duplicada (Race condition prevention na transição de telas)
    if (_openedGame) return;
    _openedGame = true;

    final level = data['level'] as int? ?? 80;

    // Agendamento seguro da navegação após o término do build atual (Evita exceções de ciclo de vida do Flutter)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            startLevel: level,
            isChallengeMode: true,
            challengeMatchId: widget.matchId,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(l10n.challenge),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      // Escuta reativa (Real-time listener) do documento da partida no banco de dados NoSQL
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ChallengeService.watchChallenge(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.error_outline,
              title: l10n.challengeLoadError,
              subtitle: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return _MessageState(
              icon: Icons.search_off,
              title: l10n.challengeNotFound,
              subtitle: widget.matchId,
            );
          }

          final status = data['status'] as String? ?? 'waiting';

          if (status == 'playing') {
            _openGame(data);
          }

          if (status == 'finished') {
            return _MessageState(
              icon: Icons.emoji_events,
              title: l10n.challengeFinished,
              subtitle: l10n.challengeFinishedDescription,
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 96,
                  ),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(color: Colors.amber),
                  const SizedBox(height: 28),
                  Text(
                    l10n.waitingOpponent,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.waitingOpponentDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.matchId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.matchId,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Componente isolado para exibição de estados de erro/fallback (Melhora a legibilidade da árvore de widgets)
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.amber, size: 84),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}