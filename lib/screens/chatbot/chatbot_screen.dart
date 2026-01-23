import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lakbyke_mobile/models/chatbot/chatbot_model.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';
import 'package:lakbyke_mobile/services/chatbot_prompt_service.dart';
import 'package:lakbyke_mobile/services/dashboard.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:lakbyke_mobile/screens/template/header.dart';
import 'package:lakbyke_mobile/screens/template/screen_title.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ChatbotService _chatbotService = ChatbotService();
  final DashboardService _dashboardService = DashboardService();
  
  // Total generated and redeemed values
  double _totalGenerated = 0.0;
  double _totalRedeemed = 0.0;
  bool _isLoadingStats = true;

  // TODO: Replace with valid API Key
  static const apiKey = 'AIzaSyBGLVqi-ZmgooWRgJaa1UqverOqhrZ_sxc'; 
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini Model
    _model = GenerativeModel(model: 'gemma-3-27b-it', apiKey: apiKey);
    
    // Load chat history from Firebase
    _loadChatHistory();
    
    // Load total generated and redeemed stats
    _loadStats();
  }
  
  // Load total generated and redeemed from dashboard service
  Future<void> _loadStats() async {
    try {
      final dashboardData = await _dashboardService.getDashboardData();
      if (dashboardData != null) {
        setState(() {
          _totalGenerated = (dashboardData['totalGenerated'] as num?)?.toDouble() ?? 0.0;
          _totalRedeemed = (dashboardData['totalRedeems'] as num?)?.toDouble() ?? 0.0;
          _isLoadingStats = false;
        });
      } else {
        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // Clean text by removing emojis and extra whitespace
  String _cleanText(String text) {
    // Remove emojis (Unicode ranges for emojis)
    String cleaned = text.replaceAll(
      RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true),
      '',
    );
    
    // Replace multiple newlines with single space
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n+'), ' ');
    
    // Replace single newlines with space
    cleaned = cleaned.replaceAll(RegExp(r'\n+'), ' ');
    
    // Collapse multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Trim
    return cleaned.trim();
  }

  // Load chat history from Firebase
  Future<void> _loadChatHistory() async {
    final history = await _chatbotService.loadChatHistory();
    
    if (history.isEmpty) {
      // If no history, add welcome message
      _addMessage("Hello! I'm your LakByke assistant, si Kleta. Start pedaling and ask me anything about your energy stats!", false);
    } else {
      // Restore chat history
      setState(() {
        _messages.addAll(history);
      });
    }
  }

  void _addMessage(String text, bool isUser) {
    // Clean text for bot messages only (preserve user input as-is)
    final cleanedText = isUser ? text : _cleanText(text);
    
    final message = ChatMessage(
      text: cleanedText, 
      isUser: isUser, 
      time: DateTime.now()
    );
    
    setState(() {
      _messages.add(message);
    });
    
    // Auto-scroll to bottom when new message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Save message to Firebase (save cleaned text for bot messages)
    _chatbotService.saveMessage(cleanedText, isUser, message.time);
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    _controller.clear();
    _addMessage(userText, true);
    setState(() => _isLoading = true);

    try {
      // 1. Get current real-time data
      final bikeData = Provider.of<BikeData>(context, listen: false);

      // 2. Get context data (dashboard data) if available
      Map<String, dynamic>? contextData;
      try {
        contextData = await _dashboardService.getDashboardData();
      } catch (e) {
        // Continue without context data
      }

      // 3. Prepare conversation history (last 5 messages)
      final conversationHistory = _messages
          .map((msg) => {
                'role': msg.isUser ? 'User' : 'Si Kleta',
                'text': msg.text,
              })
          .toList();

      // 4. Build prompt using prompt service
      final prompt = ChatbotPromptService.buildPrompt(
        userQuery: userText,
        bikeData: bikeData,
        contextData: contextData,
        conversationHistory: conversationHistory,
      );

      // 5. Send to AI
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // 6. Display result (text cleaning is handled in _addMessage for bot messages)
      _addMessage(response.text ?? "I couldn't read the sensors right now.", false);

    } catch (e) {
      _addMessage("Error: Check your API Key or internet connection.", false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BikeData(),
      child: Scaffold(
        appBar: const Header(),
        body: Column(
          children: [
            const ScreenTitle(title: 'Chatbot'),
            
            // Dashboard Header (Real-time View)
            Consumer<BikeData>(
              builder: (context, bikeData, child) => Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF2FBFB),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat("Battery", "${bikeData.batteryLevel}%", Icons.battery_charging_full),
                  _buildStat(
                    "Total Generated", 
                    _isLoadingStats ? "..." : formatEnergy(_totalGenerated), 
                    Icons.bolt
                  ),
                    _buildStat(
                      "Total Redeemed", 
                      _isLoadingStats ? "..." : "₱${_totalRedeemed.toStringAsFixed(2)}", 
                      Icons.account_balance_wallet
                    ),
                  ],
                ),
              ),
            ),

            // Chat Area (Scrollable)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFF0F8A8A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                          bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('hh:mm a').format(msg.time),
                            style: TextStyle(
                              fontSize: 10,
                              color: msg.isUser ? Colors.white70 : Colors.black54,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Area (Fixed at bottom)
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF0F8A8A),
                backgroundColor: Color(0xFFE0F2F1),
              ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask about your energy status...",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFFF6F7F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: const Color(0xFF0F8A8A),
                    mini: true,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0F8A8A)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
