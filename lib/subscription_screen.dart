import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {

  @override
  void initState() {
    super.initState();
  }

  void presentPaywall() async {
    final paywallResult = await RevenueCatUI.presentPaywall();
    log('Paywall result: $paywallResult');
  }

  void presentPaywallIfNeeded() async {
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("rc_399_1m_3d0");
    log('Paywall result: $paywallResult');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
      ),
      body: SafeArea(
        child: Center(
          child: PaywallView(
            // offering:
            //     offering, // Optional Offering object obtained through getOfferings
            onRestoreCompleted: (CustomerInfo customerInfo) {
              // Optional listener. Called when a restore has been completed.
              // This may be called even if no entitlements have been granted.
            },
            onDismiss: () {
              // Dismiss the paywall, i.e. remove the view, navigate to another screen, etc.
              // Will be called when the close button is pressed (if enabled) or when a purchase succeeds.
            },
          ),
        ),
      ),
    );
  }
}
