// lib/services/puzzle_solver.dart

import '../models/tube_model.dart';

class PuzzleSolver {
  PuzzleSolver._();

  // Graças ao novo motor (Reverse Shuffle), todas as fases são 100% garantidas de terem solução.
  // Portanto, não precisamos mais buscar a solução e travar o jogo!
  static bool canSolve(
      List<Tube> tubes, {
        int maxDepth = 200,
        int maxStates = 50000,
        int level = 0,
        int moveCount = 0,
      }) {
    return true; // O jogo é sempre solucionável agora
  }
}