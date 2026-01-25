import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import '../services/firebase_bootstrap.dart';

class TermsSigningScreen extends StatefulWidget {
  const TermsSigningScreen({
    super.key,
    required this.onAccepted,
    this.showBack = true,
  });

  final VoidCallback onAccepted;
  final bool showBack;

  @override
  State<TermsSigningScreen> createState() => _TermsSigningScreenState();
}

class _TermsSigningScreenState extends State<TermsSigningScreen> {
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _busy = false;

  Color get _primary => const Color(0xFF1E88E5);
  Color get _bgLight => const Color(0xFFF0F7FF);
  Color get _bgDark => const Color(0xFF0F172A);
  Color get _secondary => const Color(0xFF10B981);

  Future<void> _persistAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('legal.lastAcceptedAt', now.millisecondsSinceEpoch);

    if (!FirebaseBootstrap.isReady) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final info = await PackageInfo.fromPlatform();
    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform.name; // e.g. android/ios/windows

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final acceptanceRef = userRef.collection('legal_acceptances').doc();

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      userRef,
      {
        'legal': {
          'termsAccepted': true,
          'privacyAccepted': true,
          'termsAcceptedAt': FieldValue.serverTimestamp(),
          'privacyAcceptedAt': FieldValue.serverTimestamp(),
          'acceptedAt': FieldValue.serverTimestamp(),
          'acceptedOn': now.toIso8601String(),
          'appVersion': info.version,
          'buildNumber': info.buildNumber,
          'platform': platform,
        },
      },
      SetOptions(merge: true),
    );

    batch.set(
      acceptanceRef,
      {
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedOn': now.toIso8601String(),
        'termsAccepted': true,
        'privacyAccepted': true,
        'appVersion': info.version,
        'buildNumber': info.buildNumber,
        'packageName': info.packageName,
        'platform': platform,
      },
    );

    await batch.commit();
  }

  Future<void> _onNext() async {
    if (_busy) return;
    if (!_acceptTerms || !_acceptPrivacy) return;

    setState(() => _busy = true);
    try {
      await _persistAcceptance();
      if (!mounted) return;
      widget.onAccepted();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).couldNotSaveConsent)),
      );
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _onBack() async {
    if (!widget.showBack) return;

    try {
      if (FirebaseBootstrap.isReady) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? _bgDark : _bgLight;
    final card = isDark ? const Color(0xFF1F2937) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    final muted = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    final canNext = _acceptTerms && _acceptPrivacy && !_busy;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _DocIllustration(
                      isDark: isDark,
                      primary: _primary,
                      secondary: _secondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.termsSigningTitle,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.termsSigningIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.45),
                  ),
                  const SizedBox(height: 16),

                  _Bullet(
                    primary: _primary,
                    isDark: isDark,
                    bold: l10n.termsBulletNotDiagnosisTitle,
                    normal: l10n.termsBulletNotDiagnosisBody,
                  ),
                  const SizedBox(height: 14),
                  _Bullet(
                    primary: _primary,
                    isDark: isDark,
                    bold: l10n.termsBulletNoEmergencyTitle,
                    normal: l10n.termsBulletNoEmergencyBody,
                  ),
                  const SizedBox(height: 14),
                  _Bullet(
                    primary: _primary,
                    isDark: isDark,
                    bold: l10n.termsBulletDataSafeTitle,
                    normal: l10n.termsBulletDataSafeBody,
                  ),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _ConsentRow(
                          value: _acceptTerms,
                          primary: _primary,
                          onChanged: (v) => setState(() => _acceptTerms = v),
                          child: Wrap(
                            children: [
                              Text(
                                l10n.termsConsentTermsPrefix,
                                style: TextStyle(fontSize: 14, height: 1.35, color: muted, fontWeight: FontWeight.w600),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/terms'),
                                child: Text(
                                  l10n.termsConsentTermsLink,
                                  style: TextStyle(fontSize: 14, height: 1.35, color: _primary, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                l10n.termsConsentTermsSuffix,
                                style: TextStyle(fontSize: 14, height: 1.35, color: muted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ConsentRow(
                          value: _acceptPrivacy,
                          primary: _primary,
                          onChanged: (v) => setState(() => _acceptPrivacy = v),
                          child: Wrap(
                            children: [
                              Text(
                                l10n.termsConsentPrivacyPrefix,
                                style: TextStyle(fontSize: 14, height: 1.35, color: muted, fontWeight: FontWeight.w600),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/privacy'),
                                child: Text(
                                  l10n.termsConsentPrivacyLink,
                                  style: TextStyle(fontSize: 14, height: 1.35, color: _primary, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                l10n.termsConsentPrivacySuffix,
                                style: TextStyle(fontSize: 14, height: 1.35, color: muted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + MediaQuery.of(context).padding.bottom),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0B1220) : Colors.white).withOpacity(0.90),
                  border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.showBack ? _onBack : null,
                      icon: Icon(Icons.chevron_left, color: _primary),
                      label: Text(l10n.back, style: TextStyle(color: _primary, fontWeight: FontWeight.w800)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canNext ? _onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primary.withOpacity(0.35),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : Text(l10n.next, style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocIllustration extends StatelessWidget {
  const _DocIllustration({required this.isDark, required this.primary, required this.secondary});

  final bool isDark;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final halo = isDark ? const Color(0xFF1D4ED8).withOpacity(0.16) : const Color(0xFF93C5FD).withOpacity(0.35);
    final card = isDark ? const Color(0xFF0F172A) : Colors.white;
    final line = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final border = isDark ? Colors.white12 : const Color(0xFFF1F5F9);

    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
          ),
          Container(
            width: 120,
            height: 150,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(w: double.infinity, c: line),
                const SizedBox(height: 10),
                _Line(w: 68, c: line),
                const SizedBox(height: 10),
                _Line(w: double.infinity, c: line),
                const SizedBox(height: 10),
                _Line(w: 52, c: line),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: secondary,
                shape: BoxShape.circle,
                border: Border.all(color: card, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.12), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.w, required this.c});

  final double w;
  final Color c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: w,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.primary,
    required this.isDark,
    required this.bold,
    required this.normal,
  });

  final Color primary;
  final bool isDark;
  final String bold;
  final String normal;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('•', style: TextStyle(color: primary, fontSize: 20, height: 1)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: bold,
                  style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w900, color: titleColor),
                ),
                TextSpan(
                  text: normal,
                  style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600, color: bodyColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.primary,
    required this.onChanged,
    required this.child,
  });

  final bool value;
  final Color primary;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _CustomCheckbox(value: value, primary: primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  const _CustomCheckbox({required this.value, required this.primary});

  final bool value;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: value ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: value ? primary : border, width: 2),
      ),
      child: value ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
    );
  }
}
