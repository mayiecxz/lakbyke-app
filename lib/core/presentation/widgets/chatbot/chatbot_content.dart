import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:lakbyke_mobile/config/chatbot_config.dart';
import 'package:lakbyke_mobile/core/presentation/chatbot_theme.dart';
import 'package:lakbyke_mobile/core/presentation/widgets/chatbot/sheet_chat_bubble.dart';
import 'package:lakbyke_mobile/features/chatbot/data/services/chatbot_prompt_service.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/context_builder/chatbot_context_builder.dart';
import 'package:lakbyke_mobile/features/chatbot/domain/models/chatbot_model.dart';
import 'package:lakbyke_mobile/features/chatbot/providers/chatbot_providers.dart';
import 'package:lakbyke_mobile/features/home/providers/home_providers.dart';
import 'package:lakbyke_mobile/features/insights/providers/insights_providers.dart';

/// Shared chat UI and logic for [ChatbotScreen] and [ChatbotBottomSheet].
/// Renders message list, loading indicator, and input bar; owns model and repository usage.
class ChatbotContent extends ConsumerStatefulWidget {
  const ChatbotContent({super.key});

  @override
  ConsumerState<ChatbotContent> createState() => _ChatbotContentState();
}

class _ChatbotContentState extends ConsumerState<ChatbotContent> {
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

  /// First line of the error message, trimmed and length-capped for display in chat.
  static String _shortError(String fullError) {
    final firstLine = fullError.split(RegExp(r'\n')).first.trim();
    if (firstLine.length <= 200) return firstLine;
    return '${firstLine.substring(0, 197)}...';
  }

  static String _cleanText(String text) {
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
    if (!mounted) return;
    if (history.isEmpty) {
      _addMessage("Ako nga pala si Kleta! I'm your LakByke support assistant. Ask about the app—Home, Maps, QR, History, Insights, or Account.", false);
    } else {
      setState(() => _messages.addAll(history));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _addMessage(String text, bool isUser) {
    if (!mounted) return;
    final cleanedText = isUser ? text : _cleanText(text);
    final message = ChatMessage(text: cleanedText, isUser: isUser, time: DateTime.now());
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    if (userText.isEmpty || !mounted) return;
    if (!ChatbotConfig.isConfigured || _model == null) {
      _addMessage("Chat is not configured. Add your key to config/secrets.json and run: dart run tool/sync_secrets.dart", false);
      return;
    }

    _controller.clear();
    _addMessage(userText, true);
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final homeData = ref.read(homeDataStreamProvider).value;
      final insightsModel = ref.read(insightsDataProvider).valueOrNull;
      final userStatsContext = ChatbotContextBuilder.buildFullUserContext(
        homeData: homeData,
        insightsModel: insightsModel,
      );
      final conversationHistory = _messages
          .map((msg) => {'role': msg.isUser ? 'User' : 'Si Kleta', 'text': msg.text})
          .toList();
      final prompt = ChatbotPromptService.buildPrompt(
        userQuery: userText,
        conversationHistory: conversationHistory,
        userStatsContext: userStatsContext.isEmpty ? null : userStatsContext,
      );
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      if (!mounted) return;
      final responseText = response.text?.trim();
      if (responseText != null && responseText.isNotEmpty) {
        _addMessage(responseText, false);
      } else {
        _addMessage("Couldn't generate a reply. Try rephrasing or check your connection.", false);
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('ChatbotContent._sendMessage error: $e');
      debugPrint(st.toString());
      final msg = e.toString();
      // Show the actual API error in chat so user sees "leaked", "not found", etc.
      final String displayError = _shortError(msg);
      final isApiError = msg.contains('404') || msg.contains('API key') || msg.contains('invalid') || msg.contains('model') || msg.contains('leaked');
      _addMessage(
        isApiError ? 'Chat error: $displayError' : 'Error: ${displayError.isEmpty ? "Check your connection and try again." : displayError}',
        false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ChatbotTheme.gradientStart, ChatbotTheme.gradientEnd],
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
                    SheetChatBubble(text: msg.text, isUser: msg.isUser, time: msg.time),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: ChatbotTheme.userBubbleColor,
              backgroundColor: ChatbotTheme.progressBarBg,
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
                      fillColor: ChatbotTheme.inputBg,
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
                    color: hasKey ? ChatbotTheme.userBubbleColor : Colors.grey,
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
