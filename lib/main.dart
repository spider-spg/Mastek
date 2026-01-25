import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'services/firebase_bootstrap.dart';
import 'symptom_analyzer.dart';
import 'models/symptom_model.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n.dart';
import 'outbreak/outbreak_analytics_service.dart';
import 'outbreak/outbreak_detector.dart';
import 'outbreak/outbreak_region_service.dart';
import 'outbreak/symptom_codes.dart';
import 'services/theme_controller.dart';
import 'services/notification_service.dart';
import 'screens/onboarding.dart';
import 'screens/home.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/clinic_locator_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/help_faq_chatbot_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/about_medimitra_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/terms_signing_screen.dart';
import 'screens/women_health_hub_screen.dart';
import 'screens/menstrual_health_screen.dart';
import 'screens/ai_health_summary_screen.dart';
import 'widgets/language_picker_sheet.dart';
import 'services/locale_controller.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseBootstrap.isReady = true;
  } catch (_) {
    FirebaseBootstrap.isReady = false;
  }

  // Starts FCM listeners + permission only if user enabled notifications.
  await NotificationService.initOnAppStart();

  final themeMode = await ThemeController.loadFromPrefs();
  final localeController = await LocaleController.loadFromPrefs();
  runApp(
    SymptomCheckerApp(
      themeController: ThemeController(initialMode: themeMode),
      localeController: localeController,
    ),
  );
}

class SymptomCheckerApp extends StatelessWidget {
  const SymptomCheckerApp({super.key, required this.themeController, required this.localeController});

  final ThemeController themeController;
  final LocaleController localeController;

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: const Color(0xFF1D81C9),
      platform: TargetPlatform.iOS,
    );

    final scheme = base.colorScheme;
    final bg = brightness == Brightness.dark ? const Color(0xFF0E1116) : const Color(0xFFF7F7FA);
    final surface = brightness == Brightness.dark ? const Color(0xFF151A22) : Colors.white;
    final t = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = t.copyWith(
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.15),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
      bodyLarge: t.bodyLarge?.copyWith(fontWeight: FontWeight.w400, height: 1.35),
      bodyMedium: t.bodyMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.35),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark ? Colors.white12 : Colors.black.withOpacity(0.06),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.35), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withOpacity(brightness == Brightness.dark ? 0.22 : 0.12),
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: scheme.onSurface.withOpacity(0.78))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SymptomModel()),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, theme, locale, _) {
          return MaterialApp(
            title: 'MediMitra',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale.locale,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: theme.mode,
            home: const HomeController(),
            routes: {
              '/app': (context) => const AppShell(),
              '/post-auth': (context) => const PostAuthGate(),
              '/chat': (context) => const AppRoot(),
              '/women-health': (context) => const WomenHealthHubScreen(),
              '/menstrual-health': (context) => const MenstrualHealthScreen(),
              '/ai-health-summary': (context) => const AiHealthSummaryScreen(),
              '/profile': (context) => const ProfileSettingsScreen(),
              '/profile-setup': (context) => const ProfileSetupScreen(allowBack: true),
              '/clinics': (context) => const ClinicLocatorScreen(),
              '/login': (context) => const LoginScreen(),
              '/help': (context) => const HelpFaqChatbotScreen(),
              '/contact': (context) => const ContactUsScreen(),
              '/about': (context) => const AboutMediMitraScreen(),
              '/privacy': (context) => const PrivacyPolicyScreen(),
              '/terms': (context) => const TermsConditionsScreen(),
            },
          );
        },
      ),
    );
  }
}

class PostAuthGate extends StatefulWidget {
  const PostAuthGate({super.key});

  @override
  State<PostAuthGate> createState() => _PostAuthGateState();
}

class _PostAuthGateState extends State<PostAuthGate> {
  bool _acceptedThisLogin = false;

  @override
  Widget build(BuildContext context) {
    // If Firebase isn't configured for the current platform, continue into app.
    if (!FirebaseBootstrap.isReady) {
      return const AppShell();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    if (!_acceptedThisLogin) {
      return TermsSigningScreen(
        showBack: true,
        onAccepted: () {
          if (!mounted) return;
          setState(() => _acceptedThisLogin = true);
        },
      );
    }

    return const ProfileCompletionGate();
  }
}

class ProfileCompletionGate extends StatelessWidget {
  const ProfileCompletionGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase isn't configured for the current platform, continue into app.
    if (!FirebaseBootstrap.isReady) {
      return const AppShell();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    final docStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return const AppShell();
        }

        final data = snapshot.data?.data();
        final completed = data?['profileCompleted'] == true;
        final fullName = (data?['fullName'] ?? data?['name'] ?? '').toString().trim();

        if (!completed || fullName.isEmpty) {
          return const ProfileSetupScreen(allowBack: false);
        }

        return const AppShell();
      },
    );
  }
}

class HomeController extends StatefulWidget {
  const HomeController({Key? key}) : super(key: key);

  @override
  State<HomeController> createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  bool _loading = true;
  bool _seenOnboarding = false;
  bool _guestMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenOnboarding') ?? false;
    final guest = prefs.getBool('guestMode') ?? false;
    if (!mounted) return;
    setState(() {
      _seenOnboarding = seen;
      _guestMode = guest;
      _loading = false;
    });
  }

  void _onGetStarted() {
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);
      if (!mounted) return;
      setState(() => _seenOnboarding = true);
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_seenOnboarding) {
      return OnboardingScreen(onGetStarted: _onGetStarted);
    }

    // Guest mode bypasses authentication entirely.
    if (_guestMode) {
      return const AppShell();
    }

    // If Firebase isn't configured for the current platform, continue into app.
    if (!FirebaseBootstrap.isReady) {
      return const AppShell();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        return const PostAuthGate();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  bool _hasUnreadAlerts = false;
  String? _currentAlertSignature;

  static const String _alertsSeenKeyPrefix = 'outbreak_alerts_last_seen_sig_';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshUnreadAlertsBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadAlertsBadge();
    }
  }

  Future<void> _refreshUnreadAlertsBadge() async {
    try {
      final region = await OutbreakRegionService().getRegionCode();
      if (region == null) {
        if (!mounted) return;
        setState(() {
          _hasUnreadAlerts = false;
          _currentAlertSignature = null;
        });
        return;
      }

      final active = await OutbreakDetector().detectForRegion(regionCode: region);

      // A stable-ish signature so we can track whether the user has seen the latest
      // alert state for their region.
      final today = OutbreakDetector.todayDayUtc();
        final signature = active.isEmpty
          ? '$region:$today:none'
          : '$region:$today:${active.map((a) => '${a.clusterId}:${a.level.index}:${a.todayCount}').join('|')}';

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString('$_alertsSeenKeyPrefix$region');

      if (!mounted) return;
      setState(() {
        _currentAlertSignature = signature;
        _hasUnreadAlerts = active.isNotEmpty && signature != lastSeen;
      });
    } catch (_) {
      // Best-effort only; badge should never break navigation.
    }
  }

  Future<void> _markAlertsSeenIfAny() async {
    final region = await OutbreakRegionService().getRegionCode();
    final sig = _currentAlertSignature;
    if (region == null || sig == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_alertsSeenKeyPrefix$region', sig);
    if (!mounted) return;
    setState(() => _hasUnreadAlerts = false);
  }

  void _setIndex(int next) {
    if (_index == next) return;
    setState(() => _index = next);
    if (next == 2) {
      // Opening Notifications marks current alerts as seen.
      _markAlertsSeenIfAny();
    } else {
      // When leaving other tabs, refresh badge in background.
      _refreshUnreadAlertsBadge();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            showBottomNav: false,
            onOpenChat: () => setState(() => _index = 1),
          ),
          AppRoot(
            showBackButton: false,
            onOpenProfile: () => setState(() => _index = 3),
          ),
          const NotificationsScreen(),
          const ProfileSettingsScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 80,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              boxShadow: const [BoxShadow(offset: Offset(0, 16), blurRadius: 32, color: Color.fromRGBO(0, 0, 0, 0.06))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegacyNavItem(
                  selected: _index == 0,
                  selectedIcon: Icons.grid_view,
                  icon: Icons.grid_view_outlined,
                  onTap: () => _setIndex(0),
                ),
                _LegacyNavItem(
                  selected: _index == 1,
                  selectedIcon: Icons.chat_bubble,
                  icon: Icons.chat_bubble_outline,
                  onTap: () => _setIndex(1),
                ),
                _LegacyNavItem(
                  selected: _index == 2,
                  selectedIcon: Icons.notifications,
                  icon: Icons.notifications_outlined,
                  showBadge: _hasUnreadAlerts,
                  badgeBorderColor: theme.cardColor,
                  onTap: () => _setIndex(2),
                ),
                _LegacyNavItem(
                  selected: _index == 3,
                  selectedIcon: Icons.person,
                  icon: Icons.person_outline,
                  onTap: () => _setIndex(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyNavItem extends StatelessWidget {
  const _LegacyNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.showBadge = false,
    this.badgeBorderColor,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;
  final bool showBadge;
  final Color? badgeBorderColor;

  Widget _iconWithBadge(IconData data, {Color? color}) {
    final border = badgeBorderColor;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(data, color: color),
        if (showBadge)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                border: Border.all(color: border ?? Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (selected) {
      final bg = isDark ? Colors.white : Colors.black;
      final fg = isDark ? Colors.black : Colors.white;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Center(child: _iconWithBadge(selectedIcon, color: fg)),
        ),
      );
    }

    return IconButton(icon: _iconWithBadge(icon), onPressed: onTap);
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.showBackButton = true,
    this.onOpenProfile,
  });

  final bool showBackButton;
  final VoidCallback? onOpenProfile;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final TextEditingController _controller = TextEditingController();
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final translator = GoogleTranslator();
  final ScrollController _scrollController = ScrollController();
  final StreamController<Amplitude> _waveController = StreamController<Amplitude>.broadcast();
  final Random _rng = Random();
  Timer? _waveTimer;

  bool _listening = false;
  bool _botTyping = false;
  final Map<String, String> _langCodes = {
    'Auto': 'auto',
    'English': 'en',
    'Hindi': 'hi',
    'Tamil': 'ta',
    'Bengali': 'bn',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final model = Provider.of<SymptomModel>(context, listen: false);
      await model.loadProfile();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _waveTimer?.cancel();
    _waveController.close();
    super.dispose();
  }

  void _startWave() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!_listening) return;
      if (_waveController.isClosed) return;
      _waveController.add(Amplitude(current: _rng.nextDouble() * 100, max: 100));
    });
  }

  void _stopWave() {
    _waveTimer?.cancel();
    _waveTimer = null;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (!animated) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  void _afterMessageAppended() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  Future<void> _startListening() async {
    final model = Provider.of<SymptomModel>(context, listen: false);
    bool available = await _speech.initialize();
    if (!available) {
      // On web the native speech service is not available; inform user.
      if (kIsWeb) {
        final model = Provider.of<SymptomModel>(context, listen: false);
        model.addBotMessage('Voice input is not available on Chrome in this scaffold. Please type instead.');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _listening = true);
    _startWave();
    _speech.listen((val) async {
      if (val.finalResult) {
        if (!mounted) return;
        setState(() => _listening = false);
        _stopWave();
        String text = val.recognizedWords;
        // detect language from speech locale if available, prefer selector override
        String detected = val.localeId ?? '';
        String detectedCode = detected.contains('_') ? detected.split('_').first : (detected.isNotEmpty ? detected : 'auto');
        String fromLang = model.selectedLanguage != 'auto' ? model.selectedLanguage : detectedCode;
        Translation trans;
        if (fromLang == 'auto') {
          trans = await translator.translate(text, to: 'en');
        } else {
          trans = await translator.translate(text, from: fromLang, to: 'en');
        }
        model.addUserMessage(text, language: fromLang);
        _afterMessageAppended();
        if (!mounted) return;
        setState(() => _botTyping = true);
        final res = SymptomAnalyzer.analyze(trans.text);
        var outLang = model.selectedLanguage == 'auto' ? fromLang : model.selectedLanguage;
        if (outLang == 'auto' || outLang.isEmpty) outLang = 'en';
        String botText = res.explanation;
        String ttsText = res.summary;
        if (outLang != 'en') {
          try {
            botText = (await translator.translate(res.explanation, to: outLang)).text;
            ttsText = (await translator.translate(res.summary, to: outLang)).text;
          } catch (_) {
            // If translation fails, fall back to English.
          }
        }
        model.addBotMessage(botText, result: res);

        // Privacy-first outbreak aggregation: store only (day, region3, symptom codes).
        await OutbreakAnalyticsService().reportToday(
          symptomCodes: SymptomCodes.toCodes(res.matchedKeys),
        );

        if (!mounted) return;
        setState(() => _botTyping = false);
        _afterMessageAppended();
        if (!kIsWeb) await _tts.speak(ttsText);
      }
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
    _stopWave();
  }

  Future<void> _sendText() async {
    final model = Provider.of<SymptomModel>(context, listen: false);
    if (_controller.text.trim().isEmpty) return;
    String original = _controller.text.trim();
    _controller.clear();
    model.addUserMessage(original, language: model.selectedLanguage);
    _afterMessageAppended();
    if (!mounted) return;
    setState(() => _botTyping = true);
    final fromLang = model.selectedLanguage == 'auto' ? 'auto' : model.selectedLanguage;
    final Translation trans = fromLang == 'auto'
      ? await translator.translate(original, to: 'en')
      : await translator.translate(original, from: fromLang, to: 'en');
    final res = SymptomAnalyzer.analyze(trans.text);
    final outLang = model.selectedLanguage == 'auto' ? 'en' : model.selectedLanguage;
    String botText = res.explanation;
    String ttsText = res.summary;
    if (outLang != 'en') {
      try {
        botText = (await translator.translate(res.explanation, to: outLang)).text;
        ttsText = (await translator.translate(res.summary, to: outLang)).text;
      } catch (_) {
        // If translation fails, fall back to English.
      }
    }
    model.addBotMessage(botText, result: res);

    // Privacy-first outbreak aggregation: store only (day, region3, symptom codes).
    await OutbreakAnalyticsService().reportToday(
      symptomCodes: SymptomCodes.toCodes(res.matchedKeys),
    );

    if (!mounted) return;
    setState(() => _botTyping = false);
    _afterMessageAppended();
    if (!kIsWeb) await _tts.speak(ttsText);
  }

  Future<void> _sendQuickPrompt(String prompt) async {
    _controller.text = prompt;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    await _sendText();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<SymptomModel>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final surface = theme.brightness == Brightness.dark ? const Color(0xFF1E2430) : const Color(0xFFE8EEF3);
    final primary = const Color(0xFF1D81C9);
    final textDark = theme.brightness == Brightness.dark ? const Color(0xFFF8FAFB) : const Color(0xFF0E151B);
    final muted = const Color(0xFF507895);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF131720) : const Color(0xFFF9FAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back_ios_new),
                      ),
                    )
                  else
                    const SizedBox(width: 40, height: 40),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white, width: 2),
                        ),
                        child: const ClipOval(
                          child: Icon(Icons.support_agent, size: 22),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF131720) : Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.chatHeaderTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          l10n.chatHeaderStatusOnline,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final picked = await showLanguagePickerSheet(
                        context,
                        currentCode: model.selectedLanguage,
                      );
                      if (picked == null || picked == model.selectedLanguage) return;
                      await model.setLanguage(picked);
                      if (!context.mounted) return;
                      await context.read<LocaleController>().setFromLanguageCode(picked);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black12.withOpacity(0.06),
                        ),
                      ),
                      child: Icon(Icons.translate, size: 18, color: muted),
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.chatToday,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: muted.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick action chips (scroll with chat so the chat area stays spacious)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickChip(
                          label: l10n.chatQuickChipCheckFever,
                          primary: primary,
                          emphasized: true,
                          onTap: () => _sendQuickPrompt(l10n.chatQuickPromptCheckFever),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: l10n.chatQuickChipWomensHealth,
                          primary: primary,
                          onTap: () => _sendQuickPrompt(l10n.chatQuickPromptWomensHealth),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: l10n.chatQuickChipFirstAid,
                          primary: primary,
                          onTap: () => _sendQuickPrompt(l10n.chatQuickPromptFirstAid),
                        ),
                        const SizedBox(width: 10),
                        _QuickChip(
                          label: l10n.chatQuickChipChildCare,
                          primary: primary,
                          onTap: () => _sendQuickPrompt(l10n.chatQuickPromptChildCare),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...model.messages.map((msg) => _ChatBubble(
                        message: msg,
                        primary: primary,
                        surface: surface,
                        textColor: textDark,
                        muted: muted,
                      )),
                  if (_listening) ...[
                    const SizedBox(height: 8),
                    _ListeningWaveBubble(
                      stream: _waveController.stream,
                      primary: primary,
                      surface: surface,
                      muted: muted,
                    ),
                  ],
                  if (_botTyping) ...[
                    const SizedBox(height: 8),
                    _TypingBubble(surface: surface, muted: muted),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black12.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.22 : 0.08),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    _RoundIconButton(
                      background: primary.withOpacity(0.12),
                      icon: _listening ? Icons.mic : Icons.mic_none,
                      iconColor: primary,
                      onTap: _listening ? _stopListening : _startListening,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: l10n.chatInputHintAskMeAnything,
                          hintStyle: TextStyle(color: muted.withOpacity(0.55), fontWeight: FontWeight.w600),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: TextStyle(color: textDark, fontWeight: FontWeight.w600),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RoundIconButton(
                      background: primary,
                      icon: Icons.send,
                      iconColor: Colors.white,
                      onTap: _sendText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _urgencyChip(Urgency u) {
    Color c;
    String label;
    switch (u) {
      case Urgency.high:
        c = Colors.red;
        label = 'High';
        break;
      case Urgency.medium:
        c = Colors.amber;
        label = 'Medium';
        break;
      default:
        c = Colors.green;
        label = 'Low';
    }
    return Chip(backgroundColor: c, label: Text(label));
  }

  // ignore: unused_element
  void _openSettingsDialog(SymptomModel model) {
    String tmp = model.selectedLanguage;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(L10n.t('profile', model.selectedLanguage)),
            content: StatefulBuilder(builder: (context, setState) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButton<String>(
                  value: tmp,
                  items: _langCodes.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
                  onChanged: (v) => setState(() => tmp = v ?? 'auto'),
                ),
              ]);
            }),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(L10n.t('save', model.selectedLanguage)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await model.setLanguage(tmp);
                  Navigator.of(context).pop();
                },
                child: Text(L10n.t('save', model.selectedLanguage)),
              )
            ],
          );
        });
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.background, required this.icon, required this.iconColor, required this.onTap});

  final Color background;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.primary, required this.onTap, this.emphasized = false});

  final String label;
  final Color primary;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: emphasized ? primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: emphasized ? primary : primary.withOpacity(0.35), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.primary, required this.surface, required this.textColor, required this.muted});

  final ChatMessage message;
  final Color primary;
  final Color surface;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final time = DateFormat('hh:mm a').format(message.createdAt);

    final bubbleColor = isUser ? primary : surface;
    final bubbleTextColor = isUser ? Colors.white : textColor;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 22),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 24,
            color: Colors.black.withOpacity(isUser ? 0.12 : 0.06),
          )
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.30, color: bubbleTextColor),
      ),
    );

    final timeRow = isUser
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
              const SizedBox(width: 4),
              Icon(Icons.done_all, size: 16, color: primary),
            ],
          )
        : Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: muted));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_outlined, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                bubble,
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: timeRow,
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: Colors.black12.withOpacity(0.06))),
              child: const Icon(Icons.person_outline, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.surface, required this.muted});

  final Color surface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy_outlined, size: 18),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(color: muted),
              const SizedBox(width: 6),
              _Dot(color: muted, delayMs: 160),
              const SizedBox(width: 6),
              _Dot(color: muted, delayMs: 320),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListeningWaveBubble extends StatelessWidget {
  const _ListeningWaveBubble({required this.stream, required this.primary, required this.surface, required this.muted});

  final Stream<Amplitude> stream;
  final Color primary;
  final Color surface;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                  color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 18, color: primary),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Listening…',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: muted),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 26,
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColoredBox(
                          color: surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimatedWaveList(stream: stream),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: Colors.black12.withOpacity(0.06))),
          child: const Icon(Icons.person_outline, size: 18),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, this.delayMs = 0});

  final Color color;
  final int delayMs;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Animation<double> _anim = Tween<double>(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

