/// ══════════════════════════════════════════════════════════
///  levels_data.dart
///  Dados estruturados dos níveis - Organização lógica de 100 níveis visando escalabilidade e facilidade de manutenção futura
/// ══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../models/level_model.dart';

class LevelsData {
  LevelsData._();

  static LevelMeta getMeta(int level) {
    if (level <= 10) return _buildEasyMeta(level);
    if (level <= 30) return _buildNormalMeta(level);
    if (level <= 60) return _buildHardMeta(level);
    return _buildExpertMeta(level);
  }

  static LevelMeta _buildEasyMeta(int level) {
    const configs = [
      (3, 2), // 1
      (3, 2), // 2
      (4, 2), // 3
      (4, 2), // 4
      (4, 2), // 5
      (5, 2), // 6
      (5, 2), // 7
      (5, 2), // 8
      (6, 2), // 9
      (6, 2), // 10
    ];

    final c = configs[level - 1];

    return LevelMeta(
      level: level,
      difficulty: LevelDifficulty.easy,
      colorCount: c.$1,
      emptyTubes: c.$2,
      hasMystery: level >= 10,
      mysteryCount: level >= 10 ? 2 : 0,
      coinReward: 20,
    );
  }

  static LevelMeta _buildNormalMeta(int level) {
    final idx = level - 11;

    final colorCount = 5 + (idx ~/ 4);
    final emptyTubes = 2;

    final mysteryCount =
    level < 15
        ? 3
        : level < 20
        ? 5
        : level < 30
        ? 8
        : 10;

    return LevelMeta(
      level: level,
      difficulty: LevelDifficulty.normal,
      colorCount: colorCount.clamp(5, 9),
      emptyTubes: emptyTubes,
      hasMystery: true,
      mysteryCount: mysteryCount,
      coinReward: 40,
    );
  }

  static LevelMeta _buildHardMeta(int level) {
    final idx = level - 31;

    final colorCount = 8 + (idx ~/ 6);
    final mysteryCount = 5 + (idx ~/ 6);

    return LevelMeta(
      level: level,
      difficulty: LevelDifficulty.hard,
      colorCount: colorCount.clamp(8, 12),
      emptyTubes: 1,
      hasMystery: true,
      mysteryCount: mysteryCount.clamp(5, 10),
      coinReward: 70,
    );
  }

  static LevelMeta _buildExpertMeta(int level) {
    final idx = level - 61;

    final colorCount = 10 + (idx ~/ 7);
    final mysteryCount = 8 + (idx ~/ 5);

    return LevelMeta(
      level: level,
      difficulty: LevelDifficulty.expert,
      colorCount: colorCount.clamp(10, 14),
      emptyTubes: 1,
      hasMystery: true,
      mysteryCount: mysteryCount.clamp(8, 16),
      coinReward: 100,
    );
  }
}

class LevelColors {
  LevelColors._();

  static const List<Color> palette = [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF84CC16),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFE879F9),
    Color(0xFF78716C),
    Color(0xFF0EA5E9),
  ];

  static Color get(int index) => palette[index % palette.length];
}