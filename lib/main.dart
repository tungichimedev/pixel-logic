import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/app_router.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
