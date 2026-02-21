import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header/account_button.dart';

/// Height used for header overlay (dashboard-style screens).
const double kHeaderOverlayHeight = 64.0;

/// Top padding for content when using header overlay (slightly less than full height).
const double kHeaderContentTopPadding = 60.0;

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kHeaderOverlayHeight);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/lakbike_logo4.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const AccountButton(),
          ],
        ),
      ),
    );
  }
}
