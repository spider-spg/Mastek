import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

class LanguageOption {
  const LanguageOption(this.label, this.code);

  final String label;
  final String code;
}

const List<LanguageOption> kLanguageOptions = <LanguageOption>[
  LanguageOption('System (Auto)', 'auto'),
  LanguageOption('English – English', 'en'),
  LanguageOption('Hindi – हिंदी', 'hi'),
  LanguageOption('Marathi – मराठी', 'mr'),
  LanguageOption('Bengali – বাংলা', 'bn'),
  LanguageOption('Telugu – తెలుగు', 'te'),
  LanguageOption('Tamil – தமிழ்', 'ta'),
  LanguageOption('Gujarati – ગુજરાતી', 'gu'),
  LanguageOption('Kannada – ಕನ್ನಡ', 'kn'),
  LanguageOption('Malayalam – മലയാളം', 'ml'),
  LanguageOption('Punjabi – ਪੰਜਾਬੀ', 'pa'),
  LanguageOption('Odia – ଓଡ଼ିଆ', 'or'),
  LanguageOption('Assamese – অসমীয়া', 'as'),
  LanguageOption('Urdu – اردو', 'ur'),
];

String languageLabel(String code) {
  for (final opt in kLanguageOptions) {
    if (opt.code == code) return opt.label;
  }
  return 'English';
}

Future<String?> showLanguagePickerSheet(BuildContext context, {required String currentCode}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context);

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      String selected = currentCode;
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Text(
                        l10n.chooseLanguage,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: kLanguageOptions.length,
                          itemBuilder: (context, i) {
                            final opt = kLanguageOptions[i];
                            return RadioListTile<String>(
                              value: opt.code,
                              groupValue: selected,
                              dense: true,
                              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                              title: Text(
                                opt.label,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              onChanged: (v) => setState(() => selected = v ?? currentCode),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(selected),
                              child: Text(l10n.save),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
