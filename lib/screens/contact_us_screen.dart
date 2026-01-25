import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import '../services/firebase_bootstrap.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  bool _sending = false;

  User? get _userOrNull => FirebaseBootstrap.isReady ? FirebaseAuth.instance.currentUser : null;

  static const String _supportEmail = 'support@medimitra.app';

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final prefs = await SharedPreferences.getInstance();

    final user = _userOrNull;
    final cachedName = (prefs.getString('profile.fullName') ?? '').trim();

    if (!mounted) return;
    setState(() {
      _name.text = cachedName;
      _email.text = (user?.email ?? '').trim();
      _phone.text = (user?.phoneNumber ?? '').trim();
      _subject.text = 'App Support';
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _validateRequired(String? v) {
    final l10n = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return l10n.required;
    return null;
  }

  String? _validateEmail(String? v) {
    final l10n = AppLocalizations.of(context);
    final value = (v ?? '').trim();
    if (value.isEmpty) return l10n.required;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (!ok) return l10n.enterValidEmail;
    return null;
  }

  Future<void> _submit() async {
    if (_sending) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _sending = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'subject': _subject.text.trim(),
      'message': _message.text.trim(),
      'source': 'contact_us',
      'status': 'new',
      'reviewed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': DateTime.now().toIso8601String(),
      'platform': Theme.of(context).platform.toString(),
      'uiLocale': Localizations.localeOf(context).toLanguageTag(),
    };

    final user = _userOrNull;
    if (user != null) {
      payload['uid'] = user.uid;
    }

    try {
      if (FirebaseBootstrap.isReady) {
        final info = await PackageInfo.fromPlatform();
        payload['appVersion'] = info.version;
        payload['buildNumber'] = info.buildNumber;
        payload['packageName'] = info.packageName;

        await FirebaseFirestore.instance.collection('supportRequests').add(payload);
        if (!mounted) return;
        setState(() => _sending = false);
        _snack(AppLocalizations.of(context).sentSuccess);
        Navigator.of(context).maybePop();
        return;
      }
    } catch (_) {
      // If Firestore isn’t available, fall back to mailto.
    }

    // Fallback: open email client.
    final subject = Uri.encodeComponent(_subject.text.trim());
    final body = Uri.encodeComponent(
      'Name: ${_name.text.trim()}\n'
      'Email: ${_email.text.trim()}\n'
      'Phone: ${_phone.text.trim()}\n\n'
      '${_message.text.trim()}\n',
    );

    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _sending = false);
      if (!launched) {
        _snack(AppLocalizations.of(context).couldNotOpenEmailApp);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack(AppLocalizations.of(context).couldNotSendTryLater);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.contactUs),
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(
                  isDark: isDark,
                  title: l10n.needHelp,
                  subtitle: l10n.contactSubtitle,
                  lines: [
                    l10n.supportEmailLine(_supportEmail),
                    l10n.typicalResponseLine,
                  ],
                ),
                const SizedBox(height: 16),

                _Field(
                  controller: _name,
                  label: l10n.fullName,
                  hint: l10n.yourName,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _email,
                  label: l10n.email,
                  hint: l10n.emailHint,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _phone,
                  label: l10n.phoneOptional,
                  hint: l10n.yourMobileNumber,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _subject,
                  label: l10n.subject,
                  hint: l10n.subjectHint,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _message,
                  label: l10n.message,
                  hint: l10n.messageHint,
                  validator: (v) {
                    final e = _validateRequired(v);
                    if (e != null) return e;
                    if ((v ?? '').trim().length < 10) return l10n.writeMoreDetail;
                    return null;
                  },
                  minLines: 4,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.send),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.tipNoShareOtp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.lines,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final card = Theme.of(context).cardColor;
    final border = isDark ? const Color(0xFF223042) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines ?? 1,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: isDark ? const Color(0xFF151A22) : Theme.of(context).cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
