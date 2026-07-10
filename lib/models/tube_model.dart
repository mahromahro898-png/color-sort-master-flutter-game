// lib/models/tube_model.dart

/// Representa um bloco de cor individual dentro do tubo (Entidade base para a lógica de empilhamento)
class Block {
  final int colorId;
  bool isMystery;

  Block({
    required this.colorId,
    this.isMystery = false,
  });

  Block clone() {
    return Block(
      colorId: colorId,
      isMystery: isMystery,
    );
  }
}

/// Estrutura de dados do Tubo (Container) - Gerencia a capacidade e atua como uma Pilha (Stack) para os blocos
class Tube {
  final int capacity;
  final List<Block> blocks;

  Tube({
    required this.capacity,
    List<Block>? blocks,
  }) : blocks = blocks ?? [];

  bool get isFull => blocks.length >= capacity;
  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;
  Block? get topBlock => isEmpty ? null : blocks.last;

  Tube clone() {
    return Tube(
      capacity: capacity,
      blocks: blocks.map((b) => b.clone()).toList(),
    );
  }
}