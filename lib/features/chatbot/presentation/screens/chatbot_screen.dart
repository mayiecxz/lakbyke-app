import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lakbyke_mobile/config/chatbot_config.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/models/chatbot_model.dart';
import 'package:lakbyke_mobile/features/chatbot/providers/chatbot_providers.dart';
import 'package:lakbyke_mobile/features/chatbot/data/services/chatbot_prompt_service.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/header.dart' show Header, kHeaderContentTopPadding;
import 'package:intl/intl.dart';

// Chat UI constants (modern, responsive)
const _userBubbleColor = Color(0xFF0F8A8A);
const _botBubbleColor = Color(0xFFE8F5F5);
const _gradientStart = Color(0xFFE0F7FA);
const _gradientEnd = Color(0xFFB2DFDB);
const _inputBg = Color(0xFFF5F5F5);
const _bubbleRadius = 18.0;
const _avatarSize = 32.0;

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    if (ChatbotConfig.isConfigured) {
      _model = GenerativeModel(
        model: ChatbotConfig.modelName,
        apiKey: ChatbotConfig.geminiApiKey,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  String _cleanText(String text) {
    String cleaned = text.replaceAll(
      RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  Future<void> _loadChatHistory() async {
    final repo = ref.read(chatbotRepositoryProvider);
    final history = await repo.loadChatHistory();
    if (history.isEmpty) {
      _addMessage("Hi! I'm your LakByke support assistant. Ask about the app—Home, Maps, QR, History, Insights, or Account.", false);
    } else {
      setState(() => _messages.addAll(history));
    }
  }

  void _addMessage(String text, bool isUser) {
    final cleanedText = isUser ? text : _cleanText(text);
    final message = ChatMessage(text: cleanedText, isUser: isUser, time: DateTime.now());
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
    ref.read(chatbotRepositoryProvider).saveMessage(cleanedText, isUser, message.time);
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;
    if (!ChatbotConfig.isConfigured || _model == null) {
      _addMessage("Chat is not configured. Add your key to config/secrets.json and run: dart run tool/sync_secrets.dart", false);
      return;
    }

    _controller.clear();
    _addMessage(userText, true);
    setState(() => _isLoading = true);

    try {
      final conversationHistory = _messages
          .map((msg) => {'role': msg.isUser ? 'User' : 'Si Kleta', 'text': msg.text})
          .toList();
      final prompt = ChatbotPromptService.buildPrompt(
        userQuery: userText,
        conversationHistory: conversationHistory,
      );
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim();
      if (responseText != null && responseText.isNotEmpty) {
        _addMessage(responseText, false);
      } else {
        _addMessage("Couldn't generate a reply. Try rephrasing or check your connection.", false);
      }
    } catch (e) {
      final msg = e.toString();
      final isApiError = msg.contains('404') || msg.contains('API key') || msg.contains('invalid') || msg.contains('model');
      _addMessage(
        isApiError ? "Chat error: Check API key and model availability." : "Error: Check your connection and try again.",
        false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _dateLabel(int index) {
    if (index == 0) return DateFormat('EEEE | MMM d, y').format(_messages[index].time);
    final prev = _messages[index - 1].time;
    final curr = _messages[index].time;
    if (prev.year != curr.year || prev.month != curr.month || prev.day != curr.day) {
      return DateFormat('EEEE | MMM d, y').format(curr);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ChatbotConfig.isConfigured;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _gradientStart,
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: Colors.black),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: kHeaderContentTopPadding),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_gradientStart, _gradientEnd],
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final dateLabel = _dateLabel(index);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (dateLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        dateLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                _ChatBubble(
                                  text: msg.text,
                                  isUser: msg.isUser,
                                  time: msg.time,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: _userBubbleColor,
                          backgroundColor: Color(0xFFE0F2F1),
                        ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: "Ask about LakByke or get help...",
                                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                                  filled: true,
                                  fillColor: _inputBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Material(
                                color: hasKey ? _userBubbleColor : Colors.grey,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    _sendMessage();
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: const Center(
                                    child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Header(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatBubble({required this.text, required this.isUser, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? _userBubbleColor : _botBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(_bubbleRadius),
                  topRight: const Radius.circular(_bubbleRadius),
                  bottomLeft: Radius.circular(isUser ? _bubbleRadius : 6),
                  bottomRight: Radius.circular(isUser ? 6 : _bubbleRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: _avatarSize / 2,
      backgroundColor: isUser ? _userBubbleColor.withValues(alpha: 0.9) : _botBubbleColor,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy_rounded,
        size: 18,
        color: isUser ? Colors.white : _userBubbleColor,
      ),
    );
  }
}
