import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/challenge_service.dart';
import 'waiting_challenge_screen.dart';

class ChallengeScreen extends StatefulWidget {
  final int currentLevel;

  const ChallengeScreen({
    super.key,
    required this.currentLevel,
  });

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  bool _isLoading = false;

  int _generateBossChallengeLevel() {
    final random = Random();
    return 80 + random.nextInt(30); // Define o range do Boss (80 a 109) - Geração procedural para escalabilidade e balanceamento do desafio
  }

  Future<void> _createChallenge() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final challengeLevel = _generateBossChallengeLevel();
      final seed = DateTime.now().millisecondsSinceEpoch;

      final matchId = await ChallengeService.createChallenge(
        level: challengeLevel,
        seed: seed,
      );

      final challengeLink =
          'https://color-sort-master-e822e.web.app/?id=$matchId';

      if (!mounted) return;

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingChallengeScreen(
            matchId: matchId,
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      await Share.share(
        l10n.challengeShareMessage(challengeLink),
      );
    } catch (e) {
      debugPrint('CHALLENGE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.challengeCreateError}: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: const Color(0xFF1E1B4B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              l10n.challengeFriendTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.challengeFriendDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC857),
                  foregroundColor: const Color(0xFF1E1B4B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF1E1B4B),
                  ),
                )
                    : Text(
                  l10n.createChallenge,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                l10n.later,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}