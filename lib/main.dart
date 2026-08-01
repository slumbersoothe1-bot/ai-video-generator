import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'screens/auth_gate.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/billing_service.dart';
import 'services/credits_service.dart';
import 'services/referral_service.dart';
import 'services/token_store.dart';
import 'services/video_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AiVideoStudioApp());
}

class AiVideoStudioApp extends StatelessWidget {
  const AiVideoStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient.instance();
    final tokenStore = TokenStore(const FlutterSecureStorage());
    final authService = AuthService(api: api, tokenStore: tokenStore);
    final videoService = VideoService(api);
    final creditsService = CreditsService(api);
    final referralService = ReferralService(api);
    final billingService = BillingService(api);

    api.setTokenProvider(() => authService.token);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<VideoService>.value(value: videoService),
        ChangeNotifierProvider<CreditsService>.value(value: creditsService),
        ChangeNotifierProvider<ReferralService>.value(value: referralService),
        ChangeNotifierProvider<BillingService>.value(value: billingService),
      ],
      child: FutureBuilder<void>(
        future: authService.init(),
        builder: (context, _) {
          return MaterialApp(
            title: 'AI Video Studio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
