import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the nested Navigator key for [AuthenticatedShell].
/// Set by the shell when it builds; read by widgets that push/pop in-shell routes.
class ShellNavigatorKeyNotifier extends Notifier<GlobalKey<NavigatorState>?> {
  @override
  GlobalKey<NavigatorState>? build() => null;

  void attachKey(GlobalKey<NavigatorState> key) {
    state = key;
  }
}

final shellNavigatorKeyProvider =
    NotifierProvider<ShellNavigatorKeyNotifier, GlobalKey<NavigatorState>?>(
  ShellNavigatorKeyNotifier.new,
);

/// Current top route name of the shell Navigator. Used to hide bottom nav/FAB when
/// a full-screen route (e.g. Chatbot) is shown.
class ShellRouteNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCurrentRouteName(String? name) {
    state = name;
  }
}

final shellRouteNameProvider =
    NotifierProvider<ShellRouteNameNotifier, String?>(
  ShellRouteNameNotifier.new,
);

/// NavigatorObserver that updates [shellRouteNameProvider] when routes push/pop.
class ShellRouteObserver extends NavigatorObserver {
  ShellRouteObserver(this._onRouteUpdate);

  final void Function(String? routeName) _onRouteUpdate;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteUpdate(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteUpdate(previousRoute?.settings.name);
  }
}
