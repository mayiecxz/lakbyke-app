import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/shared/widgets/sidebar.dart';

class MenuButton extends StatelessWidget {
  final double size;
  final EdgeInsets padding;
  final VoidCallback? onPressed;

  const MenuButton({
    super.key,
    this.size = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu, color: Colors.white, size: size),
      onPressed: onPressed ?? () => Sidebar.show(context),
      padding: padding,
      constraints: const BoxConstraints(),
    );
  }
}
