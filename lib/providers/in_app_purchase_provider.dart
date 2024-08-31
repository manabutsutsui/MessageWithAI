import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

class InAppPurchaseNotifier extends StateNotifier<bool> {
  InAppPurchaseNotifier() : super(false) {
    _initPurchases();
  }

  Future<void> _initPurchases() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      PurchasesConfiguration config = PurchasesConfiguration('appl_cdWSpEJBdEQKmBYGohthDuHkDBG');
      await Purchases.configure(config);
      await _updatePurchaseStatus();
      
      // オファリングの取得を試みる
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        print('現在のオファリングがありません');
      } else {
        print('現在のオファリング: ${offerings.current!.identifier}');
        print('利用可能なパッケージ: ${offerings.current!.availablePackages.length}');
      }
    } catch (e) {
      print('RevenueCatの初期化エラー: $e');
      if (e is PlatformException) {
        print('エラーコード: ${e.code}');
        print('エラーメッセージ: ${e.message}');
        print('エラーの詳細: ${e.details}');
      } else {
        print('エラーの詳細: ${e.toString()}');
      }
    }
  }

  Future<void> _updatePurchaseStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      state = customerInfo.entitlements.active.containsKey('Monthly_subscription');
    } catch (e) {
      print('購入状態の更新エラー: $e');
    }
  }

  Future<void> purchasePremium() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        Package package = offerings.current!.availablePackages.first;
        await Purchases.purchasePackage(package);
        await _updatePurchaseStatus();
      }
    } catch (e) {
      print('プレミアム購入エラー: $e');
      if (e is PlatformException) {
        print('エラーコード: ${e.code}');
        print('エラーメッセージ: ${e.message}');
        print('エラーの詳細: ${e.details}');
      }
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      await _updatePurchaseStatus();
    } catch (e) {
      print('購入の復元エラー: $e');
    }
  }

  bool isPremium() {
    return state;
  }
}

final inAppPurchaseProvider =
    StateNotifierProvider<InAppPurchaseNotifier, bool>((ref) {
  return InAppPurchaseNotifier();
});
