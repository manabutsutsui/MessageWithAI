import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'ad_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SubscriptionPlan {
  final String name;
  final String price;
  final String features;
  final String productId;

  SubscriptionPlan({required this.name, required this.price, required this.features, required this.productId});
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
  String _selectedPlan = 'free_plan'; // 選択されたプランを示す状態変数

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      name: 'Free',
      price: '無料',
      features: '・画像生成10回/月\n・チャットのやり取り50回/月',
      productId: 'free_plan',
    ),
    SubscriptionPlan(
      name: 'Standard',
      price: '500円/月',
      features: '・画像生成20回/月\n・チャットのやり取り200回/月',
      productId: 'standard_monthly_subscription',
    ),
    SubscriptionPlan(
      name: 'Premium',
      price: '2000円/月',
      features: '・無制限のコンテンツアクセス\n・広告の非表示',
      productId: 'premium_monthly_subscription',
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
  }

  Future<void> _loadSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPlan = prefs.getString('subscriptionPlan') ?? 'free_plan';
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // 購入完了時の処理
        await _deliverProduct(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // エラー時の処理
        _handleError(purchaseDetails.error!);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    });
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    // ここで購入したプランの情報を保存する
    // 例: SharedPreferencesを使用
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscriptionPlan', purchaseDetails.productID);
    setState(() {
      _selectedPlan = purchaseDetails.productID; // 選択されたプランを更新
    });
  }

  void _handleError(IAPError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('購入中にエラーが発生しました: ${error.message}')),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      setState(() => _isLoading = false);
      return;
    }

    final Set<String> kIds = {
      'standard_monthly_subscription',
      'premium_monthly_subscription'
    };
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
    
    setState(() {
      _products = response.productDetails;
      _isLoading = false;
    });
  }

  void _handlePurchase(SubscriptionPlan plan) async {
    if (plan.productId == 'free_plan') {
      // 無料プランの処理
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscriptionPlan', plan.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無料プランが選択されました')),
      );
      setState(() {
        _selectedPlan = plan.productId; // 選択されたプランを更新
      });
    } else {
      final ProductDetails product = _products.firstWhere(
        (p) => p.id == plan.productId,
        orElse: () => throw StateError('商品が見つかりません'),
      );
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サブスクリプション')),
      body: Column(
        children: [
          const AdBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final isSelected = plan.productId == _selectedPlan;
                      Color backgroundColor;
                      switch (plan.name) {
                        case 'Free':
                          backgroundColor = Colors.white;
                          break;
                        case 'Standard':
                          backgroundColor = const Color.fromARGB(255, 30, 255, 236);
                          break;
                        case 'Premium':
                          backgroundColor = const Color.fromARGB(255, 255, 218, 109);
                          break;
                        default:
                          backgroundColor = Colors.white;
                      }
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
                                  Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '現在のプラン',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(plan.price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black)),
                              const SizedBox(height: 8),
                              Text(plan.features, style: const TextStyle(color: Colors.black)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: isSelected ? null : () => _handlePurchase(plan), // 選択されたプランの場合はボタンを無効に
                                child: const Text('選択'),
                              ),
                            ],
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