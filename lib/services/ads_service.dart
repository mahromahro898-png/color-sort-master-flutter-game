/// ══════════════════════════════════════════════════════════
///  ads_service.dart
///  Serviço de Monetização (Google Mobile Ads / AdMob) - Gerenciamento centralizado do ciclo de vida, pre-loading de anúncios e proteção de UX
/// ══════════════════════════════════════════════════════════
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:color_sort_master/services/mission_service.dart';

class AdsService {
  AdsService._();

  static const String bannerAdId =
      'ca-app-pub-4909113673256853/7361778984';

  static const String _rewardedAdId =
      'ca-app-pub-4909113673256853/1564030543';

  static const String _interstitialAdId =
      'ca-app-pub-4909113673256853/6781869065';

  static bool _isInitialized = false;

  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();

    _isInitialized = true;
    await loadRewarded();
    await loadInterstitial();
  }

  static Future<void> loadRewarded() async {
    if (!_isInitialized) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded ad loaded');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  static Future<bool> showRewarded({
    required void Function() onRewarded,
    void Function()? onFailed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad is not ready');
      onFailed?.call();
      await loadRewarded();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        onFailed?.call();
        loadRewarded();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('🎁 User earned reward');
        onRewarded();
      },
    );

    return true;
  }

  static Future<void> loadInterstitial() async {
    if (!_isInitialized) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial ad loaded');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<bool> showInterstitial() async {
    if (await MissionService.isAdFreeActive()) {
      return false; // 💡 Regra de negócio (Premium): Retorna 'false' imediatamente caso o usuário possua status 'Ad-Free' ativo, protegendo a UX
    }
    if (_interstitialAd == null) {
      await loadInterstitial();
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );

    await _interstitialAd!.show();
    return true;
  }

  static Future<bool> watchForCoins(void Function(int coins) onRewarded) async {
    return showRewarded(onRewarded: () => onRewarded(200));
  }

  static Future<bool> watchForHeart(void Function() onRewarded) async {
    return showRewarded(onRewarded: onRewarded);
  }

  static Future<bool> watchForHint(void Function() onRewarded) async {
    return showRewarded(onRewarded: onRewarded);
  }

  static Future<bool> watchToContinue(void Function() onRewarded) async {
    return showRewarded(onRewarded: onRewarded);
  }

  static Future<bool> watchForExtraTube(void Function() onRewarded) async {
    return showRewarded(onRewarded: onRewarded);
  }

  static bool get isRewardedReady => _rewardedAd != null;
  static bool get isInterstitialReady => _interstitialAd != null;
}