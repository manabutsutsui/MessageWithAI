import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'ad_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SubscriptionPlan {
  final String name;
  final String price;
  final String features;
  final String productId;
  final String duration;

  SubscriptionPlan({
    required this.name,
    required this.price,
    required this.features,
    required this.productId,
    required this.duration,
  });
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => SubscriptionScreenState();
}

class SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  String _selectedPlan = 'free_plan';
  bool _showAds = true;

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      name: 'Free',
      price: '無料',
      features: '・画像生成10回/月\n・チャットのやり取り50回/月',
      productId: 'free_plan',
      duration: '1ヶ月',
    ),
    SubscriptionPlan(
      name: 'Standard',
      price: '500円/月',
      features: '・画像生成20回/月\n・チャットのやり取り200回/月',
      productId: 'standard_monthly_subscription',
      duration: '1ヶ月',
    ),
    SubscriptionPlan(
      name: 'Premium',
      price: '2000円/月',
      features: '・無制限のコンテンツアクセス\n・広告の非表示',
      productId: 'premium_monthly_subscription',
      duration: '1ヶ月',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      _handleError(error);
    });
    _initializeStore();
    _loadSelectedPlan(); // 選択されたプランをロード
    _loadAdVisibility();
  }

  Future<void> _loadAdVisibility() async {
    setState(() {
      _showAds = _selectedPlan != 'premium_monthly_subscription';
    });
  }

  Future<void> _updateAdVisibility(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final bool showAds = planId != 'premium_monthly_subscription';
    await prefs.setBool('showAds', showAds);
    setState(() {
      _showAds = showAds;
    });
  }

  Future<void> _loadSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPlan = prefs.getString('subscriptionPlan') ?? 'free_plan';
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        try {
          final valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
          }
        } catch (e) {
          _handleError(e as IAPError);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleError(purchaseDetails.error!);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('verifyPurchase');
      final result = await callable.call({
        'receiptData': purchaseDetails.verificationData.serverVerificationData,
      });

      if (result.data['isValid']) {
        return true;
      } else {
        print('購入検証エラー: ${result.data['error']}');
        return false;
      }
    } catch (e) {
      print('検証中にエラーが発生しました: $e');
      return false;
    }
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // 無効な購入の処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('購入の検証に失敗しました。サポートにお問い合わせください。')),
    );
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    // ここで購入したプランの情報を保存する
    // 例: SharedPreferencesを使用
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscriptionPlan', purchaseDetails.productID);
    await _updateAdVisibility(purchaseDetails.productID);
    setState(() {
      _selectedPlan = purchaseDetails.productID; // 選択されたプランを更新
    });
  }

  void _handleError(dynamic error) {
    String message = '購入中にエラーが発生しました';
    if (error is IAPError) {
      message += ': ${error.message}';
      if (error.details != null && error.details['message'] != null) {
        message += '\n${error.details['message']}';
      }
    } else {
      message += ': $error';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    print('購入エラー: $error');
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アプリ内購入が利用できません')),
        );
        return;
      }

      final Set<String> kIds = {
        'standard_monthly_subscription',
        'premium_monthly_subscription'
      };
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('見つからない製品ID: ${response.notFoundIDs}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('一部の製品情報の取得に失敗しました')),
        );
      }

      setState(() {
        _products = response.productDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('製品情報の取得エラー: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('製品情報の取得中にエラーが発生しました: $e')),
      );
    }
  }

  void _handlePurchase(SubscriptionPlan plan) async {
    if (plan.productId == 'free_plan') {
      // 無料プランの処理
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscriptionPlan', plan.productId);
      await _updateAdVisibility(plan.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無料プランが選択されました')),
      );
      setState(() {
        _selectedPlan = plan.productId; // 選択されたプランを更新
      });
    } else {
      try {
        final ProductDetails product = _products.firstWhere(
          (p) => p.id == plan.productId,
          orElse: () => throw StateError('商品が見つかりません: ${plan.productId}'),
        );
        final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
        final bool purchaseResult = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        
        if (purchaseResult) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${plan.name}プランの購入処理を開始しました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${plan.name}プランの購入に失敗しました')),
          );
        }
      } catch (e) {
        print('購入エラー: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('購入の復元を開始しました')),
      );
    } catch (e) {
      print('購入の復元エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('購入の復元中にエラーが発生しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サブスクリプション')),
      body: Column(
        children: [
          AdBanner(isVisible: _showAds),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildLegalLinks(),
                      for (final plan in _plans)
                        _buildPlanCard(plan),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _restorePurchases,
                        child: const Text('購入の復元'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = plan.productId == _selectedPlan;
    Color backgroundColor = _getPlanColor(plan.name);
    
    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
                if (isSelected)
                  _buildCurrentPlanBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text('価格: ${plan.price}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
            const SizedBox(height: 8),
            Text('期間: ${plan.duration}', style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 8),
            const Text('含まれる機能:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text(plan.features, style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSelected ? null : () => _handlePurchase(plan),
              child: const Text('選択'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '現在のプラン',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Column(
      children: [
        TextButton(
          onPressed: () => _launchURL('https://tsutsunoidoblog.com/message-with-ai-privacy-policy/'),
          child: const Text('プライバシーポリシー'),
        ),
        TextButton(
          onPressed: () => _launchURL('https://tsutsunoidoblog.com/message-with-ai-terms-of-use/'),
          child: const Text('利用規約'),
        ),
      ],
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Color _getPlanColor(String planName) {
    switch (planName) {
      case 'Free':
        return Colors.white;
      case 'Standard':
        return const Color.fromARGB(255, 30, 255, 236);
      case 'Premium':
        return const Color.fromARGB(255, 255, 218, 109);
      default:
        return Colors.white;
    }
  }
}