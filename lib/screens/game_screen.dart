import 'dart:async'; // Necessário para o Timer (Controle de tempo assíncrono)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_generator.dart';
import '../models/level_model.dart';
import '../models/tube_model.dart';
import '../models/player_profile.dart';
import '../services/save_service.dart';
import '../services/hearts_service.dart';
import '../services/challenge_service.dart';
import '../widgets/tube_widget.dart';
import '../widgets/pour_effect_layer.dart';
import 'package:color_sort_master/services/mission_service.dart';
import 'package:color_sort_master/services/ads_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:confetti/confetti.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:color_sort_master/services/sound_service.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;
  final bool isChallengeMode;
  final String? challengeMatchId;

  const GameScreen({
    super.key,
    required this.startLevel,
    this.isChallengeMode = false,
    this.challengeMatchId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class _PendingPour {
  final int fromIndex;
  final int toIndex;
  final int moveCount;
  final Color color;
  final Rect fromRect;
  final Rect toRect;
  const _PendingPour({
    required this.fromIndex,
    required this.toIndex,
    required this.moveCount,
    required this.color,
    required this.fromRect,
    required this.toRect,
  });
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int _challengeFailedTimeMs = 999999999;

  DateTime? _challengeStartTime;
  bool _challengeSubmitted = false;

  bool get isChallengeMode =>
      widget.isChallengeMode && widget.challengeMatchId != null;

  String _formatChallengeTime(AppLocalizations loc, int? ms) {
    if (ms == null) return '--:--';
    if (ms >= _challengeFailedTimeMs) return loc.challengeFailed;

    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int currentLevel = 1;
  int moves = 0;
  int coins = 0;
  int hearts = 5;
  int hintsCount = 0;
  int undosCount = 0;
  int extraTubesCount = 0;
  int winCounter = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  PlayerProfile profile = const PlayerProfile();

  int? selectedTubeIndex;
  int? hintFromIndex;
  int? hintToIndex;

  bool isLoading = true;
  bool dailyRewardShown = false;
  bool isPouring = false;
  bool _winDialogShown = false;
  bool _noMoreMovesDialogShown = false;
  bool _winAdRewardClaimed = false;

  final GlobalKey _boardKey = GlobalKey();
  final Map<int, GlobalKey> _tubeKeys = {};

  _PendingPour? _pendingPour;

  Set<int> completedTubeIndexes = {};
  Set<int> celebratingTubeIndexes = {};

  late LevelState levelState;
  final List<LevelState> history = [];
  final LevelGenerator _generator = LevelGenerator();

  late ConfettiController _confettiController;
  Timer? _heartsTimer;

  final int hintPrice = 150;
  final int undoPrice = 100;
  final int tubePrice = 900;
  final int winRewardCoins = 20;
  final int winAdRewardCoins = 100;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4909113673256853/7361778984',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('فشل تحميل إعلان البانر: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    loadSavedProgress();

    _heartsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && hearts < 5) {
        _syncHeartsSilently();
      }
    });
    _loadBannerAd();
  }

  @override
  void dispose() {
    _heartsTimer?.cancel();
    _confettiController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _syncHeartsSilently() async {
    final syncedProfile = await HeartsService.syncHearts(profile);
    if (syncedProfile.hearts != hearts || syncedProfile.nextHeartTime != profile.nextHeartTime) {
      if (!mounted) return;
      setState(() {
        profile = syncedProfile;
        hearts = syncedProfile.hearts;
      });
    }
  }

  Future<void> loadSavedProgress() async {
    currentLevel = widget.startLevel;

    if (isChallengeMode) {
      moves = 0;
      _challengeStartTime = DateTime.now();
    } else {
      moves = await SaveService.loadMoves();
    }

    final loadedProfile = await SaveService.loadProfile();
    final syncedProfile = await HeartsService.syncHearts(loadedProfile);

    profile = syncedProfile;
    coins = syncedProfile.coins;
    hearts = syncedProfile.hearts;

    if (isChallengeMode) {
      hintsCount = 1;
      undosCount = 1;
      extraTubesCount = 0;
    } else {
      hintsCount = syncedProfile.hintsCount;
      undosCount = syncedProfile.undosCount;
      extraTubesCount = syncedProfile.extraTubesCount;
    }

    // Aguarda o carregamento assíncrono do nível para evitar bloqueio da UI thread
    await _initTubes();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (!isChallengeMode) {
      checkDailyReward();
    }
  }

  Future<void> refreshProfile() async {
    final loadedProfile = await SaveService.loadProfile();
    final syncedProfile = await HeartsService.syncHearts(loadedProfile);

    if (!mounted) return;

    setState(() {
      profile = syncedProfile;
      coins = syncedProfile.coins;
      hearts = syncedProfile.hearts;
      hintsCount = syncedProfile.hintsCount;
      undosCount = syncedProfile.undosCount;
      extraTubesCount = syncedProfile.extraTubesCount;
    });
  }

  // Refatorado para Future: garante a resolução da leitura assíncrona antes de prosseguir
  Future<void> _initTubes() async {
    // Otimização de performance: Algoritmo complexo substituído pelo uso direto de dados pré-computados
    levelState = await _generator.generateLevelByNumber(currentLevel);

    completedTubeIndexes = getCompletedTubeIndexes();
    celebratingTubeIndexes.clear();
    history.clear();

    selectedTubeIndex = null;
    hintFromIndex = null;
    hintToIndex = null;

    isPouring = false;
    _winDialogShown = false;
    _winAdRewardClaimed = false;
    _pendingPour = null;

    _tubeKeys.clear();
    for (int i = 0; i < levelState.tubes.length; i++) {
      _tubeKeys[i] = GlobalKey();
    }
  }

  // Função atualizada para gerenciar estados de loading, melhorando significativamente a UX durante operações assíncronas
  Future<void> loadLevel() async {
    setState(() {
      isLoading = true;
    });

    await _initTubes();
    moves = 0;

    if (isChallengeMode) {
      _challengeStartTime = DateTime.now();
      _challengeSubmitted = false;
    } else {
      SaveService.saveLevel(currentLevel);
      SaveService.saveMoves(moves);
    }

    _noMoreMovesDialogShown = false;

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  int calculateStars() {
    final colorCount = levelState.tubes.where((tube) => tube.isNotEmpty).length;
    if (moves <= colorCount * 3) return 3;
    if (moves <= colorCount * 5) return 2;
    return 1;
  }

  Rect? _getTubeRect(int index) {
    final boardContext = _boardKey.currentContext;
    final tubeContext = _tubeKeys[index]?.currentContext;

    if (boardContext == null || tubeContext == null) return null;

    final boardBox = boardContext.findRenderObject() as RenderBox?;
    final tubeBox = tubeContext.findRenderObject() as RenderBox?;

    if (boardBox == null || tubeBox == null) return null;

    final boardGlobal = boardBox.localToGlobal(Offset.zero);
    final tubeGlobal = tubeBox.localToGlobal(Offset.zero);

    final local = tubeGlobal - boardGlobal;

    return local & tubeBox.size;
  }

  void onTubeTap(int index) async {
    if (isPouring) return;

    if (selectedTubeIndex == null) {
      if (levelState.tubes[index].isEmpty) return;

      setState(() {
        selectedTubeIndex = index;
        hintFromIndex = null;
        hintToIndex = null;
      });
      return;
    }

    final fromIndex = selectedTubeIndex!;
    final toIndex = index;

    if (fromIndex == toIndex) {
      setState(() {
        selectedTubeIndex = null;
        hintFromIndex = null;
        hintToIndex = null;
      });
      return;
    }

    moveColors(fromIndex, toIndex);
  }

  void moveColors(int fromIndex, int toIndex) {
    if (isPouring) return;

    final fromTube = levelState.tubes[fromIndex];
    final toTube = levelState.tubes[toIndex];

    if (fromTube.isEmpty) return;

    final topBlock = fromTube.topBlock!;
    final colorId = topBlock.colorId;

    // --- 1. Validação de Regra de Negócio (Movimento Legal) ---
    bool isValid = false;
    if (toTube.isEmpty) {
      isValid = true;
    } else if (!toTube.topBlock!.isMystery && toTube.topBlock!.colorId == colorId) {
      isValid = true;
    }

    if (!isValid) {
      setState(() {
        selectedTubeIndex = null;
        hintFromIndex = null;
        hintToIndex = null;
      });
      return;
    }

    // --- 2. Cálculo de blocos transferíveis (Lógica de derramamento parcial) ---
    int sameColorCount = 0;
    for (int i = fromTube.blocks.length - 1; i >= 0; i--) {
      // Impede a movimentação se o bloco superior for do tipo "Mystery"
      if (!fromTube.blocks[i].isMystery && fromTube.blocks[i].colorId == colorId) {
        sameColorCount++;
      } else {
        break;
      }
    }

    // Calcula a capacidade disponível no tubo de destino (Alocação de espaço)
    final availableSpace = toTube.capacity - toTube.blocks.length;

    // 💡 UX Fix: Transfere apenas a quantidade máxima permitida pelo destino em vez de invalidar a ação!
    int moveCount = sameColorCount;
    if (moveCount > availableSpace) {
      moveCount = availableSpace;
    }

    // Remove a seleção caso a capacidade do destino seja zero (Fallback de segurança)
    if (moveCount <= 0) {
      setState(() {
        selectedTubeIndex = null;
        hintFromIndex = null;
        hintToIndex = null;
      });
      return;
    }

    // --- 3. Execução de Animações e Atualização de Estado (State Update) ---
    final fromRect = _getTubeRect(fromIndex);
    final toRect = _getTubeRect(toIndex);

    history.add(levelState.clone());

    if (fromRect == null || toRect == null) {
      _finishMove(fromIndex, toIndex, moveCount);
      return;
    }

    setState(() {
      isPouring = true;
      selectedTubeIndex = null;
      hintFromIndex = null;
      hintToIndex = null;

      _pendingPour = _PendingPour(
        fromIndex: fromIndex,
        toIndex: toIndex,
        moveCount: moveCount, // Passagem estrita da quantidade validada para evitar overflow visual
        color: TubeWidget.palette[colorId % TubeWidget.palette.length],
        fromRect: fromRect,
        toRect: toRect,
      );
    });

    SoundService.playPourSound();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final move = _pendingPour;
      if (move == null) return;
      _finishMove(move.fromIndex, move.toIndex, move.moveCount);
    });
  }

  void _finishMove(int fromIndex, int toIndex, int moveCount) {
    setState(() {
      final fromTube = levelState.tubes[fromIndex];
      final toTube = levelState.tubes[toIndex];

      for (int i = 0; i < moveCount; i++) {
        toTube.blocks.add(fromTube.blocks.removeLast());
      }

      if (fromTube.isNotEmpty && fromTube.topBlock!.isMystery) {
        fromTube.topBlock!.isMystery = false;
      }

      moves++;
      isPouring = false;
      _pendingPour = null;
    });

    SoundService.stopPourSound();

    if (!isChallengeMode) {
      SaveService.saveMoves(moves);
    }
    checkTubeCelebration();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      bool isLevelFullySolved = true;
      for (final tube in levelState.tubes) {
        if (tube.isEmpty) continue;
        if (!tube.isFull) {
          isLevelFullySolved = false;
          break;
        }
        final firstColor = tube.blocks.first.colorId;
        final isComplete = tube.blocks.every((b) => b.colorId == firstColor && !b.isMystery);
        if (!isComplete) {
          isLevelFullySolved = false;
          break;
        }
      }

      if (isLevelFullySolved && !_winDialogShown) {
        _winDialogShown = true;
        showWinDialog();
        return;
      }

      checkDeadEnd();
    });
  }

  Set<int> getCompletedTubeIndexes() {
    final completed = <int>{};
    for (int i = 0; i < levelState.tubes.length; i++) {
      final t = levelState.tubes[i];
      if (t.isNotEmpty && t.isFull) {
        int firstColor = t.blocks.first.colorId;
        if (t.blocks.every((b) => b.colorId == firstColor && !b.isMystery)) {
          completed.add(i);
        }
      }
    }
    return completed;
  }

  void checkTubeCelebration() {
    final newCompleted = getCompletedTubeIndexes();
    for (final index in newCompleted) {
      if (!completedTubeIndexes.contains(index)) {
        if (!mounted) return;
        setState(() {
          celebratingTubeIndexes.add(index);
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            celebratingTubeIndexes.remove(index);
          });
        });
      }
    }
    completedTubeIndexes = newCompleted;
  }

  Future<void> checkDeadEnd() async {
    if (isPouring || levelState.isSolved || _winDialogShown || _noMoreMovesDialogShown) return;

    bool hasMoves = false;
    for (int i = 0; i < levelState.tubes.length; i++) {
      Tube source = levelState.tubes[i];
      if (source.isEmpty) continue;

      if (source.topBlock!.isMystery) continue;

      int sourceSameColorCount = 0;
      for (int k = source.blocks.length - 1; k >= 0; k--) {
        if (!source.blocks[k].isMystery && source.blocks[k].colorId == source.topBlock!.colorId) {
          sourceSameColorCount++;
        } else { break; }
      }

      for (int j = 0; j < levelState.tubes.length; j++) {
        if (i == j) continue;
        Tube dest = levelState.tubes[j];

        if (dest.isFull) continue;

        int destAvailableSpace = dest.capacity - dest.blocks.length;

        if (destAvailableSpace >= sourceSameColorCount) {
          bool isUselessMove = dest.isEmpty && (sourceSameColorCount == source.blocks.length);

          if (!isUselessMove) {
            if (dest.isEmpty || (!dest.topBlock!.isMystery && dest.topBlock!.colorId == source.topBlock!.colorId)) {
              hasMoves = true;
              break;
            }
          }
        }
      }
      if (hasMoves) break;
    }

    if (hasMoves) return;

    _noMoreMovesDialogShown = true;
    showNoMoreMovesDialog();
  }

  Future<void> showHint() async {
    if (isPouring) return;

    int? foundFrom;
    int? foundTo;
    for (int from = 0; from < levelState.tubes.length; from++) {
      for (int to = 0; to < levelState.tubes.length; to++) {
        if (from == to) continue;
        final fromTube = levelState.tubes[from];
        final toTube = levelState.tubes[to];

        if (fromTube.isEmpty || toTube.isFull) continue;
        final colorId = fromTube.topBlock!.colorId;

        int sourceSameColorCount = 0;
        for (int k = fromTube.blocks.length - 1; k >= 0; k--) {
          if (!fromTube.blocks[k].isMystery && fromTube.blocks[k].colorId == colorId) {
            sourceSameColorCount++;
          } else {
            break;
          }
        }

        int destAvailableSpace = toTube.capacity - toTube.blocks.length;

        if (destAvailableSpace >= sourceSameColorCount) {
          if (toTube.isEmpty || (!toTube.topBlock!.isMystery && toTube.topBlock!.colorId == colorId)) {
            foundFrom = from;
            foundTo = to;
            break;
          }
        }
      }
      if (foundFrom != null) break;
    }

    if (foundFrom == null || foundTo == null) return;

    if (isChallengeMode) {
      if (hintsCount <= 0) return;

      setState(() {
        hintsCount--;
        selectedTubeIndex = null;
        hintFromIndex = foundFrom;
        hintToIndex = foundTo;
      });

      return;
    }
    void executeHint() {
      setState(() {
        selectedTubeIndex = null;
        hintFromIndex = foundFrom;
        hintToIndex = foundTo;
      });
    }

    if (hintsCount > 0) {
      final updatedProfile = profile.copyWith(hintsCount: hintsCount - 1);
      await SaveService.saveProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        profile = updatedProfile;
        hintsCount = updatedProfile.hintsCount;
      });
      executeHint();
    } else {
      AdsService.watchForHint(() {
        if (mounted) executeHint();
      });
    }
  }

  Future<void> undo() async {
    if (history.isEmpty || isPouring) return;
    if (isChallengeMode) {
      if (undosCount <= 0) return;

      setState(() {
        levelState = history.removeLast();
        completedTubeIndexes = getCompletedTubeIndexes();
        celebratingTubeIndexes.clear();
        selectedTubeIndex = null;
        hintFromIndex = null;
        hintToIndex = null;
        isPouring = false;
        _pendingPour = null;
        _winDialogShown = false;

        if (moves > 0) moves--;
        undosCount--;
      });

      return;
    }
    void executeUndo() {
      setState(() {
        levelState = history.removeLast();
        completedTubeIndexes = getCompletedTubeIndexes();
        celebratingTubeIndexes.clear();
        selectedTubeIndex = null;
        hintFromIndex = null;
        hintToIndex = null;
        isPouring = false;
        _pendingPour = null;
        _winDialogShown = false;
        if (moves > 0) moves--;
        if (!isChallengeMode) {
          SaveService.saveMoves(moves);
        }
      });
    }

    if (undosCount > 0) {
      final updatedProfile = profile.copyWith(undosCount: undosCount - 1);
      await SaveService.saveProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        profile = updatedProfile;
        undosCount = updatedProfile.undosCount;
      });
      executeUndo();
    } else {
      AdsService.watchToContinue(() {
        if (mounted) executeUndo();
      });
    }
  }

  Future<void> addExtraTube() async {
    if (isPouring) return;
    if (isChallengeMode) {
      return;
    }
    void executeAddTube() {
      setState(() {
        history.add(levelState.clone());
        levelState.tubes.add(Tube(capacity: 4));
        _tubeKeys[levelState.tubes.length - 1] = GlobalKey();
      });
    }

    if (extraTubesCount > 0) {
      final updatedProfile = profile.copyWith(extraTubesCount: extraTubesCount - 1);
      await SaveService.saveProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        profile = updatedProfile;
        extraTubesCount = updatedProfile.extraTubesCount;
      });
      executeAddTube();
    } else {
      AdsService.watchForExtraTube(() {
        if (mounted) executeAddTube();
      });
    }
  }

  void resetLevel() {
    loadLevel();
  }

  void nextLevel() {
    currentLevel++;
    winCounter++;
    loadLevel();

    if (winCounter > 0 && winCounter % 3 == 0) {
      AdsService.showInterstitial();
    }
  }

  void _addTubeToCurrentLevel() {
    setState(() {
      history.add(levelState.clone());
      levelState.tubes.add(Tube(capacity: 4));
      _tubeKeys[levelState.tubes.length - 1] = GlobalKey();
    });
  }

  Future<void> _spendHeartAndGoHome() async {
    if (hearts > 0) {
      final updatedProfile = await HeartsService.spendHeart(profile);
      if (mounted) {
        setState(() {
          profile = updatedProfile;
          hearts = updatedProfile.hearts;
        });
      }
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).pop();
  }

  void showNoMoreMovesDialog() {
    if (isChallengeMode) {
      _finishChallenge(failed: true);
      return;
    }

    SoundService.playLoseSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final loc = AppLocalizations.of(context)!;
        final canUseTube =
            !isChallengeMode && (coins >= tubePrice || extraTubesCount > 0);

        return CustomLoseDialog(
          loc: loc,
          coins: coins,
          extraTubesCount: extraTubesCount,
          canUseTube: canUseTube,
          tubePrice: tubePrice,
          onRestart: () async {
            if (isChallengeMode) {
              Navigator.of(context, rootNavigator: true).pop();
              loadLevel();
              return;
            }

            final String lang = Localizations.localeOf(context).languageCode;
            String alertTitle = "Warning";
            String alertMsg = "Not enough hearts! Wait for refill.";
            String btnText = "OK";

            if (lang == 'ar') {
              alertTitle = "تنبيه";
              alertMsg = "لا تملك قلوباً كافية! انتظر أو احصل على المزيد.";
              btnText = "موافق";
            } else if (lang == 'pt') {
              alertTitle = "Aviso";
              alertMsg = "Não tem corações suficientes! Espere ou consiga mais.";
              btnText = "OK";
            }

            if (hearts <= 0) {
              showDialog(
                context: context,
                builder: (alertContext) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  title: Text(
                      alertTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)
                  ),
                  content: Text(alertMsg, textAlign: TextAlign.center),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(alertContext).pop(),
                      child: Text(btnText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              return;
            }

            final updatedProfile = await HeartsService.spendHeart(profile);
            if (mounted) {
              setState(() {
                profile = updatedProfile;
                hearts = updatedProfile.hearts;
              });
              Navigator.of(context, rootNavigator: true).pop();
              loadLevel();
            }
          },
          onUseExtraTube: () async {
            Navigator.of(context, rootNavigator: true).pop();

            if (extraTubesCount > 0) {
              final updatedProfile = profile.copyWith(
                extraTubesCount: extraTubesCount - 1,
              );
              await SaveService.saveProfile(updatedProfile);
              if (!mounted) return;

              setState(() {
                profile = updatedProfile;
                extraTubesCount = updatedProfile.extraTubesCount;
              });

              _addTubeToCurrentLevel();
              _noMoreMovesDialogShown = false;
              return;
            }

            if (coins >= tubePrice) {
              final updatedProfile = profile.copyWith(
                coins: coins - tubePrice,
              );
              await SaveService.saveProfile(updatedProfile);
              if (!mounted) return;

              setState(() {
                profile = updatedProfile;
                coins = updatedProfile.coins;
              });

              _addTubeToCurrentLevel();
              _noMoreMovesDialogShown = false;
            }
          },
          onWatchAdForTube: () {
            AdsService.watchForExtraTube(() {
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              _addTubeToCurrentLevel();
              _noMoreMovesDialogShown = false;
            });
          },
          onBackHome: () {
            _spendHeartAndGoHome();
          },
        );
      },
    );
  }

  Future<void> _finishChallenge({bool failed = false}) async {
    if (!isChallengeMode || widget.challengeMatchId == null) return;
    if (_challengeSubmitted) return;

    _challengeSubmitted = true;

    final elapsedMs = _challengeStartTime == null
        ? 0
        : DateTime.now().difference(_challengeStartTime!).inMilliseconds;

    final resultTimeMs = failed ? _challengeFailedTimeMs : elapsedMs;

    try {
      await ChallengeService.submitFinishTime(
        matchId: widget.challengeMatchId!,
        timeMs: resultTimeMs,
      );
    } catch (e) {
      debugPrint('CHALLENGE FINISH ERROR: $e');
      _challengeSubmitted = false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge error: $e')),
      );
      return;
    }

    if (!mounted) return;

    if (failed) {
      SoundService.playLoseSound();
    } else {
      _confettiController.play();
      SoundService.playWinSound();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final loc = AppLocalizations.of(context)!;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ChallengeService.watchChallenge(widget.challengeMatchId!),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            if (data == null || data['status'] != 'finished') {
              return AlertDialog(
                backgroundColor: const Color(0xFF162033),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  failed ? loc.challengeFailed : loc.challengeWaitingResult,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.amber),
                    const SizedBox(height: 20),
                    Text(
                      '${loc.yourTime}: ${_formatChallengeTime(loc, resultTimeMs)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.challengeWaitingResult,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            final hostId = data['hostId'];
            final hostTime = _readInt(data['hostTimeMs']);
            final guestTime = _readInt(data['guestTimeMs']);
            final winnerId = data['winnerId'];

            return FutureBuilder<String>(
              future: ChallengeService.getCurrentUserId(),
              builder: (context, idSnapshot) {
                final myId = idSnapshot.data;
                final isHost = myId == hostId;
                final didWin = myId != null && myId == winnerId;

                final myTime = isHost ? hostTime : guestTime;
                final opponentTime = isHost ? guestTime : hostTime;

                return AlertDialog(
                  backgroundColor: const Color(0xFF162033),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  title: Text(
                    didWin
                        ? '🏆 ${loc.challengeYouWin}'
                        : '😢 ${loc.challengeYouLose}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: didWin ? Colors.amber : Colors.redAccent,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${loc.yourTime}: ${_formatChallengeTime(loc, myTime)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${loc.opponentTime}: ${_formatChallengeTime(loc, opponentTime)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(loc.backHome),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }


  Future<void> showWinDialog() async{
    await MissionService.incrementLevelCount();
    if (isChallengeMode) {
      await _finishChallenge();
      return;
    }

    final earnedStars = calculateStars();
    final updatedProfile = profile.copyWith(
      coins: profile.coins + winRewardCoins,
      currentLevel: currentLevel + 1,
      highestUnlockedLevel: currentLevel + 1 > profile.highestUnlockedLevel ? currentLevel + 1 : profile.highestUnlockedLevel,
      totalLevelsCompleted: profile.totalLevelsCompleted + 1,
      totalCoinsEarned: profile.totalCoinsEarned + winRewardCoins,
    );

    await SaveService.saveProfile(updatedProfile);
    await SaveService.completedLevel(level: currentLevel, stars: earnedStars, moves: moves);

    if (!mounted) return;
    setState(() { profile = updatedProfile; coins = updatedProfile.coins; hearts = updatedProfile.hearts; });

    _confettiController.play();
    SoundService.playWinSound();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomWinDialog(
              loc: AppLocalizations.of(context)!,
              stars: earnedStars,
              moves: moves,
              coinsEarned: winRewardCoins,
              tickerProvider: this,
              onWatchAdReward: () {
                if (_winAdRewardClaimed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reward already claimed.')),
                  );
                  return;
                }

                AdsService.watchForCoins((rewardCoins) async {
                  if (!mounted || _winAdRewardClaimed) return;

                  _winAdRewardClaimed = true;

                  final updatedProfile = profile.copyWith(
                    coins: profile.coins + winAdRewardCoins,
                    totalCoinsEarned:
                    profile.totalCoinsEarned + winAdRewardCoins,
                  );

                  await SaveService.saveProfile(updatedProfile);
                  if (!mounted) return;

                  setState(() {
                    profile = updatedProfile;
                    coins = updatedProfile.coins;
                  });
                });
              },
              onNextLevel: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Future.delayed(const Duration(milliseconds: 200));
                if (!mounted) return;
                nextLevel();
              },
            ),
            IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
                gravity: 0.1,
                numberOfParticles: 40,
                emissionFrequency: 0.05,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkDailyReward() async {
    final lastDate = await SaveService.loadLastRewardDate();
    final today = DateTime.now().toString().substring(0, 10);
    if (lastDate != today && !dailyRewardShown) {
      dailyRewardShown = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) showDailyRewardDialog();
      });
    }
  }

  int getRewardAmount(int day) {
    const rewards = [50, 75, 100, 150, 200, 300, 500];
    return rewards[(day - 1).clamp(0, 6)];
  }

  Future<void> showDailyRewardDialog() async {
    final currentDay = await SaveService.loadRewardDay();
    final rewardAmount = getRewardAmount(currentDay);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF162033),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            '🎁 ${loc.dailyReward}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${loc.claim} 🪙 $rewardAmount ${loc.coins}!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                final today = DateTime.now().toString().substring(0, 10);
                final updatedProfile = profile.copyWith(
                  coins: profile.coins + rewardAmount,
                  totalCoinsEarned: profile.totalCoinsEarned + rewardAmount,
                );
                await SaveService.saveProfile(updatedProfile);
                await SaveService.saveLastRewardDate(today);
                await SaveService.saveRewardDay(currentDay >= 7 ? 1 : currentDay + 1);
                if (!mounted) return;
                setState(() { profile = updatedProfile; coins = updatedProfile.coins; });
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Text(loc.claim.toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  Widget _topInfoBar(AppLocalizations loc) {
    final timerText = HeartsService.nextHeartCountdown(profile.nextHeartTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF162033), borderRadius: BorderRadius.circular(18)),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          Text('🪙 $coins', style: const TextStyle(color: Colors.amber, fontSize: 17, fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('❤️ $hearts', style: const TextStyle(color: Colors.redAccent, fontSize: 17, fontWeight: FontWeight.bold)),
              if (hearts < 5 && timerText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(timerText, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
              ]
            ],
          ),
          Text('💡 $hintsCount', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('↩️ $undosCount', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('${loc.moves}: $moves', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getTubeColumns(int tubeCount) {
    if (tubeCount <= 4) return 4;
    if (tubeCount <= 6) return 3;
    if (tubeCount <= 8) return 4;
    if (tubeCount <= 10) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101827),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final int tubeCount = levelState.tubes.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isChallengeMode ? loc.challenge : '${loc.level} $currentLevel',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isChallengeMode)
            IconButton(
              onPressed: resetLevel,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        key: _boardKey,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000814),
                  Color(0xFF2B0A5A),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),

                const SizedBox(height: 14),
                _topInfoBar(loc),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = _getTubeColumns(tubeCount);
                      final rows = (tubeCount / columns).ceil();

                      const horizontalPadding = 16.0;
                      const verticalPadding = 10.0;

                      final spacing = tubeCount > 10 ? 8.0 : 12.0;
                      final runSpacing = rows >= 3 ? 10.0 : 18.0;

                      final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                      final availableHeight = constraints.maxHeight - (verticalPadding * 2);

                      double tubeWidth =
                      ((availableWidth - (spacing * (columns - 1))) / columns)
                          .clamp(38.0, 72.0)
                          .toDouble();

                      double tubeHeight = (tubeWidth * 2.55)
                          .clamp(105.0, 185.0)
                          .toDouble();

                      final maxHeightByRows =
                          (availableHeight - (runSpacing * (rows - 1))) / rows;

                      if (tubeHeight > maxHeightByRows) {
                        tubeHeight = maxHeightByRows.clamp(95.0, 185.0).toDouble();
                        tubeWidth = (tubeHeight / 2.55).clamp(38.0, 72.0).toDouble();
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalPadding,
                          ),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: runSpacing,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: List.generate(tubeCount, (index) {
                              final bool isSourceTube = _pendingPour != null && _pendingPour!.fromIndex == index;

                              return Opacity(
                                opacity: isSourceTube ? 0.0 : 1.0,
                                child: TubeWidget(
                                  key: _tubeKeys[index],
                                  tube: levelState.tubes[index],
                                  isSelected: selectedTubeIndex == index,
                                  isHinted: hintFromIndex == index || hintToIndex == index,
                                  showCelebration: celebratingTubeIndexes.contains(index),
                                  onTap: () => onTubeTap(index),
                                  width: tubeWidth,
                                  height: tubeHeight,
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!isChallengeMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28, top: 10),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: undo,
                          icon: Icon(
                            undosCount > 0 ? Icons.undo : Icons.ondemand_video,
                            size: 20,
                          ),
                          label: Text(
                            undosCount > 0 ? '${loc.undo} $undosCount' : loc.undo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: undosCount > 0
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFFF59E0B),
                            foregroundColor: undosCount > 0
                                ? const Color(0xFF162033)
                                : Colors.white,
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: showHint,
                          icon: Icon(
                            hintsCount > 0 ? Icons.lightbulb : Icons.ondemand_video,
                            size: 20,
                          ),
                          label: Text(
                            hintsCount > 0 ? '${loc.hint} $hintsCount' : loc.hint,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hintsCount > 0
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF10B981),
                            foregroundColor: hintsCount > 0
                                ? const Color(0xFF162033)
                                : Colors.white,
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: addExtraTube,
                          icon: Icon(
                            extraTubesCount > 0 ? Icons.add : Icons.ondemand_video,
                            size: 20,
                          ),
                          label: Text(
                            extraTubesCount > 0 ? '${loc.tube} $extraTubesCount' : loc.tube,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: extraTubesCount > 0
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF3B82F6),
                            foregroundColor: extraTubesCount > 0
                                ? const Color(0xFF162033)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_pendingPour != null)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1800),
              curve: Curves.linear,
              builder: (context, progress, child) {
                final pour = _pendingPour!;
                return PourEffectLayer(
                  fromRect: pour.fromRect,
                  toRect: pour.toRect,
                  color: pour.color,
                  progress: progress,
                  moveCount: pour.moveCount,
                  fromTube: levelState.tubes[pour.fromIndex],
                  toTube: levelState.tubes[pour.toIndex],
                );
              },
            ),
        ],
      ),
    );
  }
}

class AnimatedStar extends StatefulWidget {
  final bool isFull;
  final double delay;

  const AnimatedStar({super.key, required this.isFull, required this.delay});

  @override
  State<AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<AnimatedStar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 30),
    ]).animate(_controller);

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white10, size: 55),
                if (widget.isFull)
                  Opacity(
                    opacity: _fillAnimation.value,
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 55,
                      shadows: [Shadow(color: Colors.amberAccent, blurRadius: 15)],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomWinDialog extends StatelessWidget {
  final AppLocalizations loc;
  final int stars;
  final int moves;
  final int coinsEarned;
  final TickerProvider tickerProvider;
  final VoidCallback onNextLevel;
  final VoidCallback onWatchAdReward;

  const CustomWinDialog({
    super.key,
    required this.loc,
    required this.stars,
    required this.moves,
    required this.coinsEarned,
    required this.tickerProvider,
    required this.onWatchAdReward,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF323B55), Color(0xFF101420), Color(0xFF080A10)],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 40, offset: const Offset(0, 20)),
              BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 50, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        loc.winTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedStar(isFull: stars >= 1, delay: 0.0),
                  const SizedBox(width: 10),
                  Transform.translate(
                      offset: const Offset(0, -10),
                      child: SizedBox(
                          width: 70, height: 70,
                          child: FittedBox(child: AnimatedStar(isFull: stars >= 2, delay: 0.4)))
                  ),
                  const SizedBox(width: 10),
                  AnimatedStar(isFull: stars >= 3, delay: 0.8),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                '${loc.solvedInMoves} $moves ${loc.moves}',
                style: const TextStyle(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: coinsEarned),
                  duration: const Duration(seconds: 1, milliseconds: 500),
                  builder: (context, value, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+$value',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            shadows: [Shadow(color: Color(0xFFFFECB3), blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('🪙', style: TextStyle(fontSize: 28)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: onNextLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: const BorderSide(color: Color(0xFF6EE7B7), width: 1),
                  ),
                  child: Text(
                    loc.nextLevel.toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: onWatchAdReward,
                  icon: const Icon(Icons.ondemand_video),
                  label: const Text(
                    '+100 COINS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFFF97316).withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomLoseDialog extends StatelessWidget {
  final AppLocalizations loc;
  final int coins;
  final int extraTubesCount;
  final bool canUseTube;
  final int tubePrice;
  final VoidCallback onRestart;
  final VoidCallback onUseExtraTube;
  final VoidCallback onWatchAdForTube;
  final VoidCallback onBackHome;

  const CustomLoseDialog({
    super.key,
    required this.loc,
    required this.coins,
    required this.extraTubesCount,
    required this.canUseTube,
    required this.tubePrice,
    required this.onRestart,
    required this.onUseExtraTube,
    required this.onWatchAdForTube,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF421A25), Color(0xFF161A25)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Text('😵', style: TextStyle(fontSize: 50)),
              ),
              const SizedBox(height: 20),
              Text(
                loc.outOfMoves,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                '❤️ -1 ${loc.heartLost}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: Text(
                    loc.tryAgain.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: onWatchAdForTube,
                  icon: const Icon(Icons.ondemand_video, size: 24),
                  label: Text(
                    loc.watchAdForTube,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: canUseTube ? onUseExtraTube : null,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  label: Text(
                    extraTubesCount > 0 ? loc.useExtraTube : '${loc.tube} -$tubePrice',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    disabledBackgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: onBackHome,
                child: Text(
                  loc.backHome,
                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}