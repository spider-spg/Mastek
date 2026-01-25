import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import '../outbreak/outbreak_detector.dart';
import '../outbreak/outbreak_models.dart';
import '../outbreak/outbreak_region_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _regionService = OutbreakRegionService();
  final _detector = OutbreakDetector();

  final TextEditingController _pinController = TextEditingController();

  String? _region;
  bool _loading = true;
  bool _savingRegion = false;
  List<OutbreakAlert> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final region = await _regionService.getRegionCode();
    if (!mounted) return;
    setState(() {
      _region = region;
      _loading = false;
    });

    if (region != null) {
      await _refresh();
    }
  }

  Future<void> _refresh() async {
    final region = _region;
    if (region == null) return;

    setState(() => _loading = true);
    try {
      final alerts = await _detector.detectForRegion(regionCode: region);
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _levelColor(OutbreakLevel level) {
    switch (level) {
      case OutbreakLevel.high:
        return const Color(0xFFDC2626);
      case OutbreakLevel.warning:
        return const Color(0xFFF59E0B);
      case OutbreakLevel.watch:
        return const Color(0xFF2563EB);
      case OutbreakLevel.none:
        return const Color(0xFF64748B);
    }
  }

  String _levelText(AppLocalizations l10n, OutbreakLevel level) {
    switch (level) {
      case OutbreakLevel.high:
        return l10n.outbreakLevelHighRisk;
      case OutbreakLevel.warning:
        return l10n.outbreakLevelWarning;
      case OutbreakLevel.watch:
        return l10n.outbreakLevelWatch;
      case OutbreakLevel.none:
        return l10n.outbreakLevelNone;
    }
  }

  Future<void> _saveRegion() async {
    if (_savingRegion) return;

    final l10n = AppLocalizations.of(context);

    final pin = _pinController.text.trim();
    if (pin.replaceAll(RegExp(r'\D'), '').length < 3) {
      _snack(l10n.enterFirst3DigitsPin);
      return;
    }

    setState(() => _savingRegion = true);
    try {
      await _regionService.setRegionFromPin(pin);
      final region = await _regionService.getRegionCode();
      if (!mounted) return;
      setState(() {
        _region = region;
      });
      await _refresh();
    } catch (_) {
      _snack(l10n.unableToSaveRegion);
    } finally {
      if (!mounted) return;
      setState(() => _savingRegion = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_none, size: 22),
                      const SizedBox(width: 10),
                      Text(l10n.notifications, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: (_region == null || _loading) ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.communityOutbreakAlerts, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            l10n.outbreakPrivacyNote,
                            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : Colors.black54, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _region == null ? l10n.regionNotSet : l10n.regionPin3Line(_region!),
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              TextButton(
                                onPressed: _savingRegion
                                    ? null
                                    : () async {
                                        final ok = await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (ctx) {
                                            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
                                            return Padding(
                                              padding: EdgeInsets.fromLTRB(18, 18, 18, bottom + 18),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(l10n.setAreaPin3Title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    l10n.setAreaPin3Body,
                                                    style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : Colors.black54),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  TextField(
                                                    controller: _pinController,
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(hintText: l10n.pinExampleHint),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    height: 48,
                                                    child: ElevatedButton(
                                                      onPressed: () => Navigator.of(ctx).pop(true),
                                                      child: Text(l10n.save),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  SizedBox(
                                                    height: 44,
                                                    child: TextButton(
                                                      onPressed: () => Navigator.of(ctx).pop(false),
                                                      child: Text(l10n.cancel),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        if (ok == true) {
                                          await _saveRegion();
                                        }
                                      },
                                child: Text(l10n.set),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : (_region == null)
                            ? Center(
                                child: Text(
                                  l10n.setPin3ToSeeAlerts,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              )
                            : (_alerts.isEmpty)
                                ? Center(
                                    child: Text(
                                      l10n.noAlertsToday,
                                      style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black54),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _alerts.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final a = _alerts[index];
                                      final color = _levelColor(a.level);
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(isDark ? 0.28 : 0.12),
                                                      borderRadius: BorderRadius.circular(999),
                                                      border: Border.all(color: color.withOpacity(isDark ? 0.50 : 0.22)),
                                                    ),
                                                    child: Text(
                                                      _levelText(l10n, a.level),
                                                      style: TextStyle(color: color, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(a.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(a.details, style: theme.textTheme.bodyMedium?.copyWith(height: 1.25)),
                                              const SizedBox(height: 10),
                                              Text(l10n.prevention, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                                              const SizedBox(height: 6),
                                              ...a.measures.map(
                                                (m) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('•  '),
                                                      Expanded(child: Text(m, style: theme.textTheme.bodyMedium)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
