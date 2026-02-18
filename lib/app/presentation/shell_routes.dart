import 'package:flutter/material.dart';

/// Route names for the shell Navigator.
abstract final class ShellRoutes {
  static const String dashboard = '/dashboard';
  static const String chatbot = '/chatbot';
  static const String account = '/account';
  static const String transactionDetail = '/transaction-detail';
  static const String kwhDetail = '/kwh-detail';
}

/// Builds a horizontal slide page route for in-shell navigation.
/// Matches the feel of the history screen (Energy / Transaction) and dashboard tab transitions.
PageRoute<T> buildShellPageRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: slide,
        child: child,
      );
    },
  );
}

/// Full-screen route that slides up from the bottom (e.g. Chatbot).
/// Replaces the current screen; bottom nav is not visible.
PageRoute<T> buildChatbotPageRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    fullscreenDialog: false,
    opaque: true,
    barrierColor: null,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: slide,
        child: child,
      );
    },
  );
}
