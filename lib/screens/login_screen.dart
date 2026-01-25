import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import 'package:symptom_checker/screens/otp_verify_screen.dart';
import 'package:symptom_checker/services/user_repository.dart';

import '../services/firebase_bootstrap.dart';
import '../services/locale_controller.dart';
import '../widgets/language_picker_sheet.dart';

enum _LoginMode { sms, email }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginMode _mode = _LoginMode.sms;

  static const MethodChannel _otpChannel = MethodChannel('com.dndy.mastek/otp');

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _busy = false;

  final UserRepository _userRepository = UserRepository();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color get _iceBlue => const Color(0xFFF0F7FF);
  Color get _primary => const Color(0xFF0066CC);
  Color get _textDark => const Color(0xFF002D5C);
  Color get _muted => const Color(0xFF4A6D8C);
  Color get _fieldBg => const Color(0xFFF8FBFF);
  Color get _fieldBorder => const Color(0xFFCBDCEE);

  String? _normalizeIndianE164(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    // Accept: 10-digit local, 12-digit starting with 91, or already +91... (after stripping non-digits).
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return null;
  }

  Future<void> _ensureUserSaved(User user, {String? phone, String? email}) async {
    await _userRepository.ensureUserDocument(user, phone: phone, email: email);
  }

  Future<void> _signInGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guestMode', true);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/app', (_) => false);
    } catch (_) {
      _showSnack(AppLocalizations.of(context).loginUnableContinueGuest);
    }
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context);
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      _showSnack(l10n.loginEnterMobileNumber);
      return;
    }

    final phone = _normalizeIndianE164(raw);
    if (phone == null) {
      _showSnack(l10n.loginEnterValidMobileNumber);
      return;
    }

    setState(() => _busy = true);

    // Prefer Firebase Phone Auth when Firebase is configured.
    // NOTE: `verifyPhoneNumber` completes *before* code is sent (via callbacks),
    // so we must keep `_busy` true until we get `codeSent`/`verificationFailed`.
    if (FirebaseBootstrap.isReady) {
      try {
        FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (credential) async {
            try {
              final cred = await FirebaseAuth.instance.signInWithCredential(credential);
              final user = cred.user;
              if (user != null) {
                await _ensureUserSaved(user, phone: phone);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('guestMode', false);
              }
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/post-auth', (_) => false);
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          },
          verificationFailed: (e) {
            if (mounted) setState(() => _busy = false);
            _showSnack(e.message ?? l10n.loginFailedSendOtp);
          },
          codeSent: (verificationId, _) async {
            if (!mounted) return;
            setState(() => _busy = false);
            _showSnack(l10n.loginOtpSent);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OtpVerifyScreen(
                  phoneNumber: phone,
                  initialVerificationId: verificationId,
                  useFirebaseAuth: true,
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (_) {
            if (mounted) setState(() => _busy = false);
          },
        );
      } catch (_) {
        if (mounted) setState(() => _busy = false);
        _showSnack(l10n.loginFailedSendOtp);
      }
      return;
    }

    try {

      // Fallback to platform-channel OTP (guest/dev flows).
      final verificationId = await _otpChannel.invokeMethod<String>('sendOtp', {
        'phoneNumber': phone,
      });
      if (!mounted) return;

      if (verificationId == null || verificationId.isEmpty) {
        _showSnack(l10n.loginFailedSendOtp);
        return;
      }

      _showSnack(l10n.loginOtpSent);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phoneNumber: phone,
            initialVerificationId: verificationId,
            useFirebaseAuth: false,
          ),
        ),
      );
    } on PlatformException catch (e) {
      _showSnack(e.message ?? l10n.loginFailedSendOtp);
    } catch (_) {
      _showSnack(l10n.loginFailedSendOtp);
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context);

    if (_mode == _LoginMode.sms) {
      await _sendOtp();
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showSnack(l10n.loginEnterValidEmail);
      return;
    }
    if (password.length < 6) {
      _showSnack(l10n.loginPasswordMinChars);
      return;
    }

    setState(() => _busy = true);
    try {
      // Prefer sign-in first so existing users reliably log in.
      // If no account exists, fall back to creating the account.
      late final UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      final user = cred.user;
      if (user != null) {
        await _ensureUserSaved(user, email: email);

        // If user signed in, disable guest mode.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('guestMode', false);

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/post-auth', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        _showSnack(l10n.loginEmailPasswordDisabled);
      } else if (e.code == 'email-already-in-use') {
        _showSnack(l10n.loginAccountExistsTryLogin);
      } else if (e.code == 'weak-password') {
        _showSnack(l10n.loginWeakPassword);
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack(l10n.loginIncorrectPassword);
      } else if (e.code == 'invalid-email') {
        _showSnack(l10n.loginInvalidEmail);
      } else {
        _showSnack(e.message ?? l10n.loginLoginFailed);
      }
    } catch (_) {
      _showSnack(l10n.loginLoginFailed);
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = context.watch<LocaleController>();
    final currentLangCode = localeController.locale?.languageCode ?? 'auto';

    return Scaffold(
      backgroundColor: _iceBlue,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, viewport) {
                final maxWidth = min(430.0, viewport.maxWidth);
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              primary: _primary,
                              languageText: '${l10n.language}: ${languageLabel(currentLangCode)}',
                              onPickLanguage: () async {
                                final selected = await showLanguagePickerSheet(context, currentCode: currentLangCode);
                                if (selected == null) return;
                                await localeController.setFromLanguageCode(selected);
                                if (!context.mounted) return;
                                _showSnack(l10n.languageSetTo(languageLabel(selected)));
                              },
                              onHelp: () => Navigator.of(context).pushNamed('/help'),
                            ),
                            const SizedBox(height: 12),
                            _HeroCard(primary: _primary, textDark: _textDark, iceBlue: _iceBlue),
                            const SizedBox(height: 14),
                            _LoginCard(
                              mode: _mode,
                              onModeChanged: (m) => setState(() {
                                _mode = m;
                              }),
                              primary: _primary,
                              textDark: _textDark,
                              muted: _muted,
                              fieldBg: _fieldBg,
                              fieldBorder: _fieldBorder,
                              phoneController: _phoneController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              busy: _busy,
                              onContinue: _continue,
                            ),
                            const SizedBox(height: 18),
                            _Footer(
                              primary: _primary,
                              muted: _muted,
                              busy: _busy,
                              onGuest: _signInGuest,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF000000).withOpacity(0.12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color.fromRGBO(0, 0, 0, 0.12)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6)),
                          SizedBox(width: 12),
                          Text(l10n.loginSendingOtp, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.primary,
    required this.languageText,
    required this.onPickLanguage,
    required this.onHelp,
  });

  final Color primary;
  final String languageText;
  final VoidCallback onPickLanguage;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPickLanguage,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.language, color: primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  languageText,
                  style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onHelp,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 10, color: Color.fromRGBO(0, 0, 0, 0.06))],
            ),
            child: Icon(Icons.help_outline, color: primary, size: 22),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.primary, required this.textDark, required this.iceBlue});

  final Color primary;
  final Color textDark;
  final Color iceBlue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = max(260.0, MediaQuery.of(context).size.height * 0.32);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Replace this image with your own asset when ready.
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuA0BEXeVOcrjmkhtmilzVG5ijva0Manb4dPqMCYrgGm-w4aAKDNY9H5sFUbSBw8a6kqaJ-05ttJLWPuU_kr_qHarWhnS3_yc8Mpk1_upIAWKOUkCvUlu82Ds9kmIYZsFba9lR-try0iTdAX9VQAHg5ikVhDjWRiigKzPxXAoOJ3SJc7t1_mnpYe7qJW3HH0jO-3DcNsvkxDipIOvpNeXXsR0Ol3Bp_XZSlZAlPLf7Dt_CL4-fXBnZPjiLZPcuaURPwNjqNfgc_75NmG',
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(color: const Color(0xFFE1EDFA)),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFF0F7FF), Color.fromRGBO(240, 247, 255, 0.35), Colors.transparent],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MediMitra',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 44,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.loginHeroSubtitle,
                    style: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.mode,
    required this.onModeChanged,
    required this.primary,
    required this.textDark,
    required this.muted,
    required this.fieldBg,
    required this.fieldBorder,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.busy,
    required this.onContinue,
  });

  final _LoginMode mode;
  final ValueChanged<_LoginMode> onModeChanged;
  final Color primary;
  final Color textDark;
  final Color muted;
  final Color fieldBg;
  final Color fieldBorder;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool busy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 25,
            color: Color.fromRGBO(0, 102, 204, 0.08),
          ),
          BoxShadow(
            offset: Offset(0, 8),
            blurRadius: 10,
            color: Color.fromRGBO(0, 102, 204, 0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.loginTagline,
              style: TextStyle(
                color: muted.withOpacity(0.95),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF).withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: l10n.smsLogin,
                    selected: mode == _LoginMode.sms,
                    onTap: () => onModeChanged(_LoginMode.sms),
                    primary: primary,
                    muted: muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeTab(
                    label: l10n.emailLogin,
                    selected: mode == _LoginMode.email,
                    onTap: () => onModeChanged(_LoginMode.email),
                    primary: primary,
                    muted: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (mode == _LoginMode.sms) ...[
            _Label(l10n.loginMobileNumberLabel, color: textDark),
            const SizedBox(height: 8),
            _Field(
              controller: phoneController,
              hintText: l10n.loginMobileHint,
              keyboardType: TextInputType.phone,
              icon: Icons.call,
              prefixText: '+91 ',
              maxLength: 10,
              digitsOnly: true,
              primary: primary,
              bg: fieldBg,
              border: fieldBorder,
            ),
          ] else ...[
            _Label(l10n.loginEmailLabel, color: textDark),
            const SizedBox(height: 8),
            _Field(
              controller: emailController,
              hintText: l10n.emailHint,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail,
              primary: primary,
              bg: fieldBg,
              border: fieldBorder,
            ),
            const SizedBox(height: 14),
            _Label(l10n.loginPasswordLabel, color: textDark),
            const SizedBox(height: 8),
            _PasswordField(
              controller: passwordController,
              hintText: l10n.loginPasswordHint,
              primary: primary,
              bg: fieldBg,
              border: fieldBorder,
              obscure: obscurePassword,
              onToggle: onToggleObscure,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    busy
                      ? l10n.loginPleaseWait
                        : (mode == _LoginMode.sms)
                        ? l10n.loginSendOtp
                        : l10n.loginContinue,
                  ),
                  const SizedBox(width: 10),
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.muted,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? const [BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.06))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected ? primary : muted,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.icon,
    this.prefixText,
    this.maxLength,
    this.digitsOnly = false,
    required this.primary,
    required this.bg,
    required this.border,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData icon;
  final String? prefixText;
  final int? maxLength;
  final bool digitsOnly;
  final Color primary;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    // This login screen uses a light background; force readable dark input text
    // to avoid grey text in release APK builds.
    const textColor = Color(0xFF0B1F33);
    const hintColor = Color(0xFF6B7C8E);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: hintColor, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: primary),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: textColor, fontWeight: FontWeight.w800),
        counterText: maxLength == null ? null : '',
        filled: true,
        fillColor: bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.6), width: 1.4),
        ),
      ),
      style: const TextStyle(color: textColor, fontWeight: FontWeight.w800),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.primary,
    required this.bg,
    required this.border,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String hintText;
  final Color primary;
  final Color bg;
  final Color border;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF0B1F33);
    const hintColor = Color(0xFF6B7C8E);

    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: hintColor, fontWeight: FontWeight.w600),
        prefixIcon: Icon(Icons.lock, color: primary),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: primary),
        ),
        filled: true,
        fillColor: bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.6), width: 1.4),
        ),
      ),
      style: const TextStyle(color: textColor, fontWeight: FontWeight.w800),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.primary,
    required this.muted,
    required this.busy,
    required this.onGuest,
  });

  final Color primary;
  final Color muted;
  final bool busy;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFCBDCEE)]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.loginOr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: muted.withOpacity(0.55),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFCBDCEE), Colors.transparent]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onGuest,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primary.withOpacity(0.22), width: 2),
              backgroundColor: Colors.white.withOpacity(0.55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: primary,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.person_search, size: 20),
            label: Text(l10n.loginContinueAsGuest),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            l10n.loginAgreementText,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
      ],
    );
  }
}
