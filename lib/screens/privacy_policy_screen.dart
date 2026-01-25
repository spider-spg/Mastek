import 'package:flutter/material.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  String _policyText() {
    // Keep this as plain text so it's easy to edit.
    return '''🔐 Privacy Policy

Last updated: January 19, 2026
App Name: MediMitra

1. Introduction

MediMitra is a healthcare support application designed to provide symptom guidance and health-related information. We take user privacy very seriously and have designed this app with a privacy-first approach. This Privacy Policy explains how we handle user data and how we ensure that no sensitive health information is misused or stored unnecessarily.

By using this app, you agree to the practices described in this policy.

2. Data We Collect

We collect only the minimum information required to improve user experience.

2.1 Basic Profile Information (Optional)

- Name or nickname (optional)
- Age group
- Gender (optional)

This information is used only to personalize the user experience and improve the relevance of health guidance.

We do not use this information for identification, tracking, or sharing.

3. Symptom and Health Data

- All symptom inputs remain only on the user’s device.
- We do not send symptom text, disease names, or chat conversations to any external server.
- No diagnosis data is stored in any central database.
- No disease history is permanently stored.
- The AI model runs locally on the device, ensuring that health data never leaves the phone.

4. Voice Data Handling

- Voice input is processed locally on the device.
- Audio is converted to text in real-time.
- The original audio is immediately deleted after conversion.
- No audio recordings are stored or transmitted.
- We do not retain voice data in any form.

5. Anonymization and Session-Based Storage

To protect user identity:

- Each session is assigned a random session ID.
- No real user identifiers are attached to health data.
- No phone number, email, or device ID is linked to symptom data.
- All stored data is fully anonymized.
- We cannot identify any individual user from stored data.

6. Temporary Storage and Auto-Deletion

- Chat history and temporary health data are stored only for a limited time.
- Data is automatically deleted after a fixed period.
- No long-term storage of symptom or conversation data is maintained.
- Users can manually clear all local data at any time.

7. Network Security

- All network communication uses HTTPS (end-to-end encrypted).
- No data is sent in plain text.
- No third-party analytics receive health or symptom data.

8. Data Sharing

We do not share any user data with:

- Advertisers
- Third-party companies
- Government agencies
- Analytics platforms

We do not sell, rent, or trade any user data.

9. Community & Outbreak Features

For community health insights:

- Only anonymous, aggregated symptom counts are used.
- No personal data, names, locations, or chat text are included.
- No individual user can ever be identified.
- No raw health data is exposed.

This ensures zero risk of re-identification.

10. Children’s Privacy

This app does not knowingly collect personal data from children under the age of 13.
If a parent or guardian believes that data has been unintentionally collected, they may request deletion.

11. User Control

Users have full control to:

- Edit or remove profile information
- Clear chat history
- Disable voice features
- Opt out of community features

All data can be removed from the device at any time.

12. Disclaimer

This app is not a medical diagnostic tool and does not replace professional medical advice.
All guidance is informational only and users are encouraged to consult a qualified doctor for medical decisions.

13. Changes to This Policy

We may update this Privacy Policy as the app evolves.
Any changes will be clearly displayed inside the app.

14. Contact

If you have any questions about privacy or data handling, you can contact:

Developer: MediMitra Team
Email: support@medimitra.app
''';
  }

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
        title: Text(l10n.privacyPolicy),
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
              _policyText(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}
