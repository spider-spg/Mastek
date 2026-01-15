import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class AuthOtpScreen extends StatefulWidget {
  const AuthOtpScreen({super.key});

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final Color _primaryColor = const Color(0xFF7B828E);
  final Color _cardBorder = const Color(0xFFE4E7EB);
  bool _verifying = false;
  String? _verificationId;
  String? _phoneNumber;

  void _navigateAfterAuth(UserCredential credential) {
    final bool isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
    final String targetRoute = isNewUser ? '/personalInfo' : '/chat';
    Navigator.pushNamedAndRemoveUntil(
      context,
      targetRoute,
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _verificationId ??= args['verificationId'] as String?;
      _phoneNumber ??= args['phoneNumber'] as String?;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onVerify() async {
    final String otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack('Please enter the 6-digit code.');
      return;
    }

    if (_verificationId == null) {
      _showSnack('Missing verification details. Please request a new OTP.');
      return;
    }

    if (mounted) {
      setState(() => _verifying = true);
    }

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final UserCredential userCredential =
          await FirebaseService.auth.signInWithCredential(credential);
      if (!mounted) return;
      _navigateAfterAuth(userCredential);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Invalid code. Please try again.');
    } catch (_) {
      _showSnack('Could not verify the code. Try again.');
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 18),
              _buildCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 44,
          backgroundColor: _primaryColor.withOpacity(0.08),
          child: Icon(Icons.phone_outlined, size: 42, color: _primaryColor),
        ),
        const SizedBox(height: 20),
        Text(
          tr('welcome'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            tr('enterOtpTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tr('otpLabel'),
              style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (_phoneNumber != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Sent to $_phoneNumber',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              hintStyle: TextStyle(
                  color: Colors.grey.shade500, letterSpacing: 8, fontSize: 22),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _primaryColor, width: 1.6),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
                fontSize: 20, letterSpacing: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            tr('demoHint'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _verifying ? null : _onVerify,
              icon: const SizedBox.shrink(),
              label: _verifying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Verifying...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(tr('verify')),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
