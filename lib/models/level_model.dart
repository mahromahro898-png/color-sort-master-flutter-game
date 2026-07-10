// lib/models/level_model.dart

import 'tube_model.dart';

// ─── 1. Base Legada (Mantida para garantir a integridade dos serviços de monetização e achievements) ───
enum LevelDifficulty { easy, normal, hard, expert }

class LevelMeta {
  final int level;
  final LevelDifficulty difficulty;
  final int colorCount;
  final int emptyTubes;
  final bool hasMystery;
  final int mysteryCount;
  final int coinReward;

  LevelMeta({
    required this.level,
    required this.difficulty,
    required this.colorCount,
    required this.emptyTubes,
    required this.hasMystery,
    required this.mysteryCount,
    required this.coinReward,
  });

  // Propriedades auxiliares implementadas para garantir a compatibilidade estrita e o funcionamento 100% do módulo de Achievements
  bool get isHard => difficulty == LevelDifficulty.hard;
  bool get isExpert => difficulty == LevelDifficulty.expert;
}

// ─── 2. Nova Arquitetura (Núcleo do Gerador Procedural de Níveis / Level Generator) ───
class LevelState {
  final List<Tube> tubes;
  int difficultyScore;

  LevelState({
    required this.tubes,
    this.difficultyScore = 0,
  });

  bool get isSolved {
    for (var tube in tubes) {
      if (tube.isEmpty) continue;

      if (!tube.isFull) return false;

      int firstColor = tube.blocks.first.colorId;
      if (tube.blocks.any((block) => block.colorId != firstColor)) {
        return false;
      }
    }
    return true;
  }

  LevelState clone() {
    return LevelState(
      tubes: tubes.map((t) => t.clone()).toList(),
      difficultyScore: difficultyScore,
    );
  }
}