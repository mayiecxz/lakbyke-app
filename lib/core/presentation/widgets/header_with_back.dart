import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart';

/// Header bar with back button for sub-screens (e.g. Account Settings).
/// Use as overlay in the same dashboard container layout.
class HeaderWithBack extends StatelessWidget {
  final String? title;

  const HeaderWithBack({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHeaderOverlayHeight,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
            ),
            Expanded(
              child: title != null && title!.isNotEmpty
                  ? Center(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : Center(
                      child: Image.asset(
                        'assets/images/lakbike_logo4.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
