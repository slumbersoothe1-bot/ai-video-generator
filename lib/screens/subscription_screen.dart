import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payments unavailable')),
        body: const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Paid plans and credit purchases are not available in this preview.',
              textAlign: TextAlign.center),
        )),
      );
}
