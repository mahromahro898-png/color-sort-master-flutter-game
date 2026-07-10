import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // =========================
  // Propriedades do Jogador (User Properties / Segmentation)
  // =========================

  static Future<void> setPlayerProperties({
    required int highestLevel,
    required int totalStars,
    required int coins,
  }) async {
    await _analytics.setUserProperty(
      name: 'highest_level',
      value: highestLevel.toString(),
    );

    await _analytics.setUserProperty(
      name: 'total_stars',
      value: totalStars.toString(),
    );

    await _analytics.setUserProperty(
      name: 'coin_range',
      value: _coinRange(coins),
    );

    await _analytics.setUserProperty(
      name: 'player_segment',
      value: _playerSegment(highestLevel),
    );
  }

  // =========================
  // Eventos de Nível (Core Gameplay Loop Tracking)
  // =========================

  static Future<void> logLevelStart({
    required int level,
    required String difficulty,
    required int colors,
    required int emptyTubes,
    required bool mystery,
  }) async {
    await _analytics.logEvent(
      name: 'level_start',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'colors': colors,
        'empty_tubes': emptyTubes,
        'mystery': mystery ? 1 : 0,
      },
    );
  }

  static Future<void> logLevelComplete({
    required int level,
    required String difficulty,
    required int moves,
    required int durationSeconds,
    required int stars,
    required int usedHint,
    required int usedUndo,
    required int usedExtraTube,
  }) async {
    await _analytics.logEvent(
      name: 'level_complete',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'moves': moves,
        'duration_seconds': durationSeconds,
        'stars': stars,
        'used_hint': usedHint,
        'used_undo': usedUndo,
        'used_extra_tube': usedExtraTube,
      },
    );
  }

  static Future<void> logLevelFail({
    required int level,
    required String difficulty,
    required int moves,
    required int durationSeconds,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'level_fail',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'moves': moves,
        'duration_seconds': durationSeconds,
        'reason': reason,
      },
    );
  }

  static Future<void> logLevelRestart({
    required int level,
    required String difficulty,
    required int movesBeforeRestart,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'level_restart',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'moves_before_restart': movesBeforeRestart,
        'duration_seconds': durationSeconds,
      },
    );
  }

  static Future<void> logLevelExit({
    required int level,
    required String difficulty,
    required int moves,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'level_exit',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'moves': moves,
        'duration_seconds': durationSeconds,
      },
    );
  }

  static Future<void> logProgressReached({
    required int highestLevel,
    required int totalStars,
    required int coins,
  }) async {
    await _analytics.logEvent(
      name: 'progress_reached',
      parameters: {
        'highest_level': highestLevel,
        'total_stars': totalStars,
        'coins': coins,
      },
    );

    await setPlayerProperties(
      highestLevel: highestLevel,
      totalStars: totalStars,
      coins: coins,
    );
  }

  // =========================
  // Eventos de Consumíveis (In-Game Helpers / Resource Sink Tracking)
  // =========================

  static Future<void> logHintUsed({required int level}) async {
    await _analytics.logEvent(
      name: 'hint_used',
      parameters: {'level': level},
    );
  }

  static Future<void> logUndoUsed({required int level}) async {
    await _analytics.logEvent(
      name: 'undo_used',
      parameters: {'level': level},
    );
  }

  static Future<void> logExtraTubeUsed({required int level}) async {
    await _analytics.logEvent(
      name: 'extra_tube_used',
      parameters: {'level': level},
    );
  }

  // =========================
  // Eventos de Retenção (Daily Engagement & LTV Tracking)
  // =========================

  static Future<void> logDailyRewardClaimed({
    required int day,
    required int rewardAmount,
  }) async {
    await _analytics.logEvent(
      name: 'daily_reward_claimed',
      parameters: {
        'day': day,
        'reward_amount': rewardAmount,
      },
    );
  }

  // =========================
  // Eventos de Desafio (Social/Multiplayer Engagement)
  // =========================

  static Future<void> logChallengeScreenOpen() async {
    await _analytics.logEvent(name: 'challenge_screen_open');
  }

  static Future<void> logChallengeCreated({
    required int level,
    required String difficulty,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_created',
      parameters: {
        'level': level,
        'difficulty': difficulty,
        'source': 'home_button',
      },
    );
  }

  static Future<void> logChallengeShared({
    required int level,
    required String method,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_shared',
      parameters: {
        'level': level,
        'method': method,
      },
    );
  }

  static Future<void> logChallengeJoined({
    required int level,
    required String joinMethod,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_joined',
      parameters: {
        'level': level,
        'join_method': joinMethod,
      },
    );
  }

  static Future<void> logChallengeCompleted({
    required int level,
    required String result,
    required int durationSeconds,
    required int moves,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_completed',
      parameters: {
        'level': level,
        'result': result,
        'duration_seconds': durationSeconds,
        'moves': moves,
      },
    );
  }

  static Future<void> logChallengeJoinFailed({
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'challenge_join_failed',
      parameters: {
        'reason': reason,
      },
    );
  }

  // =========================
  // Eventos de Loja (Monetization & Conversion Funnel)
  // =========================

  static Future<void> logStoreOpen({
    required int coins,
    required int hearts,
  }) async {
    await _analytics.logEvent(
      name: 'store_open',
      parameters: {
        'coins': coins,
        'hearts': hearts,
      },
    );
  }

  static Future<void> logStoreItemTap({
    required String itemId,
    required int price,
    required int coinsBefore,
  }) async {
    await _analytics.logEvent(
      name: 'store_item_tap',
      parameters: {
        'item_id': itemId,
        'price': price,
        'coins_before': coinsBefore,
      },
    );
  }

  static Future<void> logStorePurchaseSuccess({
    required String itemId,
    required int price,
    required int coinsAfter,
  }) async {
    await _analytics.logEvent(
      name: 'store_purchase_success',
      parameters: {
        'item_id': itemId,
        'price': price,
        'coins_after': coinsAfter,
      },
    );
  }

  static Future<void> logStorePurchaseFailed({
    required String itemId,
    required String reason,
    required int coins,
    required int price,
  }) async {
    await _analytics.logEvent(
      name: 'store_purchase_failed',
      parameters: {
        'item_id': itemId,
        'reason': reason,
        'coins': coins,
        'price': price,
      },
    );
  }

  // =========================
  // Eventos de Anúncios (Ad Monetization & Fill Rate Tracking)
  // =========================

  static Future<void> logRewardedAdCompleted({
    required String rewardType,
    required int rewardAmount,
    required String placement,
  }) async {
    await _analytics.logEvent(
      name: 'ad_rewarded_completed',
      parameters: {
        'reward_type': rewardType,
        'reward_amount': rewardAmount,
        'placement': placement,
      },
    );
  }

  static Future<void> logRewardedAdFailed({
    required String placement,
    required String reason,
  }) async {
    await _analytics.logEvent(
      name: 'ad_rewarded_failed',
      parameters: {
        'placement': placement,
        'reason': reason,
      },
    );
  }

  static Future<void> logInterstitialShown({
    required String placement,
  }) async {
    await _analytics.logEvent(
      name: 'ad_interstitial_shown',
      parameters: {
        'placement': placement,
      },
    );
  }

  // =========================
  // Eventos de Áudio (UX/UI Preferences)
  // =========================

  static Future<void> logMusicToggled({
    required bool enabled,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'music_toggled',
      parameters: {
        'enabled': enabled ? 1 : 0,
        'screen': screen,
      },
    );
  }

  static Future<void> logSfxToggled({
    required bool enabled,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'sfx_toggled',
      parameters: {
        'enabled': enabled ? 1 : 0,
        'screen': screen,
      },
    );
  }

  // =========================
  // Funções Auxiliares (Data Normalization & Segmentation Logic)
  // =========================

  static String _playerSegment(int highestLevel) {
    if (highestLevel <= 10) return 'new';
    if (highestLevel <= 50) return 'casual';
    if (highestLevel <= 100) return 'engaged';
    return 'advanced';
  }

  static String _coinRange(int coins) {
    if (coins < 100) return '0_99';
    if (coins < 500) return '100_499';
    if (coins < 1500) return '500_1499';
    return '1500_plus';
  }
}