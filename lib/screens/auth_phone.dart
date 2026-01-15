import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class AuthPhoneScreen extends StatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final Color _primaryColor = const Color(0xFF7B828E);
  final Color _cardBorder = const Color(0xFFE4E7EB);
  bool _isValidPhone = false;
  bool _isSending = false;
  bool _isGoogleLoading = false;
  String? _verificationId;
  int? _resendToken;

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
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatPhone(String raw) {
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    return '+91$digits';
  }

  Future<void> _sendOtp() async {
    final String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 && !(digits.length == 12 && digits.startsWith('91'))) {
      _showSnack(tr('enterPhone'));
      return;
    }

    final String phone = _formatPhone(_phoneController.text);
    if (mounted) {
      setState(() => _isSending = true);
    }

    try {
      await FirebaseService.auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final UserCredential userCredential =
              await FirebaseService.auth.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => _isSending = false);
          _navigateAfterAuth(userCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnack(e.message ?? 'Failed to send OTP');
          if (mounted) {
            setState(() => _isSending = false);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (!mounted) return;
          setState(() => _isSending = false);
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: <String, dynamic>{
              'verificationId': verificationId,
              'phoneNumber': phone,
              'resendToken': resendToken,
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (mounted) {
            setState(() => _isSending = false);
          }
        },
      );
    } catch (_) {
      _showSnack('Could not send OTP. Please try again.');
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (mounted) {
      setState(() => _isGoogleLoading = true);
    }
    try {
      final UserCredential credential = await FirebaseService.signInWithGoogle();
      if (!mounted) return;
      _navigateAfterAuth(credential);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Google sign-in failed.');
    } catch (_) {
      _showSnack('Google sign-in failed. Try again.');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _handlePhoneChanged(String value) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    final bool valid = digits.length == 10;
    if (valid != _isValidPhone) {
      setState(() => _isValidPhone = valid);
    }
  }

  void _continueAsGuest() {
    Navigator.pushNamed(context, '/guest');
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
              const SizedBox(height: 12),
              _buildCard(),
              const SizedBox(height: 36),
              Text(
                tr('orContinue'),
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildGuestButton(),
              const SizedBox(height: 12),
              Text(
                tr('continueWithoutLogin'),
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
          const SizedBox(height: 4),
          Text(
            tr('enterPhone'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tr('phoneNumber'),
              style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: _handlePhoneChanged,
            decoration: InputDecoration(
              hintText: '+91 98765 43210',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isValidPhone && !_isSending ? _sendOtp : null,
              icon: const SizedBox.shrink(),
              label: _isSending
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
                        const Text('Sending...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(tr('sendOtp')),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isValidPhone && !_isSending
                    ? _primaryColor
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
              icon: _isGoogleLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryColor,
                      ),
                    )
                  : const Icon(Icons.g_mobiledata, size: 28),
              label: Text(
                _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: _cardBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      height: 52,
      width: 180,
      child: OutlinedButton(
        onPressed: _continueAsGuest,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: _cardBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Text(tr('continueGuest')),
      ),
    );
  }
}
