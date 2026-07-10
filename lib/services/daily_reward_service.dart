/// ══════════════════════════════════════════════════════════
///  daily_reward_service.dart
///  Serviço de Recompensas Diárias (Daily Rewards) - Lógica de retenção de usuários (User Retention/LTV) e aplicação do Princípio de Responsabilidade Única (SRP)
/// ══════════════════════════════════════════════════════════

import '../data/game_config.dart';
import '../models/player_profile.dart';
import 'save_service.dart';
import 'economy_service.dart';

class DailyRewardService {
  DailyRewardService._();

  /// Verifica a elegibilidade para a recompensa diária baseado no ciclo de 24 horas (Time-gating mechanism)
  static Future<bool> isRewardAvailable() async {
    final lastDate = await SaveService.loadLastRewardDate();
    final today = _today();
    return lastDate != today;
  }

  /// Recupera o índice atual da sequência de login (1-7 dias) para progressão da recompensa
  static Future<int> getCurrentDay() async {
    return SaveService.loadRewardDay();
  }

  /// Resolve o objeto de recompensa correspondente ao dia atual, com validação de limites (Clamp) para evitar OutOfBounds
  static DailyReward getReward(int day) {
    final idx = (day - 1).clamp(0, GameConfig.dailyRewards.length - 1);
    return GameConfig.dailyRewards[idx];
  }

  /// Processa o resgate (Claim) da recompensa aplicando o padrão de imutabilidade de estado (State Immutability) e delegando transações ao EconomyService
  static Future<PlayerProfile> claim(PlayerProfile profile) async {
    final day = await getCurrentDay();
    final reward = getReward(day);

    PlayerProfile updated = profile;

    // Injeção de Soft Currency (Moedas)
    if (reward.coins > 0) {
      updated = await EconomyService.addCoins(updated, reward.coins);
    }
    // Injeção de Boosters (Dicas)
    if (reward.hints > 0) {
      updated = await EconomyService.addHints(updated, reward.hints);
    }
    // Injeção de Boosters (Tubos Extras)
    if (reward.extraTubes > 0) {
      updated =
      await EconomyService.addExtraTubes(updated, reward.extraTubes);
    }

    // Persiste o timestamp atual e calcula a progressão do ciclo (Loop de 7 dias)
    await SaveService.saveLastRewardDate(_today());
    final nextDay = day >= 7 ? 1 : day + 1;
    await SaveService.saveRewardDay(nextDay);

    return updated;
  }

  static String _today() =>
      DateTime.now().toString().substring(0, 10);
}