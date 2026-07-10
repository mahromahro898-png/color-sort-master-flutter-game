/// ══════════════════════════════════════════════════════════
///  achievement_model.dart
///  Modelo de Conquistas (Achievements) - Estruturação de dados para gamificação e integração com Google Play Games
/// ══════════════════════════════════════════════════════════

enum AchievementType {
  levelsCompleted,
  coinsEarned,
  hintsUsed,
  mysteryLevelsCompleted,
  hardLevelNoHint,
  perfectSolves, // 3 stars
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final int target;     // Meta a ser alcançada (ex: 10 níveis concluídos)
  final int coinReward;
  final String? googlePlayId; // TODO: Google Play Games

  // Estado atual do jogador (Tracking de progressão)
  final int progress;
  final bool isUnlocked;
  final bool rewardClaimed;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.target,
    required this.coinReward,
    this.googlePlayId,
    this.progress = 0,
    this.isUnlocked = false,
    this.rewardClaimed = false,
  });

  bool get isCompleted => progress >= target;
  double get progressRatio => (progress / target).clamp(0.0, 1.0);

  Achievement copyWith({
    int? progress,
    bool? isUnlocked,
    bool? rewardClaimed,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      type: type,
      target: target,
      coinReward: coinReward,
      googlePlayId: googlePlayId,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'isUnlocked': isUnlocked,
    'rewardClaimed': rewardClaimed,
  };
}

// ── Static list of all achievements (Lista base para inicialização e controle) ─────────────────────────
class AchievementsData {
  AchievementsData._();

  static const List<Achievement> all = [
    Achievement(
      id: 'levels_10',
      title: 'Getting Started',
      description: 'Complete 10 levels',
      icon: '🎯',
      type: AchievementType.levelsCompleted,
      target: 10,
      coinReward: 100,
      googlePlayId: 'achievement_getting_started',
    ),
    Achievement(
      id: 'levels_50',
      title: 'Halfway There',
      description: 'Complete 50 levels',
      icon: '⭐',
      type: AchievementType.levelsCompleted,
      target: 50,
      coinReward: 300,
      googlePlayId: 'achievement_halfway_there',
    ),
    Achievement(
      id: 'levels_100',
      title: 'Color Master',
      description: 'Complete 100 levels',
      icon: '👑',
      type: AchievementType.levelsCompleted,
      target: 100,
      coinReward: 700,
      googlePlayId: 'achievement_color_master',
    ),
    Achievement(
      id: 'coins_5000',
      title: 'Rich Player',
      description: 'Earn 5000 coins total',
      icon: '💰',
      type: AchievementType.coinsEarned,
      target: 5000,
      coinReward: 200,
    ),
    Achievement(
      id: 'hints_10',
      title: 'Hint Lover',
      description: 'Use 10 hints',
      icon: '💡',
      type: AchievementType.hintsUsed,
      target: 10,
      coinReward: 150,
    ),
    Achievement(
      id: 'mystery_5',
      title: 'Mystery Solver',
      description: 'Complete 5 mystery levels',
      icon: '🔮',
      type: AchievementType.mysteryLevelsCompleted,
      target: 5,
      coinReward: 400,
      googlePlayId: 'achievement_mystery_solver',
    ),
    Achievement(
      id: 'hard_no_hint',
      title: 'Pure Genius',
      description: 'Complete a hard level without using hints',
      icon: '🧠',
      type: AchievementType.hardLevelNoHint,
      target: 1,
      coinReward: 250,
      googlePlayId: 'achievement_pure_genius',
    ),
    Achievement(
      id: 'perfect_20',
      title: 'Perfectionist',
      description: 'Get 3 stars on 20 levels',
      icon: '✨',
      type: AchievementType.perfectSolves,
      target: 20,
      coinReward: 500,
    ),
  ];
}