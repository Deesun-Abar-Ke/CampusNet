import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: const Text('Messages'), showBackButton: true),
      body: const Center(
        child: Text("💬 Messages Page", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
