import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

class AboutMediMitraScreen extends StatelessWidget {
  const AboutMediMitraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: false,
              backgroundColor: bg,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(l10n.aboutMediMitra),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(
                      isDark: isDark,
                      title: 'MediMitra',
                      subtitle: 'Your AI-powered health companion for fast symptom guidance and support.',
                    ),
                    const SizedBox(height: 18),

                    _SectionTitle(title: 'What MediMitra Does'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Column(
                        children: const [
                          _FeatureRow(
                            icon: Icons.chat_bubble_rounded,
                            title: 'Symptom Checker',
                            subtitle: 'Describe symptoms by voice or text and get guidance.',
                          ),
                          _Divider(),
                          _FeatureRow(
                            icon: Icons.location_on_rounded,
                            title: 'Clinic Locator',
                            subtitle: 'Find clinics near you when you need in-person care.',
                          ),
                          _Divider(),
                          _FeatureRow(
                            icon: Icons.notifications_rounded,
                            title: 'Alerts & Updates',
                            subtitle: 'Stay informed with important health updates and reminders.',
                          ),
                          _Divider(),
                          _FeatureRow(
                            icon: Icons.translate_rounded,
                            title: 'Multi-language Support',
                            subtitle: 'Use the app in your preferred language.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    _SectionTitle(title: 'Privacy & Safety'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MediMitra provides informational guidance and does not replace professional medical advice.',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'If symptoms are severe or worsening, seek immediate medical help. Your data is handled with care and used to improve the experience.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.82)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _SectionTitle(title: 'App Info'),
                    const SizedBox(height: 10),
                    _Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Version',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                FutureBuilder<PackageInfo>(
                                  future: PackageInfo.fromPlatform(),
                                  builder: (context, snap) {
                                    final info = snap.data;
                                    final v = info == null ? '—' : '${info.version} (${info.buildNumber})';
                                    return Text(
                                      v,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface.withOpacity(0.78),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Made for',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Text(
                                  'Mastek',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface.withOpacity(0.78),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.needHelp,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pushNamed('/contact'),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(l10n.contactUs),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  final bool isDark;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(isDark ? 0.28 : 0.18),
            cs.secondary.withOpacity(isDark ? 0.22 : 0.12),
            (isDark ? const Color(0xFF151A22) : Colors.white).withOpacity(0.9),
          ],
        ),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.health_and_safety_rounded, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.2),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Theme.of(context).dividerTheme.color);
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.78)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
