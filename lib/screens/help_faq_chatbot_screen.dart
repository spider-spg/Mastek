import 'dart:async';

import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

enum _Sender { user, bot }

class HelpFaqChatbotScreen extends StatefulWidget {
  const HelpFaqChatbotScreen({super.key});

  @override
  State<HelpFaqChatbotScreen> createState() => _HelpFaqChatbotScreenState();
}

class _HelpFaqChatbotScreenState extends State<HelpFaqChatbotScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _sending = false;

  bool _seededGreeting = false;

  final List<_ChatMessage> _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededGreeting) return;
    _seededGreeting = true;

    final l10n = AppLocalizations.of(context);
    _messages.add(_ChatMessage(sender: _Sender.bot, text: l10n.helpFaqBotGreeting));
  }

  List<String> _suggestions(AppLocalizations l10n) {
    return <String>[
      l10n.helpFaqSuggestionCheckSymptoms,
      l10n.helpFaqSuggestionVoiceSymptoms,
      l10n.helpFaqSuggestionOutbreakAlert,
      l10n.helpFaqSuggestionNearbyClinics,
      l10n.helpFaqSuggestionOtpLogin,
      l10n.helpFaqSuggestionDataSafe,
      l10n.helpFaqSuggestionGuestMode,
      l10n.helpFaqSuggestionChangeLanguage,
      l10n.helpFaqSuggestionDarkMode,
    ];
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(sender: _Sender.user, text: trimmed));
    });

    _input.clear();
    _scrollToBottom();

    // Simulate thinking.
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final reply = _replyFor(trimmed);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(sender: _Sender.bot, text: reply));
      _sending = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _replyFor(String question) {
    final q = _normalize(question);
    final l10n = AppLocalizations.of(context);

    // Symptom checking
    if (_hasAny(q, ['symptom', 'check symptoms', 'symptoms', 'diagnose', 'analysis'])) {
      return l10n.helpFaqReplySymptomChecking;
    }

    // Voice
    if (_hasAny(q, ['voice', 'mic', 'speech', 'speak'])) {
      return l10n.helpFaqReplyVoiceSymptoms;
    }

    // Outbreak
    if (_hasAny(q, ['outbreak', 'alert', 'region', 'analytics', 'trend'])) {
      return l10n.helpFaqReplyOutbreakAlert;
    }

    // Clinics
    if (_hasAny(q, ['clinic', 'doctor', 'hospital', 'nearby', 'locator', 'map'])) {
      return l10n.helpFaqReplyNearbyClinics;
    }

    // OTP/Login
    if (_hasAny(q, ['otp', 'login', 'sign in', 'verification', 'phone number', 'mobile'])) {
      return l10n.helpFaqReplyOtpLogin;
    }

    // Guest
    if (_hasAny(q, ['guest', 'without login', 'skip login', 'no login'])) {
      return l10n.helpFaqReplyGuestMode;
    }

    // Privacy
    if (_hasAny(q, ['privacy', 'safe', 'data', 'secure', 'firebase', 'store'])) {
      return l10n.helpFaqReplyPrivacy;
    }

    // Language
    if (_hasAny(q, ['language', 'hindi', 'marathi', 'english', 'translate'])) {
      return l10n.helpFaqReplyChangeLanguage;
    }

    // Dark mode
    if (_hasAny(q, ['dark', 'dark mode', 'theme', 'night'])) {
      return l10n.helpFaqReplyDarkMode;
    }

    // Contact
    if (_hasAny(q, ['contact', 'support', 'helpdesk', 'call'])) {
      return l10n.helpFaqReplyContactSupport;
    }

    return l10n.helpFaqReplyFallback;
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _hasAny(String normalizedQuestion, List<String> keywords) {
    for (final k in keywords) {
      if (normalizedQuestion.contains(_normalize(k))) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.helpAndFaq),
        centerTitle: false,
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return _Bubble(message: m);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.quickQuestions,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 118),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions(l10n))
                    ActionChip(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        s,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      onPressed: () => _send(s),
                      backgroundColor: isDark ? const Color(0xFF1A2230) : Colors.white,
                      side: BorderSide(color: isDark ? const Color(0xFF223042) : const Color(0xFFE2E8F0)),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sending ? null : _send,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.typeAQuestionHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF151A22) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _sending ? null : () => _send(_input.text),
                    icon: Icon(
                      Icons.send_rounded,
                      color: _sending
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.sender, required this.text});

  final _Sender sender;
  final String text;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == _Sender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : (isDark ? const Color(0xFF1A2230) : Colors.white);

    final fg = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 560),
      margin: EdgeInsets.only(top: 10, left: isUser ? 48 : 0, right: isUser ? 0 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        border: isUser
            ? null
            : Border.all(color: isDark ? const Color(0xFF223042) : const Color(0xFFE2E8F0)),
        boxShadow: isUser
            ? const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6))]
            : null,
      ),
      child: Text(
        message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: fg,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}
