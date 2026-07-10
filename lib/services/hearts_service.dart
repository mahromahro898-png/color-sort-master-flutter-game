/// ══════════════════════════════════════════════════════════
///  hearts_service.dart
///  Serviço de Energia (Hearts Regeneration) - Gerenciamento de ciclo de regeneração de recursos, time-gating e sincronização offline
/// ══════════════════════════════════════════════════════════

import '../data/game_config.dart';
import '../models/player_profile.dart';
import 'save_service.dart';

class HeartsService {
  HeartsService._();

  /// Sincroniza o saldo de corações considerando o tempo decorrido offline (Retroactive Regeneration)
  static Future<PlayerProfile> syncHearts(PlayerProfile profile) async {
    // 1. Otimização de estado: Se a energia está completa, removemos qualquer referência de timestamp (Clean state)
    if (profile.hearts >= GameConfig.maxHearts) {
      if (profile.nextHeartTime != null) {
        final updated = profile.copyWith(clearNextHeartTime: true);
        await SaveService.saveProfile(updated);
        return updated;
      }
      return profile;
    }

    final now = DateTime.now();

    // 🚨 2. Fail-safe (Tratamento de estado inconsistente): Se a energia não está cheia mas o timer é nulo, inicializamos o fluxo de regeneração
    if (profile.nextHeartTime == null) {
      final updated = profile.copyWith(
        nextHeartTime: now.add(Duration(seconds: GameConfig.heartRegenSeconds)),
      );
      await SaveService.saveProfile(updated);
      return updated;
    }

    // 3. Cálculo de regeneração baseada no diferencial temporal (Delta Time Logic)
    final nextHeart = profile.nextHeartTime!;
    if (now.isBefore(nextHeart)) return profile; // Ainda aguardando o próximo ciclo de regeneração

    final elapsed = now.difference(nextHeart);
    final regenSeconds = GameConfig.heartRegenSeconds;

    // Cálculo do volume de corações recuperados durante o período offline
    final heartsRegened = 1 + (elapsed.inSeconds ~/ regenSeconds);

    final newHearts = (profile.hearts + heartsRegened).clamp(0, GameConfig.maxHearts);

    // Reajuste do próximo timestamp de regeneração caso o saldo não esteja completo
    DateTime? newNextTime;
    if (newHearts < GameConfig.maxHearts) {
      final remaining = elapsed.inSeconds % regenSeconds;
      newNextTime = now.add(Duration(seconds: regenSeconds - remaining));
    }

    final updated = profile.copyWith(
      hearts: newHearts,
      nextHeartTime: newNextTime,
      clearNextHeartTime: newHearts >= GameConfig.maxHearts,
    );

    await SaveService.saveProfile(updated);
    return updated;
  }

  /// Dedução de recurso (Consumível) com disparo do fluxo de regeneração (Cooldown Start)
  static Future<PlayerProfile> spendHeart(PlayerProfile profile) async {
    if (profile.hearts <= 0) return profile;

    final newHearts = profile.hearts - 1;
    DateTime? nextTime = profile.nextHeartTime;

    // Início do ciclo de Cooldown se o jogador estiver saindo do estado de energia máxima
    if (profile.heartsAreFull && newHearts < GameConfig.maxHearts) {
      nextTime = DateTime.now()
          .add(const Duration(seconds: GameConfig.heartRegenSeconds));
    }

    final updated = profile.copyWith(
      hearts: newHearts,
      nextHeartTime: nextTime,
    );

    await SaveService.saveProfile(updated);
    return updated;
  }

  /// Adição de recursos (Recompensa/Compra) com sanitização de limites (Clamping)
  static Future<PlayerProfile> addHeart(PlayerProfile profile,
      {int count = 1}) async {
    final newHearts =
    (profile.hearts + count).clamp(0, GameConfig.maxHearts);

    final updated = profile.copyWith(
      hearts: newHearts,
      clearNextHeartTime: newHearts >= GameConfig.maxHearts,
    );

    await SaveService.saveProfile(updated);
    return updated;
  }

  /// Restauração completa (Refill - Monetization feature)
  static Future<PlayerProfile> refillAll(PlayerProfile profile) async {
    final updated = profile.copyWith(
      hearts: GameConfig.maxHearts,
      clearNextHeartTime: true,
    );
    await SaveService.saveProfile(updated);
    return updated;
  }

  /// Lógica de formatação de strings para a interface (UI Countdown Display)
  static String nextHeartCountdown(DateTime? nextHeartTime) {
    if (nextHeartTime == null) return '';
    final diff = nextHeartTime.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}