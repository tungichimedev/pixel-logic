import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/consent_service.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'utils/app_router.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize monetization (non-blocking on failure)
  bool consentGiven = false;
  try {
    await PurchaseService.instance.initialize();
  } catch (e) {
    debugPrint('RevenueCat init failed: $e');
  }

  try {
    consentGiven = await ConsentService.instance.requestConsent()
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
  } catch (e) {
    debugPrint('Consent flow failed: $e');
  }

  try {
    await AdService.instance.initialize(consentGiven: consentGiven);
  } catch (e) {
    debugPrint('Ad init failed: $e');
  }

  runApp(const ProviderScope(child: PixelLogicApp()));
}

class PixelLogicApp extends StatelessWidget {
  const PixelLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pixel Logic',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      routerConfig: appRouter,
    );
  }
}
