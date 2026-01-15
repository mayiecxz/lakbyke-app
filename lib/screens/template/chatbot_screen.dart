import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lakbyke_mobile/models/chatbot_model.dart';
import 'package:lakbyke_mobile/services/chatbot_service.dart';
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

  // TODO: Replace with valid API Key
  static const apiKey = 'AIzaSyBGLVqi-ZmgooWRgJaa1UqverOqhrZ_sxc'; 
  late final GenerativeModel _model;

  // This is the "Persona" of the bot based on your Abstract
  final String _systemContext = """
  You are the intelligent assistant for 'LakByke', an IoT-integrated pedal energy system.
  
  SYSTEM INFO:
  - You are Kleta and is referred to as "si Kleta".
  - The system you're part of converts human pedaling via a PMDC motor into electricity.
  - The system stores power in a LiFePO4 battery.
  - The system can charge small devices like smartphones.
  - You want to promote sustainable mobility.
  - You randomly present sustainability facts (ex. "Did you know?..", "Interesting fact:..", "Did you know that..")
  
  YOUR GOAL:
  - Interpret the provided sensor data for the cyclist.
  - Be encouraging, eco-friendly, and helpful.
  - If battery is low, encourage pedaling.
  - Keep answers concise and friendly.
  """;

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini Model
    // Updated: gemini-pro is deprecated, using gemini-2.5-flash (current stable model)
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    
    // Load chat history from Firebase
    _loadChatHistory();
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

      // 2. Construct the prompt with LIVE data
      final prompt = """
      $_systemContext

      CURRENT LIVE SENSOR DATA:
      - Voltage: ${bikeData.voltage.toStringAsFixed(1)} V
      - Current: ${bikeData.current.toStringAsFixed(1)} A
      - Power Output: ${bikeData.power.toStringAsFixed(1)} W
      - Battery Level: ${bikeData.batteryLevel}%
      - Is Pedaling: ${bikeData.isPedaling}

      USER QUESTION: "$userText"
      """;

      // 3. Send to AI
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      // 4. Display result
      _addMessage(response.text ?? "I couldn't read the sensors right now.", false);

    } catch (e) {
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
                _buildStat("Power", "${bikeData.power.toStringAsFixed(1)} W", Icons.bolt),
                _buildStat("Voltage", "${bikeData.voltage.toStringAsFixed(1)} V", Icons.electrical_services),
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