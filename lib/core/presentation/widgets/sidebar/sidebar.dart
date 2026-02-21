import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/sidebar/sidebar_body.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => const SidebarBody(),
      barrierDismissible: true,
      barrierLabel: 'Sidebar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOut.transform(animation.value);
        return Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: MediaQuery.of(context).orientation == Orientation.portrait ? 0.6 : 0.3,
                child: Transform.translate(
                  offset: Offset(-30 * (1 - curved), 0),
                  child: Opacity(
                    opacity: curved,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
