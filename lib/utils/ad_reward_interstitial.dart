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
    print('広告の読み込みを開始します。AdUnitId: $adUnitId');

    await RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          print('リワードインタースティシャル広告の読み込みが完了しました。');
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('リワードインタースティシャル広告の読み込みに失敗しました: $error');
          _isRewardedInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showAd(VoidCallback onAdDismissed) async {
    print('showAdメソッドが呼び出されました。');
    if (!_isRewardedInterstitialAdReady) {
      print('広告はまだ準備ができていません。再度読み込みを試みます。');
      await loadAd();
      if (!_isRewardedInterstitialAdReady) {
        print('広告の準備に失敗しました。onAdDismissedを呼び出します。');
        onAdDismissed();
        return;
      }
    }

    print('広告の表示を試みます。');
    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
        print('広告がフルスクリーンで表示されました。');
      },
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        print('広告が閉じられました。');
        ad.dispose();
        _isRewardedInterstitialAdReady = false;
        onAdDismissed();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        print('リワードインタースティシャル広告の表示に失敗しました: $error');
        ad.dispose();
        _isRewardedInterstitialAdReady = false;
        onAdDismissed();
        loadAd();
      },
    );

    await _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('ユーザーが報酬を獲得しました: ${reward.amount} ${reward.type}');
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
