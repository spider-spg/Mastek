import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.termsAndConditions),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
            ),
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              l10n.termsConditionsBody,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}
