import 'package:flutter/material.dart';

class SymptomDetailsScreen extends StatelessWidget {
  const SymptomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          Text('Collect onset, severity, duration, and notes here.'),
        ],
      ),
    );
  }
}
