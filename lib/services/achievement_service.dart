/// ══════════════════════════════════════════════════════════
///  achievement_service.dart
///  Serviço de Conquistas (Achievements) - Lógica de negócios centralizada para tracking de progressão, gamificação e integração nativa com Google Play Services
/// ══════════════════════════════════════════════════════════

import '../models/achievement_model.dart';
import '../models/player_profile.dart';
import '../models/level_model.dart';
import 'save_service.dart';
import 'economy_service.dart';
import 'google_play_service.dart';

class AchievementService {
  AchievementService._();

  /// Processa as regras de negócio para atualização e verificação de conquistas após a conclusão de um nível (Integração com o Core Loop)
  static Future<List<Achievement>> onLevelCompleted({
    required PlayerProfile profile,
    required LevelMeta meta,
    required bool usedHint,
    required int stars,
  }) async {
    final achievements = await SaveService.loadAchievements();
    final newlyUnlocked = <Achievement>[];

    void update(String id, int newProgress) {
      if (!achievements.containsKey(id)) return;
      final a = achievements[id]!;
      if (a.isUnlocked) return;

      final updated = a.copyWith(progress: newProgress);
      final justUnlocked = !a.isCompleted && updated.isCompleted;

      achievements[id] = justUnlocked
          ? updated.copyWith(isUnlocked: true)
          : updated;

      if (justUnlocked) {
        newlyUnlocked.add(achievements[id]!);
        if (a.googlePlayId != null) {
          GooglePlayService.unlockAchievement(a.googlePlayId!);
        }
      }
    }

    // levels_completed
    update('levels_10', profile.totalLevelsCompleted + 1);
    update('levels_50', profile.totalLevelsCompleted + 1);
    update('levels_100', profile.totalLevelsCompleted + 1);

    // mystery
    if (meta.hasMystery) {
      final current = achievements['mystery_5']?.progress ?? 0;
      update('mystery_5', current + 1);
    }

    // hard no hint
    if (!usedHint && (meta.isHard || meta.isExpert)) {
      update('hard_no_hint', 1);
    }

    // perfect
    if (stars == 3) {
      final current = achievements['perfect_20']?.progress ?? 0;
      update('perfect_20', current + 1);
    }

    await SaveService.saveAchievements(achievements);
    return newlyUnlocked;
  }

  /// Sincroniza a progressão contínua relacionada ao acúmulo de moedas (Lifetime Economy Tracking)
  static Future<void> onCoinsUpdated(int totalCoins) async {
    final achievements = await SaveService.loadAchievements();
    final a = achievements['coins_5000'];
    if (a != null && !a.isUnlocked) {
      achievements['coins_5000'] =
          a.copyWith(progress: totalCoins.clamp(0, 5000));
      await SaveService.saveAchievements(achievements);
    }
  }

  /// Monitora e registra o consumo de boosters (Dicas/Hints) para a progressão de conquistas baseadas em eventos
  static Future<void> onHintUsed() async {
    final achievements = await SaveService.loadAchievements();
    final a = achievements['hints_10'];
    if (a != null && !a.isUnlocked) {
      final newProgress = (a.progress + 1);
      achievements['hints_10'] = newProgress >= a.target
          ? a.copyWith(progress: newProgress, isUnlocked: true)
          : a.copyWith(progress: newProgress);
      await SaveService.saveAchievements(achievements);
    }
  }

  /// Processa o resgate seguro (Claim) da recompensa da conquista, garantindo consistência transacional no saldo do jogador
  static Future<PlayerProfile> claimReward(
      PlayerProfile profile, String achievementId) async {
    final achievements = await SaveService.loadAchievements();
    final a = achievements[achievementId];
    if (a == null || !a.isUnlocked || a.rewardClaimed) return profile;

    achievements[achievementId] = a.copyWith(rewardClaimed: true);
    await SaveService.saveAchievements(achievements);

    return EconomyService.addCoins(profile, a.coinReward);
  }
}