import 'package:flutter/material.dart';
import '../widgets/body_selector_3d.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_chips.dart';

class MainChatHologramScreen extends StatelessWidget {
  const MainChatHologramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String userDisplayName = 'Guest';
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClinixAI Assistant'),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (int value) {
              if (value == 1) {
                Navigator.pushNamed(context, '/profileList');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                enabled: false,
                child: Text(
                  userDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Open profile'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: BodySelector3D(
              onRegionSelected: (String region) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: $region')),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const <Widget>[
                ChatBubble(message: 'Hello! Describe your symptom.', isUser: false),
              ],
            ),
          ),
          const QuickChips(chips: <String>['Fever', 'Cough', 'Headache']),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
