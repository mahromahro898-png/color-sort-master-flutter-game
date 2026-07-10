enum LevelStatus { locked, unlocked, completed }

class LevelProgress {
  final int level;
  final LevelStatus status;
  final int stars;
  final int bestMoves;

  LevelProgress({
    required this.level,
    required this.status,
    this.stars = 0,
    this.bestMoves = 0,
  });

  // Getter auxiliar para checagem rápida do estado (facilita a leitura e manutenção do código)
  bool get isLocked => status == LevelStatus.locked;

  // Padrão copyWith para garantir a imutabilidade: permite atualizar propriedades específicas mantendo o estado intacto
  LevelProgress copyWith({
    int? level,
    LevelStatus? status,
    int? stars,
    int? bestMoves,
  }) {
    return LevelProgress(
      level: level ?? this.level,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      bestMoves: bestMoves ?? this.bestMoves,
    );
  }

  // Factory fromJson com tratamento seguro (fallback) para dados legados: garante a retrocompatibilidade com saves antigos que não possuíam 'stars'
  factory LevelProgress.fromJson(Map<String, dynamic> json) {
    return LevelProgress(
      level: json['level'] as int,
      status: LevelStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => LevelStatus.locked,
      ),
      stars: json['stars'] as int? ?? 0,
      bestMoves: json['bestMoves'] as int? ?? 0,
    );
  }

  // Serialização (toJson) otimizada para persistência segura no armazenamento local
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'status': status.toString().split('.').last,
      'stars': stars,
      'bestMoves': bestMoves,
    };
  }
}