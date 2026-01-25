import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MediMitra'**
  String get appTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Simple healthcare for you and your family'**
  String get loginTagline;

  /// No description provided for @smsLogin.
  ///
  /// In en, this message translates to:
  /// **'SMS Login'**
  String get smsLogin;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Email Login'**
  String get emailLogin;

  /// No description provided for @homeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get homeHello;

  /// No description provided for @homeThere.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeThere;

  /// No description provided for @homeChatCta.
  ///
  /// In en, this message translates to:
  /// **'Discover our AI healthcare chat assistant'**
  String get homeChatCta;

  /// No description provided for @homeOurFeatures.
  ///
  /// In en, this message translates to:
  /// **'Our Features'**
  String get homeOurFeatures;

  /// No description provided for @homeHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get homeHighlights;

  /// No description provided for @homeDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get homeDisclaimerTitle;

  /// No description provided for @homeDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'MediMitra is for informational purposes only and is not medical advice. It does not replace a doctor.\nIn case of serious symptoms or any medical emergency, please visit the nearest hospital or contact emergency services immediately.'**
  String get homeDisclaimerBody;

  /// No description provided for @featureSymptomChecker.
  ///
  /// In en, this message translates to:
  /// **'Symptom Checker'**
  String get featureSymptomChecker;

  /// No description provided for @featureWomensHealth.
  ///
  /// In en, this message translates to:
  /// **'Women\'s Health awareness'**
  String get featureWomensHealth;

  /// No description provided for @featureInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get featureInsurance;

  /// No description provided for @featureAiHealthSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Health Summary'**
  String get featureAiHealthSummary;

  /// No description provided for @featureReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get featureReminders;

  /// No description provided for @featureLocateClinics.
  ///
  /// In en, this message translates to:
  /// **'Locate clinics near you'**
  String get featureLocateClinics;

  /// No description provided for @promoAiSymptomCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Symptom Check'**
  String get promoAiSymptomCheckTitle;

  /// No description provided for @promoAiSymptomCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe symptoms, get guidance in seconds.'**
  String get promoAiSymptomCheckSubtitle;

  /// No description provided for @promoVoiceWaveformTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice + Waveform'**
  String get promoVoiceWaveformTitle;

  /// No description provided for @promoVoiceWaveformSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hands-free chat with voice input support.'**
  String get promoVoiceWaveformSubtitle;

  /// No description provided for @promoProfilePersonalizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Personalization'**
  String get promoProfilePersonalizationTitle;

  /// No description provided for @promoProfilePersonalizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save age, gender, and conditions for better help.'**
  String get promoProfilePersonalizationSubtitle;

  /// No description provided for @promoNearbyClinicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Clinics'**
  String get promoNearbyClinicsTitle;

  /// No description provided for @promoNearbyClinicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find healthcare services near your location.'**
  String get promoNearbyClinicsSubtitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @supportAndInformation.
  ///
  /// In en, this message translates to:
  /// **'Support & Information'**
  String get supportAndInformation;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageYourNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage your notifications'**
  String get manageYourNotifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @couldNotUpdateNotifications.
  ///
  /// In en, this message translates to:
  /// **'Could not update notifications'**
  String get couldNotUpdateNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @toggleDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle dark theme'**
  String get toggleDarkTheme;

  /// No description provided for @helpAndFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpAndFaq;

  /// No description provided for @getHelpAndAnswers.
  ///
  /// In en, this message translates to:
  /// **'Get help and answers'**
  String get getHelpAndAnswers;

  /// No description provided for @getInTouchWithSupport.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with support'**
  String get getInTouchWithSupport;

  /// No description provided for @aboutMediMitra.
  ///
  /// In en, this message translates to:
  /// **'About MediMitra'**
  String get aboutMediMitra;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLine(Object version);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @howWeProtectYourData.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get howWeProtectYourData;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsConditionsBody.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions\n\nBy downloading and using this application, you agree to comply with and be bound by these Terms and Conditions. If you do not agree with any part of these terms, you should discontinue using the app.\n\nThis application is designed to provide health-related information and decision-support guidance only. It is not a medical diagnostic tool and does not replace consultation with a qualified doctor or healthcare professional. All information provided by the app is for educational and support purposes, and users must always seek professional medical advice for diagnosis, treatment, or emergencies.\n\nUsers are responsible for providing accurate and honest information while using the app. The guidance generated by the system depends on the inputs provided by the user, and incorrect or incomplete information may lead to inaccurate results. The app should not be used as the sole basis for making medical decisions.\n\nThis application is not intended for emergency situations. In case of severe symptoms such as chest pain, difficulty breathing, loss of consciousness, or heavy bleeding, users must immediately contact local emergency services or visit the nearest hospital.\n\nTo the maximum extent permitted by law, the developers shall not be held liable for any direct or indirect damages arising from the use of this application. Use of the app is entirely at the user’s own risk, and no guarantee is made regarding the accuracy, completeness, or reliability of the information provided.\n\nUse of this application is also governed by our Privacy Policy. By continuing to use the app, you confirm that you have read, understood, and agreed to both the Privacy Policy and these Terms and Conditions.\n\nWe reserve the right to modify or update these Terms and Conditions at any time. Any changes will be displayed within the app, and continued use of the app after such changes indicates acceptance of the updated terms.'**
  String get termsConditionsBody;

  /// No description provided for @legalAgreement.
  ///
  /// In en, this message translates to:
  /// **'Legal agreement'**
  String get legalAgreement;

  /// No description provided for @deleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get deleteData;

  /// No description provided for @deleteChatsAndSavedSettings.
  ///
  /// In en, this message translates to:
  /// **'Delete chats & saved settings'**
  String get deleteChatsAndSavedSettings;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Logout?'**
  String get logoutQuestion;

  /// No description provided for @logoutReturnToLogin.
  ///
  /// In en, this message translates to:
  /// **'You will be logged out and returned to the login screen.'**
  String get logoutReturnToLogin;

  /// No description provided for @chooseAnAction.
  ///
  /// In en, this message translates to:
  /// **'Choose an action'**
  String get chooseAnAction;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @permanentlyDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteAccount;

  /// No description provided for @deleteLocalData.
  ///
  /// In en, this message translates to:
  /// **'Delete local data'**
  String get deleteLocalData;

  /// No description provided for @deleteLocalDataOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete chats & saved settings on this device'**
  String get deleteLocalDataOnDevice;

  /// No description provided for @clearLocalDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear local data?'**
  String get clearLocalDataQuestion;

  /// No description provided for @clearLocalDataBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete locally stored app data on this device (saved settings, cached profile fields, and chat history in memory).\n\nYou may need to restart the app to see all changes applied.'**
  String get clearLocalDataBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @localDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared'**
  String get localDataCleared;

  /// No description provided for @couldNotClearLocalData.
  ///
  /// In en, this message translates to:
  /// **'Could not clear local data'**
  String get couldNotClearLocalData;

  /// No description provided for @accountDeletionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is not available on this platform'**
  String get accountDeletionNotAvailable;

  /// No description provided for @noSignedInAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No signed-in account found'**
  String get noSignedInAccountFound;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account. You will be logged out from this device.'**
  String get deleteAccountBody;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// No description provided for @pleaseLoginAgainThenDelete.
  ///
  /// In en, this message translates to:
  /// **'Please log in again, then delete your account'**
  String get pleaseLoginAgainThenDelete;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account'**
  String get couldNotDeleteAccount;

  /// No description provided for @networkSlowTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Network is slow. Please try again.'**
  String get networkSlowTryAgain;

  /// No description provided for @defaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUser;

  /// No description provided for @userIdLine.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String userIdLine(Object id);

  /// No description provided for @clinicsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Clinics Near You'**
  String get clinicsNearYou;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Re-center'**
  String get recenter;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'Results ({count})'**
  String resultsCount(Object count);

  /// No description provided for @nearbyClinics.
  ///
  /// In en, this message translates to:
  /// **'Nearby clinics'**
  String get nearbyClinics;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @unableToOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Unable to open dialer'**
  String get unableToOpenDialer;

  /// No description provided for @unableToOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Unable to open maps'**
  String get unableToOpenMaps;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @openLocationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get openLocationSettings;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable GPS.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable it from Settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send us a message and our team will reply.'**
  String get contactSubtitle;

  /// No description provided for @supportEmailLine.
  ///
  /// In en, this message translates to:
  /// **'Support email: {email}'**
  String supportEmailLine(Object email);

  /// No description provided for @typicalResponseLine.
  ///
  /// In en, this message translates to:
  /// **'Typical response: within 24 hours'**
  String get typicalResponseLine;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language set to {language}'**
  String languageSetTo(Object language);

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @yourMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number'**
  String get yourMobileNumber;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectHint.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get subjectHint;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or question'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sent! We will get back to you soon.'**
  String get sentSuccess;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @writeMoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Please write a bit more detail'**
  String get writeMoreDetail;

  /// No description provided for @couldNotOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app.'**
  String get couldNotOpenEmailApp;

  /// No description provided for @couldNotSendTryLater.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Please try again later.'**
  String get couldNotSendTryLater;

  /// No description provided for @tipNoShareOtp.
  ///
  /// In en, this message translates to:
  /// **'Tip: Don\'t share passwords or OTPs here.'**
  String get tipNoShareOtp;

  /// No description provided for @loginLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'English / हिंदी'**
  String get loginLanguageLabel;

  /// No description provided for @loginHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your health companion'**
  String get loginHeroSubtitle;

  /// No description provided for @loginMobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get loginMobileNumberLabel;

  /// No description provided for @loginMobileHint.
  ///
  /// In en, this message translates to:
  /// **'00000 00000'**
  String get loginMobileHint;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginPasswordHint;

  /// No description provided for @loginPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get loginPleaseWait;

  /// No description provided for @loginSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get loginSendOtp;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get loginContinue;

  /// No description provided for @loginSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP...'**
  String get loginSendingOtp;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOr;

  /// No description provided for @loginContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginContinueAsGuest;

  /// No description provided for @loginAgreementText.
  ///
  /// In en, this message translates to:
  /// **'By logging in, you agree to MediMitra\'s\nTerms of Service and Privacy Policy.'**
  String get loginAgreementText;

  /// No description provided for @loginUnableContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Unable to continue as guest.'**
  String get loginUnableContinueGuest;

  /// No description provided for @loginEnterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter mobile number.'**
  String get loginEnterMobileNumber;

  /// No description provided for @loginEnterValidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number.'**
  String get loginEnterValidMobileNumber;

  /// No description provided for @loginOtpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent.'**
  String get loginOtpSent;

  /// No description provided for @loginFailedSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP.'**
  String get loginFailedSendOtp;

  /// No description provided for @loginEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get loginEnterValidEmail;

  /// No description provided for @loginPasswordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginPasswordMinChars;

  /// No description provided for @loginEmailPasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Email/Password sign-in is disabled in Firebase Console.'**
  String get loginEmailPasswordDisabled;

  /// No description provided for @loginAccountExistsTryLogin.
  ///
  /// In en, this message translates to:
  /// **'Account already exists. Try logging in.'**
  String get loginAccountExistsTryLogin;

  /// No description provided for @loginWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (min 6 chars).'**
  String get loginWeakPassword;

  /// No description provided for @loginIncorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get loginIncorrectPassword;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email.'**
  String get loginInvalidEmail;

  /// No description provided for @loginLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get loginLoginFailed;

  /// No description provided for @otpVerifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Number'**
  String get otpVerifyNumber;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We have sent a 6-digit code to'**
  String get otpSentTo;

  /// No description provided for @otpHaventReceived.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t received the code?'**
  String get otpHaventReceived;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResendCode;

  /// No description provided for @otpVerifyProceed.
  ///
  /// In en, this message translates to:
  /// **'Verify & Proceed'**
  String get otpVerifyProceed;

  /// No description provided for @otpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get otpVerifying;

  /// No description provided for @otpEnter6Digit.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP.'**
  String get otpEnter6Digit;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP.'**
  String get otpInvalid;

  /// No description provided for @otpVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'OTP verification failed.'**
  String get otpVerificationFailed;

  /// No description provided for @otpFailedResend.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code.'**
  String get otpFailedResend;

  /// No description provided for @otpCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent.'**
  String get otpCodeResent;

  /// No description provided for @otpSafetyFirst.
  ///
  /// In en, this message translates to:
  /// **'SAFETY FIRST'**
  String get otpSafetyFirst;

  /// No description provided for @otpSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Securely connect to your healthcare records with MediMitra’s encryption.'**
  String get otpSafetyNote;

  /// No description provided for @communityOutbreakAlerts.
  ///
  /// In en, this message translates to:
  /// **'Community Outbreak Alerts'**
  String get communityOutbreakAlerts;

  /// No description provided for @outbreakPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Privacy-first: only aggregated symptom counts by PIN3 and day. No names, chat text, GPS, or exact timestamps.'**
  String get outbreakPrivacyNote;

  /// No description provided for @regionNotSet.
  ///
  /// In en, this message translates to:
  /// **'Region: Not set'**
  String get regionNotSet;

  /// No description provided for @regionPin3Line.
  ///
  /// In en, this message translates to:
  /// **'Region: {region} (PIN3)'**
  String regionPin3Line(Object region);

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @setAreaPin3Title.
  ///
  /// In en, this message translates to:
  /// **'Set your area (PIN3)'**
  String get setAreaPin3Title;

  /// No description provided for @setAreaPin3Body.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN code. We only store the first 3 digits (coarse region).'**
  String get setAreaPin3Body;

  /// No description provided for @pinExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 411001'**
  String get pinExampleHint;

  /// No description provided for @enterFirst3DigitsPin.
  ///
  /// In en, this message translates to:
  /// **'Enter at least first 3 digits of your PIN.'**
  String get enterFirst3DigitsPin;

  /// No description provided for @unableToSaveRegion.
  ///
  /// In en, this message translates to:
  /// **'Unable to save region.'**
  String get unableToSaveRegion;

  /// No description provided for @setPin3ToSeeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Set your PIN3 to see outbreak alerts for your area.'**
  String get setPin3ToSeeAlerts;

  /// No description provided for @noAlertsToday.
  ///
  /// In en, this message translates to:
  /// **'No alerts today for your area.'**
  String get noAlertsToday;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @outbreakLevelHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get outbreakLevelHighRisk;

  /// No description provided for @outbreakLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get outbreakLevelWarning;

  /// No description provided for @outbreakLevelWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get outbreakLevelWatch;

  /// No description provided for @outbreakLevelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get outbreakLevelNone;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @couldNotSaveConsent.
  ///
  /// In en, this message translates to:
  /// **'Could not save your consent. Please try again.'**
  String get couldNotSaveConsent;

  /// No description provided for @termsSigningTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsSigningTitle;

  /// No description provided for @termsSigningIntro.
  ///
  /// In en, this message translates to:
  /// **'Before using the symptom assessment, please accept the Terms of Service and Privacy Policy. Please note:'**
  String get termsSigningIntro;

  /// No description provided for @termsBulletNotDiagnosisTitle.
  ///
  /// In en, this message translates to:
  /// **'The result is not a diagnosis.'**
  String get termsBulletNotDiagnosisTitle;

  /// No description provided for @termsBulletNotDiagnosisBody.
  ///
  /// In en, this message translates to:
  /// **' It’s only for your information and not a qualified medical opinion.'**
  String get termsBulletNotDiagnosisBody;

  /// No description provided for @termsBulletNoEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not use it in case of an emergency.'**
  String get termsBulletNoEmergencyTitle;

  /// No description provided for @termsBulletNoEmergencyBody.
  ///
  /// In en, this message translates to:
  /// **' Call your local emergency number right away when there’s a health emergency.'**
  String get termsBulletNoEmergencyBody;

  /// No description provided for @termsBulletDataSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe.'**
  String get termsBulletDataSafeTitle;

  /// No description provided for @termsBulletDataSafeBody.
  ///
  /// In en, this message translates to:
  /// **' The information you give won’t be shared or used to identify you.'**
  String get termsBulletDataSafeBody;

  /// No description provided for @termsConsentTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get termsConsentTermsPrefix;

  /// No description provided for @termsConsentTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsConsentTermsLink;

  /// No description provided for @termsConsentTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get termsConsentTermsSuffix;

  /// No description provided for @termsConsentPrivacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree for my health information to be used for the interview. More information in the '**
  String get termsConsentPrivacyPrefix;

  /// No description provided for @termsConsentPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get termsConsentPrivacyLink;

  /// No description provided for @termsConsentPrivacySuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get termsConsentPrivacySuffix;

  /// No description provided for @quickQuestions.
  ///
  /// In en, this message translates to:
  /// **'Quick questions'**
  String get quickQuestions;

  /// No description provided for @typeAQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Type a question…'**
  String get typeAQuestionHint;

  /// No description provided for @talkToMaya.
  ///
  /// In en, this message translates to:
  /// **'Talk to Maya'**
  String get talkToMaya;

  /// No description provided for @womensHealthHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Women\'s Health Hub'**
  String get womensHealthHubTitle;

  /// No description provided for @womensHealthHubWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your health journey'**
  String get womensHealthHubWelcome;

  /// No description provided for @womensHealthHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a category to explore resources and get personalized care.'**
  String get womensHealthHubSubtitle;

  /// No description provided for @menstrualHealth.
  ///
  /// In en, this message translates to:
  /// **'Menstrual Health'**
  String get menstrualHealth;

  /// No description provided for @pregnancyAndMaternal.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy & Maternal'**
  String get pregnancyAndMaternal;

  /// No description provided for @breastHealth.
  ///
  /// In en, this message translates to:
  /// **'Breast Health'**
  String get breastHealth;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @womensHealthHubTagline.
  ///
  /// In en, this message translates to:
  /// **'MEDIMITRA WELLNESS'**
  String get womensHealthHubTagline;

  /// No description provided for @womensHealthCategoryMenstrualDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your monthly cycle, learn\nabout hygiene, and manage\nperiods with ease.'**
  String get womensHealthCategoryMenstrualDescription;

  /// No description provided for @womensHealthCategoryPregnancyDescription.
  ///
  /// In en, this message translates to:
  /// **'Expert guidance for a healthy\npregnancy, nutrition tips, and\nsafe delivery support.'**
  String get womensHealthCategoryPregnancyDescription;

  /// No description provided for @womensHealthCategoryBreastDescription.
  ///
  /// In en, this message translates to:
  /// **'Simple self-examination guides\nand awareness tips for early\ndetection and care.'**
  String get womensHealthCategoryBreastDescription;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @menstrualScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Menstrual Health'**
  String get menstrualScreenTitle;

  /// No description provided for @menstrualWhatIsMenstruationTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Menstruation?'**
  String get menstrualWhatIsMenstruationTitle;

  /// No description provided for @menstrualWhatIsMenstruationBody.
  ///
  /// In en, this message translates to:
  /// **'Menstruation is a natural, monthly process where the body sheds the lining of the uterus. It is a sign of a healthy reproductive system and a normal part of growing up.'**
  String get menstrualWhatIsMenstruationBody;

  /// No description provided for @menstrualQuote.
  ///
  /// In en, this message translates to:
  /// **'A cycle of renewal & life'**
  String get menstrualQuote;

  /// No description provided for @menstrualWhatIsNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Normal?'**
  String get menstrualWhatIsNormalTitle;

  /// No description provided for @menstrualNormalItem1.
  ///
  /// In en, this message translates to:
  /// **'Cycle lasts between 21 to 35 days'**
  String get menstrualNormalItem1;

  /// No description provided for @menstrualNormalItem2.
  ///
  /// In en, this message translates to:
  /// **'Bleeding lasts for 3 to 7 days'**
  String get menstrualNormalItem2;

  /// No description provided for @menstrualNormalItem3.
  ///
  /// In en, this message translates to:
  /// **'Mild to moderate cramping or discomfort'**
  String get menstrualNormalItem3;

  /// No description provided for @menstrualWarningSignsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning Signs'**
  String get menstrualWarningSignsTitle;

  /// No description provided for @menstrualWarningItem1.
  ///
  /// In en, this message translates to:
  /// **'Changing pads every 1–2 hours due to heavy flow'**
  String get menstrualWarningItem1;

  /// No description provided for @menstrualWarningItem2.
  ///
  /// In en, this message translates to:
  /// **'Severe pain that prevents you from daily activities'**
  String get menstrualWarningItem2;

  /// No description provided for @menstrualWarningItem3.
  ///
  /// In en, this message translates to:
  /// **'Cycles consistently shorter than 21 days or longer than 38 days'**
  String get menstrualWarningItem3;

  /// No description provided for @menstrualHygieneTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Tips'**
  String get menstrualHygieneTipsTitle;

  /// No description provided for @menstrualTipChangeRegularlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Regularly'**
  String get menstrualTipChangeRegularlyTitle;

  /// No description provided for @menstrualTipChangeRegularlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace pads every 4–6 hours'**
  String get menstrualTipChangeRegularlySubtitle;

  /// No description provided for @menstrualTipCleanHandsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean Hands'**
  String get menstrualTipCleanHandsTitle;

  /// No description provided for @menstrualTipCleanHandsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wash hands before and after'**
  String get menstrualTipCleanHandsSubtitle;

  /// No description provided for @menstrualTipStayDryTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Dry'**
  String get menstrualTipStayDryTitle;

  /// No description provided for @menstrualTipStayDrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the genital area clean and dry'**
  String get menstrualTipStayDrySubtitle;

  /// No description provided for @menstrualMythsFactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Myths & Facts'**
  String get menstrualMythsFactsTitle;

  /// No description provided for @menstrualMyth1.
  ///
  /// In en, this message translates to:
  /// **'Myth: \"You shouldn\'t exercise during your period.\"'**
  String get menstrualMyth1;

  /// No description provided for @menstrualFact1.
  ///
  /// In en, this message translates to:
  /// **'Fact: Light exercise can actually help reduce cramps and improve mood.'**
  String get menstrualFact1;

  /// No description provided for @menstrualMyth2.
  ///
  /// In en, this message translates to:
  /// **'Myth: \"Menstrual blood is \'dirty\' blood.\"'**
  String get menstrualMyth2;

  /// No description provided for @menstrualFact2.
  ///
  /// In en, this message translates to:
  /// **'Fact: It\'s just normal blood and tissue from the uterine lining.'**
  String get menstrualFact2;

  /// No description provided for @chatHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Assistant'**
  String get chatHeaderTitle;

  /// No description provided for @chatHeaderStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatHeaderStatusOnline;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get chatToday;

  /// No description provided for @chatQuickChipCheckFever.
  ///
  /// In en, this message translates to:
  /// **'🌡️ Check Fever'**
  String get chatQuickChipCheckFever;

  /// No description provided for @chatQuickPromptCheckFever.
  ///
  /// In en, this message translates to:
  /// **'I want to check fever.'**
  String get chatQuickPromptCheckFever;

  /// No description provided for @chatQuickChipWomensHealth.
  ///
  /// In en, this message translates to:
  /// **'🤰 Women\'s Health'**
  String get chatQuickChipWomensHealth;

  /// No description provided for @chatQuickPromptWomensHealth.
  ///
  /// In en, this message translates to:
  /// **'I have a women\'s health question.'**
  String get chatQuickPromptWomensHealth;

  /// No description provided for @chatQuickChipFirstAid.
  ///
  /// In en, this message translates to:
  /// **'🩹 First Aid'**
  String get chatQuickChipFirstAid;

  /// No description provided for @chatQuickPromptFirstAid.
  ///
  /// In en, this message translates to:
  /// **'I need first aid advice.'**
  String get chatQuickPromptFirstAid;

  /// No description provided for @chatQuickChipChildCare.
  ///
  /// In en, this message translates to:
  /// **'👶 Child Care'**
  String get chatQuickChipChildCare;

  /// No description provided for @chatQuickPromptChildCare.
  ///
  /// In en, this message translates to:
  /// **'I need child care guidance.'**
  String get chatQuickPromptChildCare;

  /// No description provided for @chatInputHintAskMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get chatInputHintAskMeAnything;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileTopBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileTopBarTitle;

  /// No description provided for @profileHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profileHeaderSubtitle;

  /// No description provided for @profileSectionFullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get profileSectionFullName;

  /// No description provided for @profileHintFullName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rahul Sharma'**
  String get profileHintFullName;

  /// No description provided for @profileSectionAge.
  ///
  /// In en, this message translates to:
  /// **'AGE'**
  String get profileSectionAge;

  /// No description provided for @profileHintAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get profileHintAge;

  /// No description provided for @profileSectionGender.
  ///
  /// In en, this message translates to:
  /// **'GENDER'**
  String get profileSectionGender;

  /// No description provided for @profileGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// No description provided for @profileGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOther;

  /// No description provided for @profileChronicConditions.
  ///
  /// In en, this message translates to:
  /// **'CHRONIC CONDITIONS'**
  String get profileChronicConditions;

  /// No description provided for @profileConditionsBadge.
  ///
  /// In en, this message translates to:
  /// **'BILINGUAL'**
  String get profileConditionsBadge;

  /// No description provided for @conditionDiabetesTitle.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get conditionDiabetesTitle;

  /// No description provided for @conditionDiabetesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Diabetes (Sugar)'**
  String get conditionDiabetesSubtitle;

  /// No description provided for @conditionBpHeartTitle.
  ///
  /// In en, this message translates to:
  /// **'BP & Heart'**
  String get conditionBpHeartTitle;

  /// No description provided for @conditionBpHeartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure / Heart'**
  String get conditionBpHeartSubtitle;

  /// No description provided for @conditionAsthmaTitle.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get conditionAsthmaTitle;

  /// No description provided for @conditionAsthmaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get conditionAsthmaSubtitle;

  /// No description provided for @conditionThyroidTitle.
  ///
  /// In en, this message translates to:
  /// **'Thyroid'**
  String get conditionThyroidTitle;

  /// No description provided for @conditionThyroidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thyroid'**
  String get conditionThyroidSubtitle;

  /// No description provided for @conditionTbTitle.
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get conditionTbTitle;

  /// No description provided for @conditionTbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis'**
  String get conditionTbSubtitle;

  /// No description provided for @conditionNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get conditionNoneTitle;

  /// No description provided for @conditionNoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No conditions'**
  String get conditionNoneSubtitle;

  /// No description provided for @helpFaqBotGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m MediMitra Help. Ask me anything about symptom checking, voice input, outbreak alerts, clinics, login, or privacy.\n\nNote: This is not medical advice. If you have a medical emergency, contact local emergency services.'**
  String get helpFaqBotGreeting;

  /// No description provided for @helpFaqSuggestionCheckSymptoms.
  ///
  /// In en, this message translates to:
  /// **'How do I check symptoms?'**
  String get helpFaqSuggestionCheckSymptoms;

  /// No description provided for @helpFaqSuggestionVoiceSymptoms.
  ///
  /// In en, this message translates to:
  /// **'How do voice symptoms work?'**
  String get helpFaqSuggestionVoiceSymptoms;

  /// No description provided for @helpFaqSuggestionOutbreakAlert.
  ///
  /// In en, this message translates to:
  /// **'What is outbreak alert?'**
  String get helpFaqSuggestionOutbreakAlert;

  /// No description provided for @helpFaqSuggestionNearbyClinics.
  ///
  /// In en, this message translates to:
  /// **'How to find nearby clinics?'**
  String get helpFaqSuggestionNearbyClinics;

  /// No description provided for @helpFaqSuggestionOtpLogin.
  ///
  /// In en, this message translates to:
  /// **'How does OTP login work?'**
  String get helpFaqSuggestionOtpLogin;

  /// No description provided for @helpFaqSuggestionDataSafe.
  ///
  /// In en, this message translates to:
  /// **'Is my data safe?'**
  String get helpFaqSuggestionDataSafe;

  /// No description provided for @helpFaqSuggestionGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Can I use the app without login?'**
  String get helpFaqSuggestionGuestMode;

  /// No description provided for @helpFaqSuggestionChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'How to change language?'**
  String get helpFaqSuggestionChangeLanguage;

  /// No description provided for @helpFaqSuggestionDarkMode.
  ///
  /// In en, this message translates to:
  /// **'How to enable dark mode?'**
  String get helpFaqSuggestionDarkMode;

  /// No description provided for @helpFaqReplySymptomChecking.
  ///
  /// In en, this message translates to:
  /// **'To check symptoms:\n1) Open Chat / Symptom Checker\n2) Type your symptoms (or use voice)\n3) Answer follow-up questions\n\nMediMitra will show likely causes and next steps. For severe symptoms (chest pain, trouble breathing, fainting), seek urgent care.'**
  String get helpFaqReplySymptomChecking;

  /// No description provided for @helpFaqReplyVoiceSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Voice symptoms: tap the microphone, speak your symptoms clearly, and the app converts it to text for analysis.\n\nTips: speak one symptom at a time, use simple words (\"fever\", \"cough\"), and allow microphone permission when asked.'**
  String get helpFaqReplyVoiceSymptoms;

  /// No description provided for @helpFaqReplyOutbreakAlert.
  ///
  /// In en, this message translates to:
  /// **'Outbreak alert helps you see if certain symptoms are trending in your area. It\'s based on anonymized, aggregated symptom patterns and is meant for awareness (not diagnosis).\n\nYou can view outbreak insights from the Outbreak section.'**
  String get helpFaqReplyOutbreakAlert;

  /// No description provided for @helpFaqReplyNearbyClinics.
  ///
  /// In en, this message translates to:
  /// **'Nearby clinics: open the Clinic Locator to see clinics around you.\n\nMake sure Location permission is enabled. If you prefer, you can also search by area/city (if available on your build).'**
  String get helpFaqReplyNearbyClinics;

  /// No description provided for @helpFaqReplyOtpLogin.
  ///
  /// In en, this message translates to:
  /// **'OTP login: enter your 10-digit mobile number and we send a verification OTP. Enter the 6-digit OTP to proceed.\n\nIf you don\'t receive it, wait for the resend timer and try again. Also confirm network/SMS permissions.'**
  String get helpFaqReplyOtpLogin;

  /// No description provided for @helpFaqReplyGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Guest mode lets you explore the app without signing in. Some features that save to your profile (like personalized settings) may be limited until you log in.'**
  String get helpFaqReplyGuestMode;

  /// No description provided for @helpFaqReplyPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your profile data (like name/age/gender/conditions) is stored securely for your account to personalize your experience. We do not want you to share sensitive info in chat.\n\nFor exact details, check Privacy Policy (in the app).'**
  String get helpFaqReplyPrivacy;

  /// No description provided for @helpFaqReplyChangeLanguage.
  ///
  /// In en, this message translates to:
  /// **'You can change language from Profile → Language.'**
  String get helpFaqReplyChangeLanguage;

  /// No description provided for @helpFaqReplyDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode: go to Profile → Dark Mode and toggle it on/off. Your choice is saved and works across the whole app.'**
  String get helpFaqReplyDarkMode;

  /// No description provided for @helpFaqReplyContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support: open Contact Us and send your message. Include screenshots and steps if possible.'**
  String get helpFaqReplyContactSupport;

  /// No description provided for @helpFaqReplyFallback.
  ///
  /// In en, this message translates to:
  /// **'I can help with: symptom checking, voice input, outbreak alerts, clinic locator, OTP login, privacy, language, and dark mode.\n\nTry one of these: \"How do I check symptoms?\", \"How to find nearby clinics?\", \"Is my data safe?\"'**
  String get helpFaqReplyFallback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'as',
        'bn',
        'en',
        'gu',
        'hi',
        'kn',
        'ml',
        'mr',
        'or',
        'pa',
        'ta',
        'te',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
