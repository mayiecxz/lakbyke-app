import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/presentation/chatbot_theme.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/chatbot_content.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart' show kHeaderContentTopPadding;
import 'package:lakbyke_mobile/core/presentation/widgets/header_with_back.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ChatbotTheme.gradientStart,
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: const ChatbotContent(),
              ),
            ),
            const HeaderWithBack(title: 'Chatbot'),
          ],
        ),
      ),
    );
  }
}
