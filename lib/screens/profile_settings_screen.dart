import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_bootstrap.dart';
import '../services/notification_service.dart';
import '../services/theme_controller.dart';
import '../services/locale_controller.dart';
import '../models/symptom_model.dart';
import '../widgets/language_picker_sheet.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

enum _DeleteChoice { account, local }

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

  static const _progressDialogKey = 'profile.delete.progress';

  User? get _userOrNull => FirebaseBootstrap.isReady ? FirebaseAuth.instance.currentUser : null;

  Future<String> _loadCachedName() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('profile.fullName') ?? '').trim();
  }

  Future<void> _clearLocalData() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearLocalDataQuestion),
          content: Text(l10n.clearLocalDataBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.clear),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final model = context.read<SymptomModel>();
      model.messages.clear();
      model.selectedLanguage = 'auto';
      model.notifyListeners();

      if (!mounted) return;
      _snack(l10n.localDataCleared);
    } catch (_) {
      if (!mounted) return;
      _snack(l10n.couldNotClearLocalData);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    if (!FirebaseBootstrap.isReady) {
      _snack(l10n.accountDeletionNotAvailable);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack(l10n.noSignedInAccountFound);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteAccountQuestion),
          content: Text(l10n.deleteAccountBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteAccount),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Blocking progress UI.
    if (!mounted) return;
    BuildContext? progressDialogContext;
    var progressDialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        progressDialogContext = ctx;
        return AlertDialog(
          key: ValueKey(_progressDialogKey),
          content: SizedBox(
            height: 72,
            child: Row(
              children: [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6)),
                SizedBox(width: 14),
                Expanded(child: Text(l10n.deletingAccount)),
              ],
            ),
          ),
        );
      },
    );

    // Give the dialog a chance to render before heavy async work.
    await Future<void>.delayed(Duration.zero);

    // Note: The dialog above won't close by itself. We close it in finally.
    try {
      // Best-effort delete of user document.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete()
            .timeout(const Duration(seconds: 12));
      } catch (_) {
        // Ignore if doc doesn't exist, permission denied, or timed out.
      }

      await user.delete().timeout(const Duration(seconds: 20));
      await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 10));

      // Clear local device state as well.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear().timeout(const Duration(seconds: 10));

      final model = context.read<SymptomModel>();
      model.messages.clear();
      model.selectedLanguage = 'auto';
      model.notifyListeners();

      if (!mounted) return;

      // Close progress UI before navigating away.
      if (progressDialogOpen && progressDialogContext != null) {
        progressDialogOpen = false;
        try {
          Navigator.of(progressDialogContext!, rootNavigator: true).pop();
        } catch (_) {
          // Ignore if already closed.
        }
      }

      // Always go back to login after delete.
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        _snack(l10n.pleaseLoginAgainThenDelete);
      } else {
        _snack(e.message ?? l10n.couldNotDeleteAccount);
      }
    } on TimeoutException {
      if (!mounted) return;
      _snack(l10n.networkSlowTryAgain);
    } catch (_) {
      if (!mounted) return;
      _snack(l10n.couldNotDeleteAccount);
    } finally {
      // Close the progress dialog if it is still open.
      if (progressDialogOpen && progressDialogContext != null) {
        progressDialogOpen = false;
        try {
          Navigator.of(progressDialogContext!, rootNavigator: true).pop();
        } catch (_) {
          // Ignore if already closed.
        }
      }
    }
  }

  Future<void> _showDeleteOptions() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_DeleteChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.chooseAnAction, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: Color(0xFFDC2626)),
                title: Text(l10n.deleteAccount),
                subtitle: Text(l10n.permanentlyDeleteAccount),
                onTap: () => Navigator.of(context).pop(_DeleteChoice.account),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
                title: Text(l10n.deleteLocalData),
                subtitle: Text(l10n.deleteLocalDataOnDevice),
                onTap: () => Navigator.of(context).pop(_DeleteChoice.local),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    if (choice == _DeleteChoice.local) {
      await _clearLocalData();
      return;
    }
    await _deleteAccount();
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationService.getEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loadingNotifications = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatUserId(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleaned.length < 12) return cleaned;

    final v = cleaned.substring(0, 12).toUpperCase();
    return '${v.substring(0, 4)}-${v.substring(4, 8)}-${v.substring(8, 12)}';
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final symptomModel = context.watch<SymptomModel>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final user = _userOrNull;

    final docStream = user == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

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
              leading: widget.showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: const Text(''),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeaderCard(
                      user: user,
                      stream: docStream,
                      loadCachedName: _loadCachedName,
                      formatUserId: _formatUserId,
                      onEdit: () => Navigator.of(context).pushNamed('/profile-setup'),
                    ),
                    const SizedBox(height: 22),

                    _SectionTitle(title: l10n.settings),
                    const SizedBox(height: 10),
                    _Card(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _RowTile(
                            icon: Icons.notifications_rounded,
                            iconBg: const Color(0xFFEFF6FF),
                            iconFg: const Color(0xFF2563EB),
                            title: l10n.notifications,
                            subtitle: l10n.manageYourNotifications,
                            trailing: Switch.adaptive(
                              value: _notificationsEnabled,
                              onChanged: _loadingNotifications
                                  ? null
                                  : (v) async {
                                      setState(() => _notificationsEnabled = v);
                                      try {
                                        await NotificationService.setEnabled(v);
                                        if (!mounted) return;
                                        _snack(v ? l10n.notificationsEnabled : l10n.notificationsDisabled);
                                      } catch (_) {
                                        if (!mounted) return;
                                        _snack(l10n.couldNotUpdateNotifications);
                                      }
                                    },
                              activeTrackColor: const Color(0xFF34C759),
                              activeThumbColor: Colors.white,
                            ),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.dark_mode_rounded,
                            iconBg: const Color(0xFFEEF2FF),
                            iconFg: const Color(0xFF4F46E5),
                            title: l10n.darkMode,
                            subtitle: l10n.toggleDarkTheme,
                            trailing: Switch.adaptive(
                              value: theme.isDark,
                              onChanged: (v) => theme.setDarkEnabled(v),
                              activeTrackColor: const Color(0xFF34C759),
                              activeThumbColor: Colors.white,
                            ),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.language_rounded,
                            iconBg: const Color(0xFFF0FDFA),
                            iconFg: const Color(0xFF0D9488),
                            title: l10n.language,
                            subtitle: languageLabel(symptomModel.selectedLanguage),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () async {
                              final picked = await showLanguagePickerSheet(
                                context,
                                currentCode: symptomModel.selectedLanguage,
                              );
                              if (picked == null || picked == symptomModel.selectedLanguage) return;
                              await symptomModel.setLanguage(picked);
                              if (!context.mounted) return;
                              await context.read<LocaleController>().setFromLanguageCode(picked);
                              if (!context.mounted) return;
                              _snack(l10n.languageSetTo(languageLabel(picked)));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    _SectionTitle(title: l10n.supportAndInformation),
                    const SizedBox(height: 10),
                    _Card(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _RowTile(
                            icon: Icons.help_outline_rounded,
                            iconBg: const Color(0xFFFFF7ED),
                            iconFg: const Color(0xFFEA580C),
                            title: l10n.helpAndFaq,
                            subtitle: l10n.getHelpAndAnswers,
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () => Navigator.of(context).pushNamed('/help'),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.call_rounded,
                            iconBg: const Color(0xFFF0FDF4),
                            iconFg: const Color(0xFF16A34A),
                            title: l10n.contactUs,
                            subtitle: l10n.getInTouchWithSupport,
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () => Navigator.of(context).pushNamed('/contact'),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.info_outline_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconFg: const Color(0xFF475569),
                            title: l10n.aboutMediMitra,
                            subtitle: l10n.versionLine('0.1.0'),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () => Navigator.of(context).pushNamed('/about'),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.security_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconFg: const Color(0xFF475569),
                            title: l10n.privacyPolicy,
                            subtitle: l10n.howWeProtectYourData,
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () => Navigator.of(context).pushNamed('/privacy'),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.description_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconFg: const Color(0xFF475569),
                            title: l10n.termsAndConditions,
                            subtitle: l10n.legalAgreement,
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: () => Navigator.of(context).pushNamed('/terms'),
                          ),
                          const _Divider(),
                          _RowTile(
                            icon: Icons.delete_forever_rounded,
                            iconBg: const Color(0xFFFEF2F2),
                            iconFg: const Color(0xFFDC2626),
                            title: l10n.deleteData,
                            subtitle: l10n.deleteChatsAndSavedSettings,
                            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                            onTap: _showDeleteOptions,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: const BorderSide(color: Color(0xFFFFE4E6)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                      ),
                      child: Text(l10n.logOut, style: const TextStyle(color: Color(0xFFDC2626))),
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

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.user,
    required this.stream,
    required this.loadCachedName,
    required this.formatUserId,
    required this.onEdit,
  });

  final User? user;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? stream;
  final Future<String> Function() loadCachedName;
  final String Function(String? raw) formatUserId;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget content(Map<String, dynamic>? data, String cachedName) {
      final fullName = (data?['fullName'] ?? data?['name'] ?? cachedName).toString().trim();
      final displayName = fullName.isEmpty ? l10n.defaultUser : fullName;
      final String? userIdRaw = (data?['userId'] as String?) ?? user?.uid;
      final userIdFormatted = formatUserId(userIdRaw);

      final photoUrl = user?.photoURL;

      return Column(
        children: [
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                child: ClipOval(
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFCBD5E1),
                          child: const Icon(Icons.person_rounded, size: 46, color: Colors.white),
                        )
                      : Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFCBD5E1),
                              child: const Icon(Icons.person_rounded, size: 46, color: Colors.white),
                            );
                          },
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: const Color(0xFF2563EB),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onEdit,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (userIdFormatted.isNotEmpty)
            Text(
              l10n.userIdLine(userIdFormatted),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
          const SizedBox(height: 8),
        ],
      );
    }

    return Center(
      child: stream == null
          ? FutureBuilder<String>(
              future: loadCachedName(),
              builder: (context, snap) => content(null, snap.data ?? ''),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                return FutureBuilder<String>(
                  future: loadCachedName(),
                  builder: (context, cached) => content(data, cached.data ?? ''),
                );
              },
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 2.2,
              color: const Color(0xFF64748B),
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFF223042) : const Color(0xFFE2E8F0);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.9 : 0.7)),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6)),
              ],
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          height: 1.2,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        );

    final row = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 4),
                Text(subtitle, style: subtitleStyle),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30),
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      child: row,
    );
  }
}
