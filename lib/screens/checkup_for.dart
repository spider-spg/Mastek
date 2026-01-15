import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF1F2A3D);
const Color _mutedText = Color(0xFF5E6A7D);
const Color _cardBorder = Color(0xFFE4E7EB);
const Color _iconBg = Color(0xFFF2F6FA);

class CheckupForScreen extends StatelessWidget {
  const CheckupForScreen({super.key});

  void _goToProfiles(BuildContext context) {
    Navigator.pushNamed(context, '/profileList');
  }

  void _goToPersonalInfo(BuildContext context) {
    Navigator.pushNamed(context, '/personalInfo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 28),
              _OptionCard(
                icon: Icons.person_outline,
                title: 'Myself',
                subtitle: 'Guest',
                onTap: () => _goToPersonalInfo(context),
              ),
              const SizedBox(height: 16),
              _OptionCard(
                icon: Icons.add,
                title: 'Someone Else',
                subtitle: 'Add Profile',
                onTap: () => _goToProfiles(context),
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
        const CircleAvatar(
          radius: 42,
          backgroundColor: _iconBg,
          child: Icon(Icons.group_outlined, size: 42, color: _primaryColor),
        ),
        const SizedBox(height: 18),
        const Text(
          'Checkup For?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 32,
              backgroundColor: _iconBg,
              child: Icon(icon, size: 30, color: _primaryColor),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _mutedText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 22, color: _mutedText),
          ],
        ),
      ),
    );
  }
}
