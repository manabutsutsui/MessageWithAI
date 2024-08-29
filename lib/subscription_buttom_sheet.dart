import 'package:flutter/material.dart';

class SubscriptionBottomSheet extends StatelessWidget {
  const SubscriptionBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 36),
              const Text(
                'StyleShift Premium',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Pacifico'),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '\u005C Try it free for 3 days!/',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // ここにプレミアムプランの購入ロジックを追加
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 18),),
                    SizedBox(width: 18),
                    Text(
                      'Premium Plan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• Ad-free experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '• Unlimited access to all features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
