import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/sidebar_panel.dart';

/// Full-screen dialog content for the sidebar (wraps [SidebarPanel]).
class SidebarBody extends ConsumerWidget {
  const SidebarBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SidebarPanel();
  }
}
