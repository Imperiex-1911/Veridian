// lib/screens/chat_screen.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Data Model for a single chat message ---
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// --- Service to handle API calls ---
class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = 'https://veridian-api-1jzx.onrender.com';

  Future<String> sendMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      body: jsonEncode({'user_id': user.uid, 'message': message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reply'];
    } else {
      throw Exception('Failed to get response from AI advisor: ${response.body}');
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add an initial greeting message from the AI
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI Energy Advisor. Ask me anything about your audit results or how to save energy.",
      isUser: false,
    ));
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text;
    if (messageText.trim().isEmpty) return;

    // Add user's message to the UI
    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      // Get response from the AI
      final aiResponse = await _chatService.sendMessage(messageText);
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Sorry, I couldn't get a response. Please try again. Error: $e", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Advisor is typing..."),
              ),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration.collapsed(hintText: 'Ask about your energy usage...'),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}