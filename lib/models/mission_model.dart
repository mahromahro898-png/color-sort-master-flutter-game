/// ══════════════════════════════════════════════════════════
///  mission_model.dart
///  Modelo de Missões Diárias (Daily Missions) - Estrutura de dados para o sistema de retenção e engajamento diário
/// ══════════════════════════════════════════════════════════

enum MissionType {
  completeLevels,
  useHints,
  watchAds,
  completeMysteryLevel,
  earnCoins,
  completeLevelsNoPowerup,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final String icon;
  final MissionType type;
  final int target;

  // Recompensas (Rewards)
  final int coinReward;
  final int hintReward;
  final int extraTubeReward;

  // Estado atual da missão (Tracking para atualização reativa da UI)
  final int progress;
  final bool isCompleted;
  final bool rewardClaimed;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.target,
    this.coinReward = 0,
    this.hintReward = 0,
    this.extraTubeReward = 0,
    this.progress = 0,
    this.isCompleted = false,
    this.rewardClaimed = false,
  });

  double get progressRatio => (progress / target).clamp(0.0, 1.0);
  bool get canClaim => isCompleted && !rewardClaimed;

  Mission copyWith({
    int? progress,
    bool? isCompleted,
    bool? rewardClaimed,
  }) {
    return Mission(
      id: id,
      title: title,
      description: description,
      icon: icon,
      type: type,
      target: target,
      coinReward: coinReward,
      hintReward: hintReward,
      extraTubeReward: extraTubeReward,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'isCompleted': isCompleted,
    'rewardClaimed': rewardClaimed,
  };

  String get rewardText {
    final parts = <String>[];
    if (coinReward > 0)      parts.add('🪙 $coinReward');
    if (hintReward > 0)      parts.add('💡 $hintReward Hint');
    if (extraTubeReward > 0) parts.add('🧪 $extraTubeReward Tube');
    return parts.join(' + ');
  }
}

// ── Daily missions pool (Repositório de missões geradas dinamicamente) ──────────────────────────────────────
class MissionsPool {
  MissionsPool._();

  static const List<Mission> pool = [
    Mission(
      id: 'complete_3',
      title: 'Level Up',
      description: 'Complete 3 levels',
      icon: '🎮',
      type: MissionType.completeLevels,
      target: 3,
      coinReward: 80,
    ),
    Mission(
      id: 'complete_5',
      title: 'On a Roll',
      description: 'Complete 5 levels',
      icon: '🔥',
      type: MissionType.completeLevels,
      target: 5,
      coinReward: 150,
    ),
    Mission(
      id: 'use_hint',
      title: 'Need a Tip?',
      description: 'Use 1 hint',
      icon: '💡',
      type: MissionType.useHints,
      target: 1,
      coinReward: 40,
    ),
    Mission(
      id: 'watch_ad',
      title: 'Ad Watcher',
      description: 'Watch 1 rewarded ad',
      icon: '📺',
      type: MissionType.watchAds,
      target: 1,
      coinReward: 60,
    ),
    Mission(
      id: 'mystery_1',
      title: 'Into the Unknown',
      description: 'Complete 1 mystery level',
      icon: '🔮',
      type: MissionType.completeMysteryLevel,
      target: 1,
      coinReward: 200,
      hintReward: 1,
    ),
    Mission(
      id: 'earn_100',
      title: 'Coin Collector',
      description: 'Earn 100 coins',
      icon: '🪙',
      type: MissionType.earnCoins,
      target: 100,
      coinReward: 50,
    ),
    Mission(
      id: 'no_powerup_2',
      title: 'Pure Skill',
      description: 'Complete 2 levels without any powerup',
      icon: '🧠',
      type: MissionType.completeLevelsNoPowerup,
      target: 2,
      coinReward: 120,
      hintReward: 1,
    ),
  ];
}