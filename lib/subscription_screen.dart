import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Offering? _offering;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      setState(() {
        _offering = offerings.current;
      });
    } catch (e) {
      print('オファリングの取得に失敗しました: $e');
    }
  }

  Future<void> _purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      // 購入成功時の処理
    } catch (e) {
      // エラー処理
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('サブスクリプション')),
      body: _offering == null
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _offering!.availablePackages.length,
              itemBuilder: (context, index) {
                Package package = _offering!.availablePackages[index];
                return ListTile(
                  title: Text(package.storeProduct.title),
                  subtitle: Text(package.storeProduct.description),
                  trailing: Text(package.storeProduct.priceString),
                  onTap: () => _purchasePackage(package),
                );
              },
            ),
    );
  }
}
