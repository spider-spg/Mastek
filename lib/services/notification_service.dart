import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap.dart';

class NotificationService {
  static const String _prefsKey = 'settings.notificationsEnabled';
  static const String _channelId = 'medimitra_general';
  static const String _channelName = 'MediMitra Notifications';
  static const String _channelDescription = 'General notifications and alerts';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (kIsWeb) return;

    // If Firebase isn't configured on this platform, just persist the setting.
    if (!FirebaseBootstrap.isReady) return;

    await _ensureInitialized();

    await FirebaseMessaging.instance.setAutoInitEnabled(enabled);

    if (!enabled) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        await FirebaseMessaging.instance.deleteToken();
        await _removeTokenFromUser(token);
      } catch (e) {
        debugPrint('NotificationService: disable failed: $e');
      }
      return;
    }

    // Enabled: request runtime permission on Android 13+ (and iOS).
    await _requestRuntimePermission();

    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _saveTokenToUser(token);
    } catch (e) {
      debugPrint('NotificationService: token registration failed: $e');
    }
  }

  static Future<void> initOnAppStart() async {
    if (kIsWeb) return;

    // If Firebase isn't configured on this platform, do nothing.
    if (!FirebaseBootstrap.isReady) return;

    final enabled = await getEnabled();
    await FirebaseMessaging.instance.setAutoInitEnabled(enabled);

    if (!enabled) return;

    await _ensureInitialized();
    await _requestRuntimePermission();

    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _saveTokenToUser(token);
    } catch (e) {
      debugPrint('NotificationService: init token error: $e');
    }
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Local notifications init.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(initSettings);

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await androidPlugin.createNotificationChannel(channel);
    }

    // Foreground messages -> show local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background/terminated messages (Android primarily): register handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  static Future<void> _requestRuntimePermission() async {
    try {
      // iOS permission dialog (no-op on Android).
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // ignore
    }

    // Android 13+ permission prompt.
    try {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // ignore
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon,
      ),
    );

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  static Future<void> _saveTokenToUser(String? token) async {
    if (token == null || token.isEmpty) return;
    if (!FirebaseBootstrap.isReady) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> _removeTokenFromUser(String? token) async {
    if (token == null || token.isEmpty) return;
    if (!FirebaseBootstrap.isReady) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'fcmTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // ignore
  }
  // If you later want to show notifications here too, you can.
}
