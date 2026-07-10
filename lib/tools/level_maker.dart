import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Curva de dificuldade profissional
class LevelDifficultyCurve {
  static const int gameSeedBase = 918273;

  static LevelConfig configFor(int levelNumber) {
    return LevelConfig(
      levelNumber: levelNumber,
      numColors: _numColorsFor(levelNumber),
      numEmptyTubes: _numEmptyTubesFor(levelNumber),
      tubeCapacity: _tubeCapacityFor(levelNumber),
      shuffleSteps: _shuffleStepsFor(levelNumber),
      mysteryPercentage: _mysteryPercentageFor(levelNumber),
      seed: gameSeedBase + levelNumber * 97,
    );
  }

  static int _numColorsFor(int lvl) {
    if (lvl <= 20) return (4 + (lvl / 10)).floor().clamp(4, 14).toInt();
    if (lvl <= 100) return (6 + ((lvl - 20) / 16)).floor().clamp(4, 14).toInt();
    // Aqui definimos o limite máximo em 14 para corresponder às cores reais do seu jogo
    return (11 + ((lvl - 100) / 60)).floor().clamp(4, 14).toInt();
  }

  static int _tubeCapacityFor(int lvl) {
    if (lvl < 150) return 4;
    if (lvl < 500) return 5;
    return 6;
  }

  static int _numEmptyTubesFor(int lvl) {
    if (lvl <= 50) return 3;
    if (lvl <= 100) return 2;
    return (lvl % 15 == 0) ? 2 : 1;
  }

  static int _shuffleStepsFor(int lvl) {
    double base = lvl <= 100 ? 15 + lvl * 0.6 : 75 + 14 * sqrt((lvl - 100).toDouble());
    double waveAmplitude = lvl <= 100 ? 4 : 10 + (lvl / 100);
    double wave = sin(lvl * pi / 5) * waveAmplitude;
    double bossBoost = (lvl % 25 == 0) ? base * 0.25 : 0;
    double restRelief = (lvl % 15 == 0 && lvl > 100) ? base * 0.15 : 0;
    return (base + wave + bossBoost - restRelief).round().clamp(10, 4000).toInt();
  }

  static double _mysteryPercentageFor(int lvl) {
    if (lvl <= 60) return 0.0;
    double pct = ((lvl - 60) / 900).clamp(0.0, 0.35);
    if (lvl % 15 == 0) pct *= 0.3;
    return pct;
  }
}

class LevelConfig {
  final int levelNumber, numColors, numEmptyTubes, tubeCapacity, shuffleSteps, seed;
  final double mysteryPercentage;
  const LevelConfig({required this.levelNumber, required this.numColors, required this.numEmptyTubes, required this.tubeCapacity, required this.shuffleSteps, required this.mysteryPercentage, required this.seed});
}

void main() {
  final directory = Directory('assets/levels');
  if (!directory.existsSync()) directory.createSync(recursive: true);

  print('Iniciando a geração de fases profissionais...');

  for (int levelNum = 1; levelNum <= 1000; levelNum++) {
    final config = LevelDifficultyCurve.configFor(levelNum);
    final random = Random(config.seed);

    List<Map<String, dynamic>> allBlocks = [];
    for (int c = 0; c < config.numColors; c++) {
      for (int b = 0; b < config.tubeCapacity; b++) {
        allBlocks.add({'c': c, 'm': false});
      }
    }

    List<List<Map<String, dynamic>>> tubes = [];
    for (int i = 0; i < config.numColors; i++) {
      tubes.add(allBlocks.sublist(i * config.tubeCapacity, (i + 1) * config.tubeCapacity).toList());
    }
    for (int i = 0; i < config.numEmptyTubes; i++) tubes.add([]);

    int successfulShuffles = 0;
    int maxAttempts = config.shuffleSteps * 10;
    int attempts = 0;
    int? lastSource, lastDest;

    while (successfulShuffles < config.shuffleSteps && attempts < maxAttempts) {
      attempts++;
      int sourceIndex = random.nextInt(tubes.length);
      var sourceTube = tubes[sourceIndex];
      if (sourceTube.isEmpty) continue;

      bool canReverse = sourceTube.length == 1 || (sourceTube.last['c'] == sourceTube[sourceTube.length - 2]['c']);
      if (!canReverse) continue;

      int destIndex = random.nextInt(tubes.length);
      if (destIndex == sourceIndex || (sourceIndex == lastDest && destIndex == lastSource)) continue;

      var destTube = tubes[destIndex];
      if (destTube.length >= config.tubeCapacity) continue;

      destTube.add(sourceTube.removeLast());
      lastSource = sourceIndex; lastDest = destIndex;
      successfulShuffles++;
    }

    if (config.mysteryPercentage > 0) {
      List<Map<String, dynamic>> eligible = [];
      for (var tube in tubes) {
        if (tube.length > 1) {
          for (int i = 0; i < tube.length - 1; i++) eligible.add(tube[i]);
        }
      }
      eligible.shuffle(random);
      int targetCount = (eligible.length * config.mysteryPercentage).round();
      for (int i = 0; i < targetCount && i < eligible.length; i++) eligible[i]['m'] = true;
    }

    Map<String, dynamic> levelData = {
      'level': levelNum,
      'capacity': config.tubeCapacity,
      'tubes': tubes,
    };

    File('${directory.path}/level_$levelNum.json').writeAsStringSync(jsonEncode(levelData));
    if (levelNum % 100 == 0) print('$levelNum fases geradas...');
  }
  print('Concluído com sucesso! Verifique a pasta assets/levels');
}