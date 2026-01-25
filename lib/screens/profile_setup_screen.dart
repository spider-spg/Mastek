import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_bootstrap.dart';

enum Gender { male, female, other }

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.allowBack = false});

  final bool allowBack;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _kNameKey = 'profile.fullName';
  static const _kAgeKey = 'profile.age';
  static const _kGenderKey = 'profile.gender';
  static const _kConditionsKey = 'profile.conditions';

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  Gender _gender = Gender.male;
  final Set<String> _conditions = <String>{};

  bool _loading = true;
  bool _saving = false;

  Color get _primary => const Color(0xFF1D81C9);
  Color get _bg => const Color(0xFFF6FAFF);

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic>? remote;
    if (FirebaseBootstrap.isReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          remote = snap.data();
        } catch (_) {
          // Ignore and fall back to local cache.
        }
      }
    }

    final cachedName = prefs.getString(_kNameKey);
    final cachedAge = prefs.getString(_kAgeKey);
    final cachedGender = prefs.getString(_kGenderKey);
    final cachedConditions = prefs.getStringList(_kConditionsKey);

    final remoteName = (remote?['fullName'] ?? remote?['name'])?.toString();
    final remoteAge = remote?['age']?.toString();
    final remoteGender = remote?['gender']?.toString();
    final remoteConditions = (remote?['conditions'] as List?)?.map((e) => e.toString()).toList();

    setState(() {
      _nameController.text = (remoteName ?? cachedName)?.trim() ?? '';
      _ageController.text = (remoteAge ?? cachedAge)?.trim() ?? '';
      _gender = _genderFromRaw((remoteGender ?? cachedGender ?? 'male').trim());
      _conditions
        ..clear()
        ..addAll(remoteConditions ?? cachedConditions ?? const <String>[]);
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

  void _toggleCondition(String id) {
    setState(() {
      if (id == 'none') {
        _conditions
          ..clear()
          ..add('none');
        return;
      }

      _conditions.remove('none');
      if (_conditions.contains(id)) {
        _conditions.remove(id);
      } else {
        _conditions.add(id);
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _finishSetup() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final ageRaw = _ageController.text.trim();

    if (name.isEmpty) {
      _snack('Enter your full name.');
      return;
    }

    final age = int.tryParse(ageRaw);
    if (age == null || age <= 0 || age > 120) {
      _snack('Enter a valid age.');
      return;
    }

    setState(() => _saving = true);
    try {
      final conditions = _conditions.isEmpty ? const <String>['none'] : _conditions.toList(growable: false);

      // Persist locally too (Profile screen reads these).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, name);
      await prefs.setString(_kAgeKey, age.toString());
      await prefs.setString(_kGenderKey, _genderToRaw(_gender));
      await prefs.setStringList(_kConditionsKey, conditions);

      // Persist to Firestore.
      if (FirebaseBootstrap.isReady) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {
              'uid': user.uid,
              'email': user.email,
              'phone': user.phoneNumber,
              'fullName': name,
              'age': age,
              'gender': _genderToRaw(_gender),
              'conditions': conditions,
              'profileCompleted': true,
              'lastLoginAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/app', (_) => false);
    } catch (_) {
      _snack('Failed to save profile.');
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: widget.allowBack,
              backgroundColor: _bg.withOpacity(0.9),
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 96,
              titleSpacing: 20,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF0E151B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Help us personalize your healthcare\nexperience.',
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black54, height: 1.2),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(offset: Offset(0, 8), blurRadius: 18, color: Color.fromRGBO(0, 0, 0, 0.04)),
                            ],
                          ),
                          child: Icon(Icons.person_add, color: _primary, size: 42),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'PERSONAL DETAILS',
                          style: t.labelLarge?.copyWith(
                            color: _primary.withOpacity(0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 22),

                        _LabeledField(
                          label: 'FULL NAME',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          hintText: 'e.g. Rahul Sharma',
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'AGE',
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          hintText: 'Years',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 18),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              'GENDER',
                              style: t.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _GenderTile(
                                label: 'Male',
                                icon: Icons.male,
                                selected: _gender == Gender.male,
                                primary: _primary,
                                onTap: () => setState(() => _gender = Gender.male),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GenderTile(
                                label: 'Female',
                                icon: Icons.female,
                                selected: _gender == Gender.female,
                                primary: _primary,
                                onTap: () => setState(() => _gender = Gender.female),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GenderTile(
                                label: 'Other',
                                icon: Icons.diversity_3,
                                selected: _gender == Gender.other,
                                primary: _primary,
                                onTap: () => setState(() => _gender = Gender.other),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  'CHRONIC CONDITIONS',
                                  style: t.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'SELECT ALL THAT APPLY',
                                style: t.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _ConditionRow(
                          id: 'diabetes',
                          title: 'Diabetes',
                          subtitle: 'मधुमेह',
                          icon: Icons.bloodtype,
                          iconBackground: const Color(0xFFE8F2FF),
                          iconColor: _primary,
                          selected: _conditions.contains('diabetes'),
                          onChanged: _toggleCondition,
                        ),
                        const SizedBox(height: 10),
                        _ConditionRow(
                          id: 'bp_heart',
                          title: 'BP & Heart',
                          subtitle: 'बीपी और हृदय',
                          icon: Icons.favorite,
                          iconBackground: const Color(0xFFFFEAEA),
                          iconColor: const Color(0xFFE74C3C),
                          selected: _conditions.contains('bp_heart'),
                          onChanged: _toggleCondition,
                        ),
                        const SizedBox(height: 10),
                        _ConditionRow(
                          id: 'asthma',
                          title: 'Asthma',
                          subtitle: 'अस्थमा',
                          icon: Icons.air,
                          iconBackground: const Color(0xFFE9FBFF),
                          iconColor: const Color(0xFF1BA9C7),
                          selected: _conditions.contains('asthma'),
                          onChanged: _toggleCondition,
                        ),
                        const SizedBox(height: 10),
                        _ConditionRow(
                          id: 'thyroid',
                          title: 'Thyroid',
                          subtitle: 'थायराइड',
                          icon: Icons.monitor_heart,
                          iconBackground: const Color(0xFFF3EFFF),
                          iconColor: const Color(0xFF7A3FFC),
                          selected: _conditions.contains('thyroid'),
                          onChanged: _toggleCondition,
                        ),
                        const SizedBox(height: 10),
                        _ConditionRow(
                          id: 'tb',
                          title: 'TB',
                          subtitle: 'टीबी',
                          icon: Icons.coronavirus,
                          iconBackground: const Color(0xFFFFF3E6),
                          iconColor: const Color(0xFFEF7D1A),
                          selected: _conditions.contains('tb'),
                          onChanged: _toggleCondition,
                        ),
                        const SizedBox(height: 10),
                        _ConditionRow(
                          id: 'none',
                          title: 'None',
                          subtitle: 'कोई नहीं',
                          icon: Icons.do_not_disturb_on,
                          iconBackground: const Color(0xFFF2F5F7),
                          iconColor: Colors.black54,
                          selected: _conditions.contains('none'),
                          onChanged: _toggleCondition,
                        ),

                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _finishSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              shadowColor: _primary.withOpacity(0.18),
                              elevation: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _saving ? 'Saving...' : 'Finish Setup',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.check_circle, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Text(
                            'By tapping finish, you agree to our Terms of Service and Privacy Policy regarding your health data.',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(color: Colors.black38, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 10),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.hintText,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label,
            style: t.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Colors.black38,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 8), blurRadius: 18, color: Color.fromRGBO(0, 0, 0, 0.03)),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFFCBD3DC), fontWeight: FontWeight.w600),
              filled: false,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color.fromRGBO(29, 129, 201, 0.25), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? primary : Colors.transparent, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 8), blurRadius: 18, color: Color.fromRGBO(0, 0, 0, 0.03)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? primary : const Color(0xFF4A6D8C),
                ),
              )
            ],
          ),
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
    required this.iconBackground,
    required this.iconColor,
    required this.selected,
    required this.onChanged,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(id),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? const Color(0xFF1D81C9) : Colors.transparent, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 8), blurRadius: 18, color: Color.fromRGBO(0, 0, 0, 0.03)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(999)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1A2430))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.black38, letterSpacing: 0.2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? const Color(0xFF1D81C9) : Colors.black12, width: 1.6),
                ),
                child: selected
                    ? const Center(child: Icon(Icons.check, size: 16, color: Color(0xFF1D81C9)))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
