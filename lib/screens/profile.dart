import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_bootstrap.dart';

enum Gender { male, female, other }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _kNameKey = 'profile.fullName';
  static const _kAgeKey = 'profile.age';
  static const _kGenderKey = 'profile.gender';
  static const _kConditionsKey = 'profile.conditions';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  Gender _gender = Gender.male;
  final Set<String> _selectedConditions = <String>{'none'};

  bool _loading = true;
  bool _saving = false;
  bool _initializedFromRemote = false;

  User? get _userOrNull => FirebaseBootstrap.isReady ? FirebaseAuth.instance.currentUser : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer Firestore as source-of-truth when signed in.
    final user = _userOrNull;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = snap.data() ?? const <String, dynamic>{};

        final name = (data['fullName'] ?? data['name'] ?? '').toString();
        final age = (data['age'] ?? '').toString();
        final genderRaw = (data['gender'] ?? 'male').toString();
        final conditions = (data['conditions'] as List?)?.map((e) => e.toString()).toList();

        setState(() {
          _nameController.text = name;
          _ageController.text = age;
          _gender = _genderFromRaw(genderRaw);
          _selectedConditions
            ..clear()
            ..addAll(conditions ?? <String>['none']);
          if (_selectedConditions.isEmpty) _selectedConditions.add('none');
          _loading = false;
          _initializedFromRemote = true;
        });
        return;
      } catch (_) {
        // Fall through to local cache.
      }
    }

    final name = prefs.getString(_kNameKey) ?? '';
    final age = prefs.getString(_kAgeKey) ?? '';
    final genderRaw = prefs.getString(_kGenderKey) ?? 'male';
    final conditions = prefs.getStringList(_kConditionsKey);

    setState(() {
      _nameController.text = name;
      _ageController.text = age;
      _gender = _genderFromRaw(genderRaw);
      _selectedConditions
        ..clear()
        ..addAll(conditions ?? <String>['none']);
      if (_selectedConditions.isEmpty) _selectedConditions.add('none');
      _loading = false;
    });
  }

  Gender _genderFromRaw(String raw) {
    switch (raw) {
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      case 'male':
      default:
        return Gender.male;
    }
  }

  String _genderToRaw(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
      case Gender.male:
      default:
        return 'male';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kNameKey, _nameController.text.trim());
    await prefs.setString(_kAgeKey, _ageController.text.trim());
    await prefs.setString(_kGenderKey, _genderToRaw(_gender));
    await prefs.setStringList(_kConditionsKey, _selectedConditions.toList(growable: false));

    // Persist to Firestore (source-of-truth) when signed in.
    final user = _userOrNull;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'email': user.email,
          'phone': user.phoneNumber,
          'fullName': _nameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'gender': _genderToRaw(_gender),
          'conditions': _selectedConditions.toList(growable: false),
          'profileCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profileSaved)),
    );
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.logoutQuestion),
          content: Text(l10n.logoutReturnToLogin),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.logOut)),
          ],
        );
      },
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guestMode', false);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // If Firebase isn't configured/initialized on this platform, ignore.
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _toggleCondition(String id) {
    setState(() {
      if (id == 'none') {
        _selectedConditions
          ..clear()
          ..add('none');
        return;
      }

      _selectedConditions.remove('none');

      if (_selectedConditions.contains(id)) {
        _selectedConditions.remove(id);
      } else {
        _selectedConditions.add(id);
      }

      if (_selectedConditions.isEmpty) {
        _selectedConditions.add('none');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final background = isDark ? const Color(0xFF1F262E) : const Color(0xFFF6F8F8);
    final primary = const Color(0xFF1D81C9);
    final muted = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF507895);
    final card = isDark ? const Color(0xFF222B34) : Colors.white;

    final user = _userOrNull;
    final docStream = user == null ? null : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    final form = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _ProfileHeader(primary: primary, name: _nameController.text),
          const SizedBox(height: 24),

          _Section(
            title: l10n.profileSectionFullName,
            child: _PillInput(
              controller: _nameController,
              hintText: l10n.profileHintFullName,
              keyboardType: TextInputType.name,
              fillColor: card,
              accent: primary,
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.profileSectionAge,
            child: _PillInput(
              controller: _ageController,
              hintText: l10n.profileHintAge,
              keyboardType: TextInputType.number,
              fillColor: card,
              accent: primary,
            ),
          ),
          const SizedBox(height: 16),

          _Section(
            title: l10n.profileSectionGender,
            child: Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    label: l10n.profileGenderMale,
                    icon: Icons.male,
                    selected: _gender == Gender.male,
                    onTap: () => setState(() => _gender = Gender.male),
                    primary: primary,
                    cardColor: card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCard(
                    label: l10n.profileGenderFemale,
                    icon: Icons.female,
                    selected: _gender == Gender.female,
                    onTap: () => setState(() => _gender = Gender.female),
                    primary: primary,
                    cardColor: card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderCard(
                    label: l10n.profileGenderOther,
                    icon: Icons.diversity_3,
                    selected: _gender == Gender.other,
                    onTap: () => setState(() => _gender = Gender.other),
                    primary: primary,
                    cardColor: card,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileChronicConditions,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: muted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.profileConditionsBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _ConditionRow(
            id: 'diabetes',
            title: l10n.conditionDiabetesTitle,
            subtitle: l10n.conditionDiabetesSubtitle,
            icon: Icons.bloodtype,
            iconColor: primary,
            iconBackground: isDark ? const Color(0xFF223C52) : const Color(0xFFEAF4FF),
            selected: _selectedConditions.contains('diabetes'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            id: 'bp_heart',
            title: l10n.conditionBpHeartTitle,
            subtitle: l10n.conditionBpHeartSubtitle,
            icon: Icons.favorite,
            iconColor: const Color(0xFFEF4444),
            iconBackground: isDark ? const Color(0xFF3A2430) : const Color(0xFFFFEEF0),
            selected: _selectedConditions.contains('bp_heart'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            id: 'asthma',
            title: l10n.conditionAsthmaTitle,
            subtitle: l10n.conditionAsthmaSubtitle,
            icon: Icons.air,
            iconColor: const Color(0xFF0891B2),
            iconBackground: isDark ? const Color(0xFF16323A) : const Color(0xFFE8FBFF),
            selected: _selectedConditions.contains('asthma'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            id: 'thyroid',
            title: l10n.conditionThyroidTitle,
            subtitle: l10n.conditionThyroidSubtitle,
            icon: Icons.monitor_heart,
            iconColor: const Color(0xFF8B5CF6),
            iconBackground: isDark ? const Color(0xFF2A2342) : const Color(0xFFF3EEFF),
            selected: _selectedConditions.contains('thyroid'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),
          const SizedBox(height: 12),
          _ConditionRow(
            id: 'tb',
            title: l10n.conditionTbTitle,
            subtitle: l10n.conditionTbSubtitle,
            icon: Icons.health_and_safety,
            iconColor: const Color(0xFFEA580C),
            iconBackground: isDark ? const Color(0xFF3B2A1D) : const Color(0xFFFFF2E6),
            selected: _selectedConditions.contains('tb'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),
          const SizedBox(height: 14),
          _ConditionRow(
            id: 'none',
            title: l10n.conditionNoneTitle,
            subtitle: l10n.conditionNoneSubtitle,
            icon: Icons.do_not_disturb_on,
            iconColor: isDark ? Colors.white70 : Colors.black54,
            iconBackground: isDark ? Colors.white10 : const Color(0xFFF2F5F7),
            selected: _selectedConditions.contains('none'),
            onChanged: _toggleCondition,
            primary: primary,
            cardColor: card,
          ),

          const SizedBox(height: 28),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
                shadowColor: Colors.transparent,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
              icon: const Icon(Icons.check_circle, size: 22),
              label: Text(_saving ? l10n.saving : l10n.saveChanges),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _logout,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                side: BorderSide(color: Colors.red.withOpacity(0.35), width: 1.6),
                foregroundColor: Colors.red,
                backgroundColor: Colors.transparent,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(l10n.logOut),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (docStream == null) {
      body = form;
    } else {
      body = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          // Populate once from the database (source-of-truth).
          if (!_initializedFromRemote && data != null && !_saving) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _nameController.text = (data['fullName'] ?? data['name'] ?? '').toString();
                _ageController.text = (data['age'] ?? '').toString();
                _gender = _genderFromRaw((data['gender'] ?? 'male').toString());
                final conditions = (data['conditions'] as List?)?.map((e) => e.toString()).toList();
                _selectedConditions
                  ..clear()
                  ..addAll(conditions ?? <String>['none']);
                if (_selectedConditions.isEmpty) _selectedConditions.add('none');
                _initializedFromRemote = true;
              });
            });
          }

          return form;
        },
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _ProfileTopBar(primary: primary, showBackButton: widget.showBackButton),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.primary, required this.showBackButton});

  final Color primary;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          if (showBackButton)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                      color: Colors.black.withOpacity(0.04),
                    )
                  ],
                ),
                child: Icon(Icons.arrow_back, color: primary),
              ),
            )
          else
            const SizedBox(width: 44, height: 44),
          const Spacer(),
          Text(
            l10n.profileTopBarTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.primary, required this.name});

  final Color primary;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = (name.trim().isNotEmpty ? name.trim()[0] : 'R').toUpperCase();

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, const Color(0xFF60A5FA)],
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 6),
                blurRadius: 22,
                color: Colors.black.withOpacity(0.08),
              )
            ],
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.profileHeaderSubtitle,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white60 : const Color(0xFF507895);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: labelColor),
          ),
        ),
        child,
      ],
    );
  }
}

class _PillInput extends StatelessWidget {
  const _PillInput({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.fillColor,
    required this.accent,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final Color fillColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 20,
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.cardColor,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.06) : cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: selected ? primary : Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 20,
              color: Colors.black.withOpacity(0.04),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary, size: 26),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.selected,
    required this.onChanged,
    required this.primary,
    required this.cardColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool selected;
  final void Function(String id) onChanged;
  final Color primary;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = selected ? primary : Colors.transparent;
    final background = selected ? primary.withOpacity(0.06) : cardColor;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 20,
              color: Colors.black.withOpacity(0.04),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(999)),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                color: isDark ? Colors.transparent : Colors.white,
              ),
              child: selected
                  ? Icon(Icons.check, size: 18, color: primary)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
