import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_bootstrap.dart';
import '../services/locale_controller.dart';
import '../models/symptom_model.dart';
import '../widgets/language_picker_sheet.dart';
import 'package:symptom_checker/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.showBottomNav = true, this.onOpenChat}) : super(key: key);

  final bool showBottomNav;
  final VoidCallback? onOpenChat;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _disclaimerDismissedKey = 'home.disclaimer.dismissed';

  bool _disclaimerDismissed = false;
  bool _loadedDisclaimerPref = false;

  @override
  void initState() {
    super.initState();
    _loadDisclaimerPref();
  }

  Future<void> _loadDisclaimerPref() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_disclaimerDismissedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _disclaimerDismissed = dismissed;
      _loadedDisclaimerPref = true;
    });
  }

  Future<void> _dismissDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disclaimerDismissedKey, true);
    if (!mounted) return;
    setState(() => _disclaimerDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final symptomModel = context.watch<SymptomModel>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.homeHello, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          _GreetingName(textStyle: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Material(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 1,
                        child: IconButton(
                          icon: Icon(Icons.language, color: Theme.of(context).iconTheme.color),
                          onPressed: () async {
                            final picked = await showLanguagePickerSheet(
                              context,
                              currentCode: symptomModel.selectedLanguage,
                            );
                            if (picked == null || picked == symptomModel.selectedLanguage) return;
                            await symptomModel.setLanguage(picked);
                            if (!context.mounted) return;
                            await context.read<LocaleController>().setFromLanguageCode(picked);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        final cb = widget.onOpenChat;
                        if (cb != null) {
                          cb();
                        } else {
                          Navigator.of(context).pushNamed('/chat');
                        }
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4573D2),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(offset: Offset(0, 10), blurRadius: 24, color: Color.fromRGBO(69, 115, 210, 0.10))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.homeChatCta,
                                style: t.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Icons.keyboard_double_arrow_right, color: Color(0xFF4573D2)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_loadedDisclaimerPref && !_disclaimerDismissed) ...[
                    _DisclaimerBanner(
                      dismissible: true,
                      onDismiss: _dismissDisclaimer,
                    ),
                    const SizedBox(height: 14),
                  ],

                  Text(l10n.homeOurFeatures, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _FeatureTile(
                        icon: Icons.note_add,
                        label: l10n.featureSymptomChecker,
                        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/chat'),
                      ),
                      _FeatureTile(
                        icon: Icons.female,
                        label: l10n.featureWomensHealth,
                        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/women-health'),
                      ),
                      _FeatureTile(icon: Icons.security, label: l10n.featureInsurance),
                      _FeatureTile(
                        icon: Icons.summarize,
                        label: l10n.featureAiHealthSummary,
                        onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/ai-health-summary'),
                      ),
                      _FeatureTile(icon: Icons.checklist, label: l10n.featureReminders),
                      _FeatureTile(
                        icon: Icons.location_on,
                        label: l10n.featureLocateClinics,
                        onTap: () => Navigator.of(context).pushNamed('/clinics'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const _PromoCarousel(),

                  if (_loadedDisclaimerPref && _disclaimerDismissed) ...[
                    const SizedBox(height: 18),
                    const _DisclaimerBanner(dismissible: false),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: !widget.showBottomNav
          ? null
          : SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              boxShadow: const [BoxShadow(offset: Offset(0, 16), blurRadius: 32, color: Color.fromRGBO(0,0,0,0.06))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(color: isDark ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(999)),
                  child: const Icon(Icons.grid_view, color: Colors.white),
                ),
                IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => Navigator.of(context).pushNamed('/chat')),
                IconButton(icon: const Icon(Icons.schedule), onPressed: () {}),
                IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.of(context).pushNamed('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({this.dismissible = false, this.onDismiss});

  final bool dismissible;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final bg = isDark ? const Color(0xFF18263A) : const Color(0xFFEAF2FF);
    final border = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFBBD6FF);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyColor = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155);
    final iconColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF3B82F6);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.homeDisclaimerTitle}: ',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeDisclaimerBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bodyColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (dismissible)
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 18,
                icon: Icon(Icons.close, size: 18, color: bodyColor),
                onPressed: onDismiss,
                tooltip: l10n.close,
              ),
            ),
        ],
      ),
    );
  }
}

class _GreetingName extends StatelessWidget {
  const _GreetingName({this.textStyle});

  final TextStyle? textStyle;

  Future<String?> _loadCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile.fullName')?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!FirebaseBootstrap.isReady) {
      return FutureBuilder<String?>(
        future: _loadCachedName(),
        builder: (context, snap) {
          final name = snap.data;
          return Text('${(name?.isNotEmpty ?? false) ? name : l10n.homeThere}!', style: textStyle);
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return FutureBuilder<String?>(
        future: _loadCachedName(),
        builder: (context, snap) {
          final name = snap.data;
          return Text('${(name?.isNotEmpty ?? false) ? name : l10n.homeThere}!', style: textStyle);
        },
      );
    }

    final docStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['fullName'] ?? data?['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          return Text('$name!', style: textStyle);
        }

        return FutureBuilder<String?>(
          future: _loadCachedName(),
          builder: (context, snap) {
            final cached = snap.data;
            return Text('${(cached?.isNotEmpty ?? false) ? cached : l10n.homeThere}!', style: textStyle);
          },
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _FeatureTile({Key? key, required this.icon, required this.label, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade50, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.08),
                offset: const Offset(0, 6),
                blurRadius: 14,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _kAutoScrollEvery = Duration(seconds: 4);
  static const _kAnim = Duration(milliseconds: 420);

  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  List<_PromoItem> _items(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _PromoItem(
        title: l10n.promoAiSymptomCheckTitle,
        subtitle: l10n.promoAiSymptomCheckSubtitle,
        icon: Icons.auto_awesome,
        gradient: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
      ),
      _PromoItem(
        title: l10n.promoVoiceWaveformTitle,
        subtitle: l10n.promoVoiceWaveformSubtitle,
        icon: Icons.mic_rounded,
        gradient: const [Color(0xFF7C3AED), Color(0xFFC4B5FD)],
      ),
      _PromoItem(
        title: l10n.promoProfilePersonalizationTitle,
        subtitle: l10n.promoProfilePersonalizationSubtitle,
        icon: Icons.person_rounded,
        gradient: const [Color(0xFF059669), Color(0xFF6EE7B7)],
      ),
      _PromoItem(
        title: l10n.promoNearbyClinicsTitle,
        subtitle: l10n.promoNearbyClinicsSubtitle,
        icon: Icons.location_on_rounded,
        gradient: const [Color(0xFFEA580C), Color(0xFFFDBA74)],
        onTap: () => Navigator.of(context).pushNamed('/clinics'),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_kAutoScrollEvery, (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      final total = _items(context).length;
      if (total == 0) return;
      final next = (_index + 1) % total;
      _controller.animateToPage(next, duration: _kAnim, curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = theme.textTheme;
    final items = _items(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).homeHighlights, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: item.onTap,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.gradient,
                        ),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 14),
                            blurRadius: 30,
                            color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(isDark ? 0.10 : 0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Icon(item.icon, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withOpacity(0.9)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (i) {
              final selected = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withOpacity(0.85)
                      : theme.colorScheme.onSurface.withOpacity(isDark ? 0.25 : 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PromoItem {
  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onTap;
}
