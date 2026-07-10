/// ══════════════════════════════════════════════════════════
///  game_engine.dart
///  Motor do Jogo (Game Engine) - Core logic, resolução de movimentos e detecção de estado de vitória/Dead End
/// ══════════════════════════════════════════════════════════
import '../models/level_model.dart';
import '../models/tube_model.dart';

class GameEngine {
  late LevelState currentLevel;
  int moves = 0;

  /// Inicializa o motor com um estado de nível (LevelState) para processamento
  void loadLevel(LevelState level) {
    currentLevel = level;
    moves = 0;
  }

  /// Tenta processar um movimento entre dois tubos.
  /// Retorna 'true' se o movimento for legal e processado, 'false' caso contrário.
  bool moveBlock(int sourceIndex, int destIndex) {
    if (sourceIndex == destIndex) return false;

    Tube sourceTube = currentLevel.tubes[sourceIndex];
    Tube destTube = currentLevel.tubes[destIndex];

    if (sourceTube.isEmpty || destTube.isFull) return false;

    Block blockToMove = sourceTube.topBlock!;

    // Validação da regra de negócio (Regras de empilhamento do jogo)
    bool isValidMove = false;
    if (destTube.isEmpty) {
      isValidMove = true;
    } else {
      Block destTop = destTube.topBlock!;
      // Bloqueio de movimentação sobre itens Mystery e validação de consistência de cores
      if (!destTop.isMystery && destTop.colorId == blockToMove.colorId) {
        isValidMove = true;
      }
    }

    if (isValidMove) {
      // Execução atômica da transação de dados entre tubos
      destTube.blocks.add(sourceTube.blocks.removeLast());
      moves++;

      // Mecânica de revelação: Desbloqueia bloco Mystery quando o bloco sobrejacente é removido
      if (sourceTube.isNotEmpty && sourceTube.topBlock!.isMystery) {
        sourceTube.topBlock!.isMystery = false;
      }

      return true;
    }

    return false;
  }

  /// Getter que avalia se a condição de vitória foi atingida (Game State Observer)
  bool get isGameWon => currentLevel.isSolved;

  /// Detecção de estado de Dead End (Heurística de busca de movimentos disponíveis)
  /// Verifica se existe pelo menos um movimento legal possível para evitar travamento do usuário
  bool hasAvailableMoves() {
    for (int i = 0; i < currentLevel.tubes.length; i++) {
      for (int j = 0; j < currentLevel.tubes.length; j++) {
        if (i == j) continue;

        Tube source = currentLevel.tubes[i];
        Tube dest = currentLevel.tubes[j];

        if (source.isEmpty || dest.isFull) continue;

        if (dest.isEmpty) return true; // Movimento legal para tubo vazio

        // Verifica compatibilidade de cor para fusão de blocos
        if (!dest.topBlock!.isMystery && dest.topBlock!.colorId == source.topBlock!.colorId) {
          return true; // Movimento legal de fusão
        }
      }
    }
    return false; // Nenhum movimento legal encontrado: Dead End detectado
  }
}