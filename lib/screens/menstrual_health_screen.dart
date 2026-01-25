import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

class MenstrualHealthScreen extends StatelessWidget {
  const MenstrualHealthScreen({super.key});

  static const Color _primary = Color(0xFFE48191);
  static const Color _backgroundLight = Color(0xFFEFF3F5);
  static const Color _backgroundDark = Color(0xFF2B303B);
  static const Color _softRed = Color(0xFFCC6D84);
  static const Color _leafGreen = Color(0xFF66AA66);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final bg = isDark ? _backgroundDark : _backgroundLight;
    final card = isDark ? const Color(0xFF1F2430) : Colors.white;
    final divider = isDark ? Colors.white10 : Colors.black.withOpacity(0.06);
    final text = isDark ? Colors.white : const Color(0xFF1A0F11);
    final muted = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A3F41);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: bg.withOpacity(0.80),
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  titleSpacing: 16,
                  title: Row(
                    children: <Widget>[
                      _CircleButton(
                        onTap: () => Navigator.of(context).maybePop(),
                        background: card,
                        child: Icon(Icons.arrow_back_rounded, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.menstrualScreenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(isDark ? 0.18 : 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_library_rounded, color: _primary, size: 20),
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: divider),
                  ),
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      <Widget>[
                        _Card(
                          background: card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(Icons.auto_awesome_rounded, color: _primary, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.menstrualWhatIsMenstruationTitle,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.menstrualWhatIsMenstruationBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: divider),
                              const SizedBox(height: 16),
                              _GradientQuote(isDark: isDark, text: l10n.menstrualQuote),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        _Card(
                          background: card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(Icons.calendar_today_rounded, color: _primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.menstrualWhatIsNormalTitle,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _CheckItem(text: l10n.menstrualNormalItem1, isDark: isDark),
                              _CheckItem(text: l10n.menstrualNormalItem2, isDark: isDark),
                              _CheckItem(text: l10n.menstrualNormalItem3, isDark: isDark),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        _WarningCard(isDark: isDark),

                        const SizedBox(height: 18),

                        _Card(
                          background: card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(Icons.sanitizer_rounded, color: _primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.menstrualHygieneTipsTitle,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _TipTile(
                                icon: Icons.water_drop_rounded,
                                title: l10n.menstrualTipChangeRegularlyTitle,
                                subtitle: l10n.menstrualTipChangeRegularlySubtitle,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _TipTile(
                                icon: Icons.front_hand_rounded,
                                title: l10n.menstrualTipCleanHandsTitle,
                                subtitle: l10n.menstrualTipCleanHandsSubtitle,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _TipTile(
                                icon: Icons.dry_cleaning_rounded,
                                title: l10n.menstrualTipStayDryTitle,
                                subtitle: l10n.menstrualTipStayDrySubtitle,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        _Card(
                          background: card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(Icons.psychology_rounded, color: _primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.menstrualMythsFactsTitle,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _MythFact(
                                myth: l10n.menstrualMyth1,
                                fact: l10n.menstrualFact1,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: divider),
                              const SizedBox(height: 12),
                              _MythFact(
                                myth: l10n.menstrualMyth2,
                                fact: l10n.menstrualFact2,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.background, required this.child});

  final VoidCallback onTap;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: isDark ? 0 : 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 20,
              color: Color.fromRGBO(0, 0, 0, 0.05),
            ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientQuote extends StatelessWidget {
  const _GradientQuote({required this.isDark, required this.text});

  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            MenstrualHealthScreen._primary.withOpacity(0.10),
            isDark ? const Color(0x334C7DFF) : const Color(0xFFE7F0FF),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            right: -18,
            bottom: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MenstrualHealthScreen._primary.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -18,
            top: -18,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: (isDark ? const Color(0x334C7DFF) : const Color(0xFFBFD9FF)).withOpacity(0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: MenstrualHealthScreen._primary,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1A0F11);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: MenstrualHealthScreen._leafGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bg = MenstrualHealthScreen._softRed.withOpacity(isDark ? 0.20 : 0.10);
    final border = MenstrualHealthScreen._softRed;
    final title = MenstrualHealthScreen._softRed;
    final body = isDark ? const Color(0xFFFFE4EA) : const Color(0xFF4A1A1E);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: border, width: 4)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_rounded, color: title, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.menstrualWarningSignsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: title,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Bullet(text: l10n.menstrualWarningItem1, color: body),
          const SizedBox(height: 10),
          _Bullet(text: l10n.menstrualWarningItem2, color: body),
          const SizedBox(height: 10),
          _Bullet(text: l10n.menstrualWarningItem3, color: body),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(color: MenstrualHealthScreen._softRed, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.icon, required this.title, required this.subtitle, required this.isDark});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileBg = isDark ? Colors.white.withOpacity(0.06) : MenstrualHealthScreen._backgroundLight;
    final iconBg = isDark ? Colors.white.withOpacity(0.10) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A0F11);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4A3F41);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: MenstrualHealthScreen._primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MythFact extends StatelessWidget {
  const _MythFact({required this.myth, required this.fact, required this.isDark});

  final String myth;
  final String fact;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mythColor = isDark ? Colors.white : const Color(0xFF1A0F11);
    final factColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4A3F41);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.cancel_rounded, color: MenstrualHealthScreen._softRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                myth,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mythColor,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: MenstrualHealthScreen._leafGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fact,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: factColor,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
