import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../screens/pack_select_screen.dart';
import '../screens/game_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/pack/:packId',
      builder: (context, state) => PackSelectScreen(
        packId: state.pathParameters['packId']!,
      ),
    ),
    GoRoute(
      path: '/play/:puzzleId',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: GameScreen(puzzleId: state.pathParameters['puzzleId']!),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
  ],
);
