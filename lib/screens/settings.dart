import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const <Widget>[
          ListTile(title: Text('Language & region')),
          ListTile(title: Text('Privacy & consent')),
          ListTile(title: Text('About ClinixAI')),
        ],
      ),
    );
  }
}
