// lib/screens/level_select_screen.dart

import 'package:flutter/material.dart';
import '../services/save_service.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  // Escalonamento de conteúdo (Scalability): Limite de fases expandido para 1000 visando maximizar a retenção (LTV) do usuário a longo prazo
  static const int totalLevels = 1000;

  int unlockedLevel = 1;
  Map<int, int> levelStars = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLevels();
  }

  Future<void> loadLevels() async {
    final saved = await SaveService.loadLevel();
    final starsMap = <int, int>{};

    for (int i = 1; i <= totalLevels; i++) {
      starsMap[i] = await SaveService.loadLevelStars(i);
    }

    if (!mounted) return;

    setState(() {
      unlockedLevel = saved;
      levelStars = starsMap;
      isLoading = false;
    });
  }

  void openLevel(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(startLevel: level),
      ),
    ).then((_) => loadLevels());
  }

  bool isMysteryLevel(int level) {
    return level >= 15 && level % 5 == 0;
  }

  // Balanceamento de dificuldade (Difficulty Curve): Distribuição coesa das nomenclaturas ao longo dos 1000 níveis para manter o engajamento contínuo
  String difficultyText(int level) {
    if (level <= 50) return 'Easy';
    if (level <= 100) return 'Normal';
    if (level <= 400) return 'Hard';
    if (level <= 800) return 'Expert';
    return 'Master';
  }

  // Feedback visual (UI/UX): Atualização da paleta de progressão, introduzindo a cor roxa para identificar o "Endgame" (categoria Master > 800)
  Color difficultyColor(int level) {
    if (level <= 50) return const Color(0xFF22C55E);
    if (level <= 100) return const Color(0xFF38BDF8);
    if (level <= 400) return const Color(0xFFF59E0B);
    if (level <= 800) return const Color(0xFFEF4444);
    return const Color(0xFF9333EA);
  }

  Widget starsWidget(int stars, bool isUnlocked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index < stars;
        return Icon(
          Icons.star_rounded,
          size: 14,
          color: !isUnlocked
              ? Colors.white12
              : active
              ? Colors.amber
              : Colors.white24,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101827),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101827),
      appBar: AppBar(
        title: const Text(
          'Select Level',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF162033),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Progress Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlocked Level $unlockedLevel / $totalLevels',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              itemCount: totalLevels,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final level = index + 1;
                final isUnlocked = level <= unlockedLevel;
                final stars = levelStars[level] ?? 0;
                final isCompleted = stars > 0;
                final isMystery = isMysteryLevel(level);
                final diffColor = difficultyColor(level);

                return GestureDetector(
                  onTap: isUnlocked ? () => openLevel(level) : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isUnlocked ? 1 : 0.55,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E293B),
                            isMystery
                                ? const Color(0xFF3B0764)
                                : const Color(0xFF0F172A),
                          ],
                        )
                            : null,
                        color: isUnlocked ? null : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !isUnlocked
                              ? Colors.white24
                              : isCompleted
                              ? Colors.amber
                              : isMystery
                              ? const Color(0xFFA855F7)
                              : const Color(0xFF60A5FA),
                          width: 2,
                        ),
                        boxShadow: isUnlocked
                            ? [
                          BoxShadow(
                            color: (isMystery
                                ? const Color(0xFFA855F7)
                                : const Color(0xFF60A5FA))
                                .withOpacity(0.18),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Icon(
                              isUnlocked
                                  ? isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.play_circle_fill_rounded
                                  : Icons.lock_rounded,
                              size: 18,
                              color: isUnlocked
                                  ? isCompleted
                                  ? Colors.amber
                                  : Colors.white70
                                  : Colors.white30,
                            ),
                          ),
                          if (isMystery)
                            Positioned(
                              top: 7,
                              left: 7,
                              child: Container(
                                width: 23,
                                height: 23,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF581C87),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFA855F7),
                                  ),
                                ),
                                child: const Text(
                                  '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$level',
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? Colors.white
                                        : Colors.white30,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: diffColor.withOpacity(
                                      isUnlocked ? 0.2 : 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isMystery ? 'Mystery' : difficultyText(level),
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? diffColor
                                          : Colors.white30,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                starsWidget(stars, isUnlocked),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}