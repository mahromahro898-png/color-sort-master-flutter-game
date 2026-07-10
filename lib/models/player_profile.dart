/// ══════════════════════════════════════════════════════════
///  player_profile.dart
///  Perfil completo do jogador - Gerenciamento de estado global e persistência de dados do usuário
/// ══════════════════════════════════════════════════════════
import '../data/game_config.dart';

class PlayerProfile {
  final int coins;
  final int hearts;
  final DateTime? nextHeartTime; // Timestamp para o próximo coração (Sistema de regeneração de energia)
  final int currentLevel;
  final int highestUnlockedLevel;
  final int hintsCount;
  final int undosCount;
  final int extraTubesCount;
  final bool adsRemoved;
  final int totalLevelsCompleted;
  final int totalCoinsEarned;

  const PlayerProfile({
    this.hearts = GameConfig.maxHearts,
    this.coins = GameConfig.starterCoins,          // Inicializado a partir das configurações globais (GameConfig) para consistência no balanceamento
    this.hintsCount = GameConfig.starterHints,
    this.undosCount = GameConfig.starterUndos,
    this.extraTubesCount = GameConfig.starterExtraTubes,
    this.currentLevel = 1,
    this.highestUnlockedLevel = 1,
    this.totalLevelsCompleted = 0,
    this.totalCoinsEarned = 0,
    this.nextHeartTime,
    this.adsRemoved = false,
  });

  bool get hasHearts => hearts > 0;
  bool get heartsAreFull => hearts >= GameConfig.maxHearts;

  PlayerProfile copyWith({
    int? coins,
    int? hearts,
    DateTime? nextHeartTime,
    bool clearNextHeartTime = false,
    int? currentLevel,
    int? highestUnlockedLevel,
    int? hintsCount,
    int? undosCount,
    int? extraTubesCount,
    bool? adsRemoved,
    int? totalLevelsCompleted,
    int? totalCoinsEarned,
  }) {
    return PlayerProfile(
      coins: coins ?? this.coins,
      hearts: hearts ?? this.hearts,
      nextHeartTime: clearNextHeartTime
          ? null
          : (nextHeartTime ?? this.nextHeartTime),
      currentLevel: currentLevel ?? this.currentLevel,
      highestUnlockedLevel:
      highestUnlockedLevel ?? this.highestUnlockedLevel,
      hintsCount: hintsCount ?? this.hintsCount,
      undosCount: undosCount ?? this.undosCount,
      extraTubesCount: extraTubesCount ?? this.extraTubesCount,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      totalLevelsCompleted:
      totalLevelsCompleted ?? this.totalLevelsCompleted,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'hearts': hearts,
    'nextHeartTime': nextHeartTime?.millisecondsSinceEpoch,
    'currentLevel': currentLevel,
    'highestUnlockedLevel': highestUnlockedLevel,
    'hintsCount': hintsCount,
    'undosCount': undosCount,
    'extraTubesCount': extraTubesCount,
    'adsRemoved': adsRemoved,
    'totalLevelsCompleted': totalLevelsCompleted,
    'totalCoinsEarned': totalCoinsEarned,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final nextHeartMs = json['nextHeartTime'];
    return PlayerProfile(
      // Fallback seguro: garante a inicialização com valores padrão (GameConfig) em caso de dados legados ausentes
      coins: json['coins'] as int? ?? GameConfig.starterCoins,
      hearts: json['hearts'] as int? ?? GameConfig.maxHearts,
      nextHeartTime: nextHeartMs != null
          ? DateTime.fromMillisecondsSinceEpoch(nextHeartMs as int)
          : null,
      currentLevel: json['currentLevel'] as int? ?? 1,
      highestUnlockedLevel: json['highestUnlockedLevel'] as int? ?? 1,
      hintsCount: json['hintsCount'] as int? ?? GameConfig.starterHints,
      undosCount: json['undosCount'] as int? ?? GameConfig.starterUndos,
      extraTubesCount: json['extraTubesCount'] as int? ?? GameConfig.starterExtraTubes,
      adsRemoved: json['adsRemoved'] as bool? ?? false,
      totalLevelsCompleted: json['totalLevelsCompleted'] as int? ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
    );
  }
}