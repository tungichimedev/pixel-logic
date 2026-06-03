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

  // Initialize RevenueCat
  try {
    await PurchaseService.instance.initialize();
  } catch (e) {
    debugPrint('RevenueCat init failed: $e');
  }

  // Load persisted consent (no dialogs — just read previous state)
  await ConsentService.instance.loadPersistedConsent();

  // Only initialize ads if consent was previously obtained.
  // First-time users get ads initialized after tutorial completes
  // (triggered from main_shell.dart).
  if (ConsentService.instance.consentRequested) {
    try {
      await AdService.instance.initialize(
        consentGiven: ConsentService.instance.consentGiven,
      );
    } catch (e) {
      debugPrint('Ad init failed: $e');
    }
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
