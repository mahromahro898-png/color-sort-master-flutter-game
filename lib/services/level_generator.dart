import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/level_model.dart';
import '../models/tube_model.dart';

class LevelGenerator {
  Future<LevelState> generateLevelByNumber(int levelNumber) async {
    try {
      String jsonString = await rootBundle.loadString('assets/levels/level_$levelNumber.json');
      Map<String, dynamic> data = jsonDecode(jsonString);

      // Lê a capacidade do tubo dedicada a cada nível (por exemplo, em níveis avançados passa a ser 5 ou 6)
      int capacity = data['capacity'] ?? 4;
      List<dynamic> tubesData = data['tubes'];

      List<Tube> tubes = [];

      for (var tubeArray in tubesData) {
        List<dynamic> blocksData = tubeArray;
        List<Block> blocks = [];

        for (var b in blocksData) {
          Block newBlock = Block(colorId: b['c'] as int);

          // Ativa o modo mistério se estiver presente no arquivo
          if (b['m'] == true) {
            newBlock.isMystery = true;
          }
          blocks.add(newBlock);
        }

        tubes.add(Tube(
          capacity: capacity,
          blocks: blocks,
        ));
      }

      LevelState generatedLevel = LevelState(tubes: tubes);
      generatedLevel.difficultyScore = 100;
      return generatedLevel;

    } catch (e) {
      print("Erro de emergência - Nível $levelNumber não encontrado: $e");
      return LevelState(tubes: []);
    }
  }
}