import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: 'Chatbot', showBackButton: true),
      body: const Center(
        child: Text("🤖 Chatbot Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
