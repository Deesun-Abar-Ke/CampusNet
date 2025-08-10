import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  final List<Map<String, String>> sampleMessages = const [
    {
      'sender': 'Sadia',
      'message': 'Hey! Are you coming to the campus event tomorrow?',
      'time': '2m ago',
    },
    {
      'sender': 'Jahan',
      'message': 'Don’t forget the tuition class at 5 PM.',
      'time': '10m ago',
    },
    {
      'sender': 'Moon',
      'message': 'Can you share the notes for last week’s lecture?',
      'time': '1h ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleMessages.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final msg = sampleMessages[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(msg['sender']![0]),
            ),
            title: Text(msg['sender']!),
            subtitle: Text(msg['message']!),
            trailing: Text(
              msg['time']!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            onTap: () {
              // You can handle opening detailed chat here later
            },
          );
        },
      ),
    );
  }
}
