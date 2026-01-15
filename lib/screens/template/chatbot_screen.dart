import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lakbyke_mobile/models/chatbot_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BikeData(),
      child: const MaterialApp(home: LakBykeChatScreen()),
    ),
  );
}

class LakBykeChatScreen extends StatefulWidget {
  const LakBykeChatScreen({super.key});

  @override
  State<LakBykeChatScreen> createState() => _LakBykeChatScreenState();
}

class _LakBykeChatScreenState extends State<LakBykeChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // TODO: Replace with valid API Key
  static const apiKey = 'AIzaSyAGH10LVPyyz7SLzthWzkpmLBqLA1nn910'; 
  late final GenerativeModel _model;

  // This is the "Persona" of the bot based on your Abstract
  final String _systemContext = """
  You are the intelligent assistant for 'LakByke', an IoT-integrated pedal energy system.
  
  SYSTEM INFO:
  - You convert human pedaling via a PMDC motor into electricity.
  - You store power in a LiFePO4 battery.
  - You can charge small devices like smartphones.
  - You want to promote sustainable mobility.
  
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
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    
    // Add a welcome message
    _addMessage("Hello! I'm your LakByke assistant, si Kleta 🥰. Start pedaling and ask me anything about your energy stats!", false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text, 
        isUser: isUser, 
        time: DateTime.now()
      ));
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("LakByke Smart Assistant"),
        backgroundColor: Colors.teal,
        actions: [
          // A little simulator button to change data for testing
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bikeData.simulateDataChange(),
            tooltip: "Simulate Pedaling",
          )
        ],
      ),
      body: Column(
        children: [
          // --- Dashboard Header (Real-time View) ---
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
          
          // --- Chat Area ---
          Expanded(
            child: ListView.builder(
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
                            color: msg.isUser ? Colors.white70 : Colors.black54
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- Input Area ---
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about your energy status...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.send),
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
}