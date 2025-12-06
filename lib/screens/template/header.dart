import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/screens/template/menu_button.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Container(
        color: Colors.black,
        child: Row(
          children: [
            const MenuButton(),
            const Expanded(child: SizedBox()),
            // placeholder for optional actions on right
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}
