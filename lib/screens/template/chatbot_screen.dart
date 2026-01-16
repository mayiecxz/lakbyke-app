import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lakbyke_mobile/models/chatbot_model.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';
import 'package:lakbyke_mobile/services/chatbot_prompt_service.dart';
import 'package:lakbyke_mobile/services/dashboard.dart';
import 'package:lakbyke_mobile/utils/formatting.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Chatbot bottom sheet that opens as a modal dialog.
/// Follows Material Design guidelines for bottom sheets.
class ChatbotBottomSheet extends StatefulWidget {
  const ChatbotBottomSheet({super.key});

  /// Shows the chatbot bottom sheet as a modal dialog.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChangeNotifierProvider(
        create: (_) => BikeData(),
        child: const ChatbotBottomSheet(),
      ),
    );
  }

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet> {
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
    // Updated: gemini-pro is deprecated, using gemini-2.5-flash (current stable model)
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
      print('Error loading stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  // Load chat history from Firebase
  Future<void> _loadChatHistory() async {
    final history = await _chatbotService.loadChatHistory();
    
    if (history.isEmpty) {
      // If no history, add welcome message
      _addMessage("Hello! I'm your LakByke assistant, si Kleta 🥰. Start pedaling and ask me anything about your energy stats!", false);
    } else {
      // Restore chat history
      setState(() {
        _messages.addAll(history);
      });
    }
  }

  void _addMessage(String text, bool isUser) {
    final message = ChatMessage(
      text: text, 
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
    
    // Save message to Firebase
    _chatbotService.saveMessage(text, isUser, message.time);
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
        print('Error fetching context data: $e');
        // Continue without context data
      }

      // 3. Build prompt using simple prompt service
      final prompt = ChatbotPromptService.buildPrompt(
        userQuery: userText,
        bikeData: bikeData,
        contextData: contextData,
      );

      // 4. Send to AI
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // 5. Display result
      _addMessage(response.text ?? "I couldn't read the sensors right now.", false);

    } catch (e) {
      print('Error in chatbot: $e');
      _addMessage("Error: Check your API Key or internet connection.", false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeData = Provider.of<BikeData>(context); // Listen to changes
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.85;

    return Container(
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with title and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "LakByke Smart Assistant",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: "Close",
                ),
              ],
            ),
          ),

          // Dashboard Header (Real-time View)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
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
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.teal : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
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
          if (_isLoading) const LinearProgressIndicator(),
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
                    decoration: const InputDecoration(
                      hintText: "Ask about your energy status...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.teal,
                  mini: true,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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