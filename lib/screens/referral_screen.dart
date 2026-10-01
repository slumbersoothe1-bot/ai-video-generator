import 'package:flutter/material.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Referrals unavailable')),
        body: const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Referral links and rewards are not available in this preview.',
              textAlign: TextAlign.center),
        )),
      );
}
