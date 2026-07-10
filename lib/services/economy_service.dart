/// ══════════════════════════════════════════════════════════
///  economy_service.dart
///  Serviço de Economia (In-Game Economy) - Gerenciamento centralizado de transações de moedas (Soft Currency) e consumo de itens (Boosters)
/// ══════════════════════════════════════════════════════════

import '../data/game_config.dart';
import '../models/player_profile.dart';
import '../models/level_model.dart';
import 'save_service.dart';

class EconomyService {
  EconomyService._();

  // ── Gestão de Moedas (Hard/Soft Currency Influx) ───────────────────────────────────────────────

  /// Credita moedas ao perfil do jogador e registra no histórico de ganhos totais (LTV Analysis)
  static Future<PlayerProfile> addCoins(
      PlayerProfile profile,
      int amount,
      ) async {
    final updated = profile.copyWith(
      coins: profile.coins + amount,
      totalCoinsEarned: profile.totalCoinsEarned + amount,
    );
    await SaveService.saveProfile(updated);
    return updated;
  }

  /// Processa a dedução de saldo com verificação prévia de fundos (Pre-condition guard)
  static Future<PlayerProfile?> spendCoins(
      PlayerProfile profile,
      int amount,
      ) async {
    if (profile.coins < amount) return null; // Validação de saldo insuficiente
    final updated = profile.copyWith(coins: profile.coins - amount);
    await SaveService.saveProfile(updated);
    return updated;
  }

  // ── Recompensas de Vitória (Escalonamento de Premiação) ────────────────────────────────────

  /// Resolve o valor da recompensa baseado na dificuldade do nível (Game Balance/Tuning)
  static int winReward(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.easy:   return GameConfig.coinsEasyWin;
      case LevelDifficulty.normal: return GameConfig.coinsNormalWin;
      case LevelDifficulty.hard:   return GameConfig.coinsHardWin;
      case LevelDifficulty.expert: return GameConfig.coinsMysteryWin;
    }
  }

  // ── Boosters (Gestão de Inventário e conversão de moeda) ───────────────────────────────────────────────

  /// Consome uma dica (Hint) ou realiza a compra via conversão de moeda caso o estoque seja zero
  static Future<PlayerProfile?> useHint(PlayerProfile profile) async {
    if (profile.hintsCount > 0) {
      final updated = profile.copyWith(hintsCount: profile.hintsCount - 1);
      await SaveService.saveProfile(updated);
      return updated;
    }
    // Conversão de moeda (Monetization Loop)
    return spendCoins(profile, GameConfig.costHint);
  }

  static Future<PlayerProfile> addHints(
      PlayerProfile profile, int count) async {
    final updated =
    profile.copyWith(hintsCount: profile.hintsCount + count);
    await SaveService.saveProfile(updated);
    return updated;
  }

  // ── Undos ───────────────────────────────────────────────

  /// Gerenciamento de Undo com fallback para compra via moedas (Economy Sink)
  static Future<PlayerProfile?> useUndo(PlayerProfile profile) async {
    if (profile.undosCount > 0) {
      final updated =
      profile.copyWith(undosCount: profile.undosCount - 1);
      await SaveService.saveProfile(updated);
      return updated;
    }
    return spendCoins(profile, GameConfig.costUndo);
  }

  static Future<PlayerProfile> addUndos(
      PlayerProfile profile, int count) async {
    final updated =
    profile.copyWith(undosCount: profile.undosCount + count);
    await SaveService.saveProfile(updated);
    return updated;
  }

  // ── Extra Tubes (Escalonamento de Dificuldade/UX) ─────────────────────────────────────────

  static Future<PlayerProfile?> useExtraTube(PlayerProfile profile) async {
    if (profile.extraTubesCount > 0) {
      final updated = profile.copyWith(
          extraTubesCount: profile.extraTubesCount - 1);
      await SaveService.saveProfile(updated);
      return updated;
    }
    return spendCoins(profile, GameConfig.costExtraTube);
  }

  static Future<PlayerProfile> addExtraTubes(
      PlayerProfile profile, int count) async {
    final updated = profile.copyWith(
        extraTubesCount: profile.extraTubesCount + count);
    await SaveService.saveProfile(updated);
    return updated;
  }

  // ── Continue After Fail (Resgate de partida / Monetization Bridge) ─────────────────────────────────

  static Future<PlayerProfile?> continueWithCoins(
      PlayerProfile profile) async {
    return spendCoins(profile, GameConfig.costContinueLevel);
  }

  // ── Refill Hearts (Regeneração de energia / Monetization Sink) ───────────────────────────────────────

  static Future<PlayerProfile?> refillOneHeartWithCoins(
      PlayerProfile profile) async {
    final result = await spendCoins(profile, GameConfig.costRefillOneHeart);
    if (result == null) return null;
    final updated = result.copyWith(
        hearts: (result.hearts + 1).clamp(0, 5)); // Proteção de bound (Clamp)
    await SaveService.saveProfile(updated);
    return updated;
  }

  static Future<PlayerProfile?> refillAllHeartsWithCoins(
      PlayerProfile profile) async {
    final result =
    await spendCoins(profile, GameConfig.costRefillAllHearts);
    if (result == null) return null;
    final updated = result.copyWith(hearts: 5, clearNextHeartTime: true);
    await SaveService.saveProfile(updated);
    return updated;
  }
}