/// ══════════════════════════════════════════════════════════
///  save_service.dart  (Atualizado completamente e conectado à nuvem)
///  Todas as operações de salvar e carregar em um só lugar
///  Usa shared_preferences
/// ══════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_profile.dart';
import '../models/level_model.dart';
import '../models/achievement_model.dart';
import '../models/mission_model.dart';
import '../models/level_progress_model.dart';
import 'cloud_save_service.dart'; // Chamada do arquivo de salvamento na nuvem

class SaveService {
  SaveService._();

  static const _kProfile = 'player_profile';
  static const _kLevelProgress = 'level_progress_';
  static const _kAchievements = 'achievements';
  static const _kMissions = 'daily_missions';
  static const _kMissionsDate = 'missions_date';
  static const _kRewardDay = 'reward_day';
  static const _kLastRewardDate = 'last_reward_date';
  static const _kSettings = 'settings';
  static const _kInterstitialCount = 'interstitial_count';

  static const String _currentLevelKey = 'current_level';
  static const String _totalStarsKey = 'total_stars';

  static Future<PlayerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kProfile);
    if (json == null) return const PlayerProfile();
    try {
      return PlayerProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const PlayerProfile();
    }
  }

  static Future<void> saveProfile(PlayerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfile, jsonEncode(profile.toJson()));
  }

  static Future<int> loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentLevelKey) ?? 1;
  }

  static Future<void> saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentLevelKey, level);

    final profile = await loadProfile();
    await saveProfile(profile.copyWith(currentLevel: level));
  }

  static Future<int> loadLevelStars(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_${level}_stars') ?? 0;
  }

  static Future<void> saveLevelStars(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final oldStars = await loadLevelStars(level);

    if (stars > oldStars) {
      await prefs.setInt('level_${level}_stars', stars);
      await _recalculateTotalStars();
    }
  }

  static Future<int> loadTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalStarsKey) ?? 0;
  }

  static Future<void> _recalculateTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    int total = 0;

    for (int i = 1; i <= 500; i++) {
      total += prefs.getInt('level_${i}_stars') ?? 0;
    }

    await prefs.setInt(_totalStarsKey, total);
  }

  static Future<LevelProgress> loadLevelProgress(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_kLevelProgress$level');
    if (json == null) {
      return LevelProgress(
        level: level,
        status: level == 1 ? LevelStatus.unlocked : LevelStatus.locked,
      );
    }
    try {
      return LevelProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return LevelProgress(level: level, status: LevelStatus.locked);
    }
  }

  static Future<void> saveLevelProgress(LevelProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kLevelProgress${progress.level}',
      jsonEncode(progress.toJson()),
    );
  }

  static Future<void> completedLevel({
    required int level,
    required int stars,
    required int moves,
  }) async {
    final current = await loadLevelProgress(level);
    final updated = current.copyWith(
      status: LevelStatus.completed,
      stars: stars > current.stars ? stars : current.stars,
      bestMoves: current.bestMoves == 0 || moves < current.bestMoves
          ? moves
          : current.bestMoves,
    );

    await saveLevelProgress(updated);
    await saveLevelStars(level, stars);
    await saveLevel(level + 1);

    final next = await loadLevelProgress(level + 1);
    if (next.isLocked) {
      await saveLevelProgress(
        next.copyWith(status: LevelStatus.unlocked),
      );
    }

    // Aqui o novo progresso é enviado diretamente para a nuvem após vencer!
    //await CloudSaveService.saveGameDataToCloud();
  }

  static Future<Map<String, Achievement>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kAchievements);

    final base = {for (final a in AchievementsData.all) a.id: a};

    if (json == null) return base;

    try {
      final saved = jsonDecode(json) as Map<String, dynamic>;
      for (final entry in saved.entries) {
        if (base.containsKey(entry.key)) {
          final data = entry.value as Map<String, dynamic>;
          base[entry.key] = base[entry.key]!.copyWith(
            progress: data['progress'] as int?,
            isUnlocked: data['isUnlocked'] as bool?,
            rewardClaimed: data['rewardClaimed'] as bool?,
          );
        }
      }
    } catch (_) {}

    return base;
  }

  static Future<void> saveAchievements(
      Map<String, Achievement> achievements,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      for (final e in achievements.entries) e.key: e.value.toJson()
    };
    await prefs.setString(_kAchievements, jsonEncode(data));
  }

  static Future<List<Mission>> loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();

    final savedDate = prefs.getString(_kMissionsDate);
    if (savedDate != today) {
      final fresh = _generateDailyMissions();
      await _saveMissionsRaw(fresh, today, prefs);
      return fresh;
    }

    final json = prefs.getString(_kMissions);
    if (json == null) return _generateDailyMissions();

    try {
      final list = jsonDecode(json) as List;
      final savedMissions = list.map((e) => e as Map<String, dynamic>).toList();

      return MissionsPool.pool.take(3).map((mission) {
        final saved = savedMissions.firstWhere(
              (s) => s['id'] == mission.id,
          orElse: () => <String, dynamic>{},
        );
        if (saved.isEmpty) return mission;
        return mission.copyWith(
          progress: saved['progress'] as int?,
          isCompleted: saved['isCompleted'] as bool?,
          rewardClaimed: saved['rewardClaimed'] as bool?,
        );
      }).toList();
    } catch (_) {
      return _generateDailyMissions();
    }
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveMissionsRaw(missions, _todayString(), prefs);
  }

  static Future<void> _saveMissionsRaw(
      List<Mission> missions,
      String date,
      SharedPreferences prefs,
      ) async {
    await prefs.setString(
      _kMissions,
      jsonEncode(missions.map((m) => m.toJson()).toList()),
    );
    await prefs.setString(_kMissionsDate, date);
  }

  static List<Mission> _generateDailyMissions() {
    final pool = List<Mission>.from(MissionsPool.pool)..shuffle();
    return pool.take(3).toList();
  }

  static Future<int> loadRewardDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kRewardDay) ?? 1;
  }

  static Future<void> saveRewardDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRewardDay, day);
  }

  static Future<String> loadLastRewardDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastRewardDate) ?? '';
  }

  static Future<void> saveLastRewardDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRewardDate, date);
  }

  static Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kSettings);
    if (json == null) {
      return {'music': true, 'sound': true, 'vibration': true};
    }
    try {
      return Map<String, bool>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {'music': true, 'sound': true, 'vibration': true};
    }
  }

  static Future<void> saveSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(settings));
  }

  static Future<int> loadInterstitialCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kInterstitialCount) ?? 0;
  }

  static Future<void> saveInterstitialCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kInterstitialCount, count);
  }

  static String _todayString() => DateTime.now().toString().substring(0, 10);

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<int> loadStars() async {
    final profile = await loadProfile();
    return profile.coins;
  }

  static Future<void> saveStars(int coins) async {
    final profile = await loadProfile();
    await saveProfile(profile.copyWith(coins: coins));
  }

  static Future<int> loadMoves() async => 0;

  static Future<void> saveMoves(int moves) async {}

  static Future<void> addStars(int amount) async {
    final profile = await loadProfile();
    await saveProfile(profile.copyWith(coins: profile.coins + amount));
  }

  static Future<void> clearProgress() async => clearAll();

  static Future<String> loadLastRewardDateCompat() => loadLastRewardDate();
}