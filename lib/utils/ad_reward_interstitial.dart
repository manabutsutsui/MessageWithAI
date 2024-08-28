import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RewardedInterstitialAdManager {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialAdReady = false;

  Future<void> loadAd() async {
    final String adUnitId = await _getAdUnitId();

    await RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showAd(VoidCallback onAdDismissed) async {
    if (!_isRewardedInterstitialAdReady) {
      await loadAd();
      if (!_isRewardedInterstitialAdReady) {
        onAdDismissed();
        return;
      }
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
      },
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        _isRewardedInterstitialAdReady = false;
        onAdDismissed();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        ad.dispose();
        _isRewardedInterstitialAdReady = false;
        onAdDismissed();
        loadAd();
      },
    );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      },
    );
  }

  Future<String> _getAdUnitId() async {
    final String configContent = await rootBundle.loadString('assets/config.json');
    final Map<String, dynamic> config = json.decode(configContent);
    return Platform.isAndroid
        ? config['androidRewardedInterstitialAdUnitId']
        : config['iosRewardedInterstitialAdUnitId'];
  }

  bool isAdReady() {
    return _isRewardedInterstitialAdReady;
  }
}
