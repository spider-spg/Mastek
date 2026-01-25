import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../symptom_analyzer.dart';

// Simple model to hold messages
class ChatMessage {
  final String text;
  final bool isUser;
  final AnalysisResult? result;
  final DateTime createdAt;

  ChatMessage(
    this.text, {
    this.isUser = false,
    this.result,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SymptomModel extends ChangeNotifier {
  final List<ChatMessage> messages = <ChatMessage>[];
  String selectedLanguage = 'auto';

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('selectedLanguage') ?? 'auto';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = code;
    await prefs.setString('selectedLanguage', code);
    notifyListeners();
  }

  void addUserMessage(String text, {String? language}) {
    messages.add(ChatMessage(text, isUser: true));
    notifyListeners();
  }

  void addBotMessage(String text, {AnalysisResult? result}) {
    messages.add(ChatMessage(text, isUser: false, result: result));
    notifyListeners();
  }
}
