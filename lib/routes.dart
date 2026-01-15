import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection.dart';
import 'screens/auth_phone.dart';
import 'screens/auth_otp.dart';
import 'screens/guest_mode.dart';
import 'screens/checkup_for.dart';
import 'screens/profile_create_edit.dart';
import 'screens/personal_info.dart';
import 'screens/main_chat_hologram.dart';
import 'screens/symptom_details.dart';
import 'screens/result_screen.dart';
import 'screens/profile_list.dart';
import 'screens/settings.dart';

final Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
  '/': (BuildContext context) => const SplashScreen(),
  '/language': (BuildContext context) => const LanguageSelectionScreen(),
  '/authPhone': (BuildContext context) => const AuthPhoneScreen(),
  '/otp': (BuildContext context) => const AuthOtpScreen(),
  '/guest': (BuildContext context) => const GuestModeScreen(),
  '/checkupFor': (BuildContext context) => const CheckupForScreen(),
  '/profileCreateEdit': (BuildContext context) =>
      const ProfileCreateEditScreen(),
  '/personalInfo': (BuildContext context) => const PersonalInfoScreen(),
  '/chat': (BuildContext context) => const MainChatHologramScreen(),
  '/symptomDetails': (BuildContext context) => const SymptomDetailsScreen(),
  '/result': (BuildContext context) => const ResultScreen(),
  '/profileList': (BuildContext context) => const ProfileListScreen(),
  '/settings': (BuildContext context) => const SettingsScreen(),
};
