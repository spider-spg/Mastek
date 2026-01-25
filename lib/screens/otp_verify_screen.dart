import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import '../services/firebase_bootstrap.dart';
import '../services/user_repository.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    super.key,
    required this.phoneNumber,
    required this.initialVerificationId,
    this.useFirebaseAuth = true,
  });

  final String phoneNumber;
  final String initialVerificationId;
  final bool useFirebaseAuth;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const MethodChannel _otpChannel = MethodChannel('com.dndy.mastek/otp');

  final UserRepository _userRepository = UserRepository();

  late String _verificationId;

  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 45;
  bool _busy = false;

  Color get _iceBlue => const Color(0xFFF0F7FF);
  Color get _primary => const Color(0xFF0066CC);
  Color get _textDark => const Color(0xFF002D5C);
  Color get _muted => const Color(0xFF4A6D8C);
  Color get _fieldBorder => const Color(0xFFCBDCEE);

  bool get _canResend => _secondsLeft <= 0 && !_busy;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.initialVerificationId;
    _startTimer();

    // Autofocus first box after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _otpValue() => _controllers.map((c) => c.text).join();

  Future<void> _resendCode() async {
    if (!_canResend) return;

    final l10n = AppLocalizations.of(context);

    setState(() => _busy = true);
    try {
      if (widget.useFirebaseAuth && FirebaseBootstrap.isReady) {
        FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: widget.phoneNumber,
          verificationCompleted: (credential) async {
            final cred = await FirebaseAuth.instance.signInWithCredential(credential);
            final user = cred.user;
            if (user != null) {
              await _userRepository.ensureUserDocument(user, phone: widget.phoneNumber);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('guestMode', false);
            }
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/post-auth', (_) => false);
          },
          verificationFailed: (e) {
            if (mounted) setState(() => _busy = false);
            _showSnack(e.message ?? l10n.otpFailedResend);
          },
          codeSent: (verificationId, _) {
            if (!mounted) return;
            setState(() => _busy = false);
            setState(() => _verificationId = verificationId);
            for (final c in _controllers) {
              c.clear();
            }
            _focusNodes.first.requestFocus();
            _startTimer();
            _showSnack(l10n.otpCodeResent);
          },
          codeAutoRetrievalTimeout: (_) {
            if (mounted) setState(() => _busy = false);
          },
        );
        return;
      }

      final verificationId = await _otpChannel.invokeMethod<String>('sendOtp', {
        'phoneNumber': widget.phoneNumber,
      });
      if (!mounted) return;

      if (verificationId == null || verificationId.isEmpty) {
        _showSnack(l10n.otpFailedResend);
        return;
      }

      setState(() => _verificationId = verificationId);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _startTimer();
      _showSnack(l10n.otpCodeResent);
    } on PlatformException catch (e) {
      _showSnack(e.message ?? l10n.otpFailedResend);
    } catch (_) {
      _showSnack(l10n.otpFailedResend);
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyAndProceed() async {
    if (_busy) return;

    final l10n = AppLocalizations.of(context);

    final code = _otpValue();
    if (code.length != 6 || code.contains(RegExp(r'\D'))) {
      _showSnack(l10n.otpEnter6Digit);
      return;
    }

    setState(() => _busy = true);
    try {
      if (widget.useFirebaseAuth && FirebaseBootstrap.isReady) {
        final credential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: code);
        final cred = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = cred.user;
        if (user != null) {
          await _userRepository.ensureUserDocument(user, phone: widget.phoneNumber);
        }

        // OTP login succeeded; disable guest mode.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('guestMode', false);

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/post-auth', (_) => false);
        return;
      }

      // Platform-channel fallback (does not create a Firebase user by itself).
      final ok = await _otpChannel.invokeMethod<bool>('verifyOtp', {
        'verificationId': _verificationId,
        'smsCode': code,
      });

      if (ok != true) {
        _showSnack(l10n.otpInvalid);
        return;
      }

      // Best-effort: if a Firebase user exists for some reason, ensure Firestore doc.
      if (FirebaseBootstrap.isReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _userRepository.ensureUserDocument(user, phone: widget.phoneNumber);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guestMode', false);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/post-auth', (_) => false);
    } on PlatformException catch (e) {
      _showSnack(e.message ?? l10n.otpVerificationFailed);
    } catch (_) {
      _showSnack(l10n.otpVerificationFailed);
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  void _handleChanged(int index, String value) {
    if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }
    if (value.isEmpty) return;

    // Support pasting full code into any box.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) return;

      for (var i = 0; i < 6; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }

      final next = digits.length >= 6 ? 5 : digits.length;
      _focusNodes[next.clamp(0, 5)].requestFocus();
      if (_otpValue().length == 6) {
        _verifyAndProceed();
      }
      return;
    }

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      _verifyAndProceed();
    }
  }

  String _formatTimer() {
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _displayPhone(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      final local = digits.substring(2);
      return '+91 ${local.substring(0, 5)} ${local.substring(5)}';
    }
    return e164;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxWidth = 430.0;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardVisible = viewInsetsBottom > 0;

    return Scaffold(
      backgroundColor: _iceBlue,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, viewport) {
                final width = viewport.maxWidth.clamp(0.0, maxWidth);
                final horizontalPad = width < 360 ? 18.0 : 32.0;
                final isShort = viewport.maxHeight < 720;
                return Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _busy ? null : () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color.fromRGBO(0, 0, 0, 0.08)),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new, color: _primary, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.otpVerifyNumber,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 52),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad, 10),
                        child: Column(
                          children: [
                            SizedBox(height: isShort ? 2 : 8),
                            Text(
                              'MediMitra',
                              style: TextStyle(
                                color: _primary,
                                fontSize: isShort ? 24 : 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: isShort ? 12 : 18),
                            Text(
                              l10n.otpSentTo,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _displayPhone(widget.phoneNumber),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                            ),
                            SizedBox(height: isShort ? 12 : 18),
                            LayoutBuilder(
                              builder: (context, box) {
                                final gap = box.maxWidth < 360 ? 6.0 : 10.0;
                                final available = box.maxWidth - gap * 5;
                                // Slightly larger boxes, but still guaranteed to fit.
                                final side = (available / 6).clamp(42.0, 60.0);
                                final height = (side + 18).clamp(62.0, 78.0);
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(6, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: i == 5 ? 0 : gap),
                                      child: _OtpBox(
                                        width: side,
                                        height: height,
                                        controller: _controllers[i],
                                        focusNode: _focusNodes[i],
                                        onChanged: (v) => _handleChanged(i, v),
                                        border: _fieldBorder,
                                        shadowColor: _primary,
                                        textColor: _textDark,
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                            SizedBox(height: isShort ? 10 : 18),
                            Text(
                              l10n.otpHaventReceived,
                              style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTimer(),
                                  style: TextStyle(color: _muted.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 10),
                                Container(width: 4, height: 4, decoration: BoxDecoration(color: _muted.withOpacity(0.3), shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: _canResend ? _resendCode : null,
                                  child: Text(
                                    l10n.otpResendCode,
                                    style: TextStyle(fontWeight: FontWeight.w900, color: _primary),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),

                    AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        0,
                        horizontalPad,
                        (keyboardVisible ? viewInsetsBottom : 0) + 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: isShort ? 58 : 64,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _verifyAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _busy ? l10n.loginPleaseWait : l10n.otpVerifyProceed,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(width: 10),
                                  if (_busy)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.check_circle, size: 22),
                                ],
                              ),
                            ),
                          ),
                          if (!keyboardVisible) ...[
                            SizedBox(height: isShort ? 14 : 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [Colors.transparent, Color(0xFFCBDCEE)],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.otpSafetyFirst,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: _muted.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [Color(0xFFCBDCEE), Colors.transparent],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                l10n.otpSafetyNote,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                      ],
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
                        boxShadow: const [BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color.fromRGBO(0, 0, 0, 0.12))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.6),
                          ),
                          SizedBox(width: 12),
                          Text(l10n.otpVerifying, style: const TextStyle(fontWeight: FontWeight.w800)),
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.border,
    required this.shadowColor,
    required this.textColor,
  });

  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Color border;
  final Color shadowColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: shadowColor.withOpacity(0.55), width: 1.6),
          ),
        ),
        cursorColor: shadowColor,
        onChanged: onChanged,
      ),
    );
  }
}
