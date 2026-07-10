/// ══════════════════════════════════════════════════════════
///  game_config.dart
///  Configurações centrais do jogo - Centralização de variáveis mágicas para facilitar a manutenção e balanceamento futuro
/// ══════════════════════════════════════════════════════════

class GameConfig {
  GameConfig._();

  // ── Hearts ─────────────────────────────────────────────
  static const int maxHearts = 5;
  static const int heartRegenMinutes = 30; // Ajustado para 30 minutos (regen) visando balanceamento. Alterar aqui caso necessário no futuro.
  static const int heartRegenSeconds = heartRegenMinutes * 60;

  // ── Coin Rewards ───────────────────────────────────────
  static const int coinsEasyWin    = 20;
  static const int coinsNormalWin  = 60; // Recompensa ajustada para 60 para alinhar com o escopo atual. Ponto de controle para economia do jogo.
  static const int coinsHardWin    = 70;
  static const int coinsMysteryWin = 100;
  static const int coinsAdReward   = 200;

  // ── Coin Costs ─────────────────────────────────────────
  static const int costHint           = 100;
  static const int costUndo           = 50;
  static const int costExtraTube      = 200;
  static const int costContinueLevel  = 150;
  static const int costRefillOneHeart = 100;
  static const int costRefillAllHearts = 400;

  // ── Daily Rewards ──────────────────────────────────────
  static const List<DailyReward> dailyRewards = [
    DailyReward(day: 1, coins: 50,  hints: 0, extraTubes: 0),
    DailyReward(day: 2, coins: 100, hints: 0, extraTubes: 0),
    DailyReward(day: 3, coins: 150, hints: 0, extraTubes: 0),
    DailyReward(day: 4, coins: 250, hints: 0, extraTubes: 0),
    DailyReward(day: 5, coins: 0,   hints: 1, extraTubes: 0),
    DailyReward(day: 6, coins: 0,   hints: 0, extraTubes: 1),
    DailyReward(day: 7, coins: 500, hints: 0, extraTubes: 0),
  ];

  // ── Ads ────────────────────────────────────────────────
  static const int levelsBeforeInterstitial = 3;

  // ── Level Difficulty Ranges ────────────────────────────
  static const int easyMaxLevel    = 10;
  static const int normalMaxLevel  = 30;
  static const int hardMaxLevel    = 60;
  static const int mysteryMinLevel = 20; // Ponto de partida para os níveis Mystery. Escalonamento de dificuldade definido a partir daqui.

  // ── Starter Pack ──────────────────────────────────────
  // Valores do Starter Pack ajustados para melhorar a experiência inicial (onboarding) do usuário. Facilita o tuning futuro da economia inicial.
  static const int starterCoins     = 200;
  static const int starterHints     = 1;
  static const int starterUndos     = 1;
  static const int starterExtraTubes = 1;
}

// ── Daily Reward Model (utilizado nas configurações) ────────────────
class DailyReward {
  final int day;
  final int coins;
  final int hints;
  final int extraTubes;

  const DailyReward({
    required this.day,
    required this.coins,
    required this.hints,
    required this.extraTubes,
  });

  String get description {
    final parts = <String>[];
    if (coins > 0)      parts.add('🪙 $coins Coins');
    if (hints > 0)      parts.add('💡 $hints Hint${hints > 1 ? "s" : ""}');
    if (extraTubes > 0) parts.add('🧪 $extraTubes Extra Tube${extraTubes > 1 ? "s" : ""}');
    return parts.join(' + ');
  }
}