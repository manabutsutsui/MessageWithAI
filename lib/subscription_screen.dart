import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'ad_banner.dart';

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

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      name: 'Free',
      price: '無料',
      features: '・画像生成10回/月\n・チャットのやり取り50回/月\n・広告の表示',
      productId: 'free_plan',
    ),
    SubscriptionPlan(
      name: 'Standard',
      price: '500円/月',
      features: '・画像生成20回/月\n・チャットのやり取り200回/月\n・広告の非表示',
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
    _initializeStore();
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

  void _handlePurchase(SubscriptionPlan plan) {
    if (plan.productId == 'free_plan') {
      // 無料プランの処理
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無料プランが選択されました')),
      );
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
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(plan.price, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(plan.features),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                child: const Text('選択'),
                                onPressed: () => _handlePurchase(plan),
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