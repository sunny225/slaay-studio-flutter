import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../features/notification/providers/notification_provider.dart';
import '../features/product/providers/product_provider.dart';
import '../features/home/screens/main_navigation_wrapper.dart';
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String _fcmToken = 'SIMULATOR_TOKEN_12345_DEFAULT';
  http.Client? _sseClient;

  String get fcmToken => _fcmToken;

  // Global navigator key to access context for deep-linking
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Initialize Local Notifications
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationClick(response.payload);
        },
      );
    } catch (e) {
      debugPrint('Local notifications initialization failed: $e. Operating in test or simulated environment.');
    }

    // 2. Initialize Firebase Core & FCM safely (handles missing config files)
    try {
      await Firebase.initializeApp();
      
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request FCM permissions for iOS
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get Token
      final token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        debugPrint('FCM Token successfully fetched: $_fcmToken');
        registerTokenWithBackend(_fcmToken);
      }

      // Save FCM token to preferences for display in Merchant Dashboard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_fcm_token', _fcmToken);

      // Listen to token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        prefs.setString('device_fcm_token', newToken);
      });

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM message received in foreground: ${message.notification?.title}');
        _handleIncomingPush(
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? '',
          payloadType: message.data['type'] ?? 'promo',
        );
      });

      // Background Message Open Click Handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background via FCM: ${message.data['type']}');
        _handleNotificationClick(message.data['type']);
      });

      // Start the Server-Sent Events real-time notification listener
      _startSSEConnection();

    } catch (e) {
      debugPrint('Firebase Core/FCM missing configurations or failing: $e. Operating in Local Simulation mode.');
      // Create mock token in SharedPreferences for Dashboard fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_fcm_token', _fcmToken);
      
      // Start the Server-Sent Events real-time notification listener in mock/simulated mode
      _startSSEConnection();
    }
  }

  // Handle push details (save to provider and trigger system heads-up local push)
  void _handleIncomingPush({
    required String title,
    required String body,
    required String payloadType,
  }) {
    // Get Provider from context without using BuildContext directly to support background updates
    // In actual app runtime, we look up via navigatorKey
    final context = navigatorKey.currentContext;
    if (context != null) {
      Provider.of<NotificationProvider>(context, listen: false).addNotification(
        title: title,
        body: body,
        type: payloadType,
      );
    }

    // Trigger local push notification bubble
    _showHeadsUpLocalNotification(
      title: title,
      body: body,
      payload: payloadType,
    );
  }

  // Render OS native notification alert banner
  Future<void> _showHeadsUpLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for vital storefront updates.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Deep-link matching and navigation
  void _handleNotificationClick(String? payload) {
    if (payload == null || payload.isEmpty) return;
    
    debugPrint('Executing deep link action for payload: $payload');
    
    // Use navigatorKey context to navigate to target pages
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (payload) {
      case 'abandoned_cart':
        // Navigate to Cart Tab (Index 3)
        MainNavigationWrapper.activeTabNotifier.value = 3;
        break;
      case 'new_drop':
        // Navigate to New Drops Tab (Index 2)
        MainNavigationWrapper.activeTabNotifier.value = 2;
        break;
      case 'payment':
      case 'order_update':
        // Navigate to Profile Tab (Index 4)
        MainNavigationWrapper.activeTabNotifier.value = 4;
        break;
      default:
        // Default: Open Notifications screen or do nothing
        break;
    }
  }

  // Simulate push notification trigger from Merchant Dashboard panel
  Future<void> triggerSimulatedNotification({
    required String title,
    required String body,
    required String type,
    int delaySeconds = 0,
  }) async {
    if (delaySeconds > 0) {
      Future.delayed(Duration(seconds: delaySeconds), () {
        _handleIncomingPush(title: title, body: body, payloadType: type);
      });
    } else {
      _handleIncomingPush(title: title, body: body, payloadType: type);
    }
  }

  // Registers the FCM device token with the Node/Express backend database.
  Future<void> registerTokenWithBackend(String token) async {
    try {
      final res = await ApiClient.post('/auth/register-fcm-token', {
        'token': token,
        'deviceType': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'),
      });
      debugPrint('FCM token registered on backend: ${res.statusCode}');
    } catch (e) {
      debugPrint('Error registering FCM token on backend: $e');
    }
  }

  // Persistent HTTP Server-Sent Events stream connection to receive notifications from the backend console.
  Future<void> _startSSEConnection() async {
    if (_sseClient != null) {
      debugPrint('[SSE] Connection already active. Skipping duplicate startup request.');
      return;
    }

    final token = _fcmToken;
    final urlStr = '${ApiClient.baseUrl}/auth/notifications/stream?token=$token';
    debugPrint('[SSE] Connecting to notification stream at: $urlStr');

    try {
      final client = http.Client();
      _sseClient = client;

      final request = http.Request('GET', Uri.parse(urlStr));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['x-storefront-access-key'] = 'slaay_sf_sandbox_active_license_key_2026';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await client.send(request);
      final contentType = response.headers['content-type'] ?? '';

      if (response.statusCode == 200 && contentType.contains('text/event-stream')) {
        debugPrint('[SSE] Connected to notifications stream successfully. Content-Type: $contentType');

        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          debugPrint('[SSE] Raw line received: "$line"');
          if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            try {
              final payload = jsonDecode(dataStr);
              debugPrint('[SSE] Received notification push event: $payload');
              
              if (payload['type'] == 'inventory_sync') {
                final productId = payload['productId']?.toString();
                final stock = payload['stock'] as int?;
                final variations = payload['variations'] as List<dynamic>?;
                if (productId != null && stock != null) {
                  final context = navigatorKey.currentContext;
                  if (context != null) {
                    // ignore: use_build_context_synchronously
                    Provider.of<ProductProvider>(context, listen: false)
                        .updateProductStock(productId, stock, variations);
                  }
                }
                return;
              }
              
              if (payload['status'] == 'connected' || payload['title'] == null) {
                debugPrint('[SSE] Handshake status received. Skipping notification dispatch.');
                return;
              }
              
              _handleIncomingPush(
                title: payload['title'] ?? 'Notification',
                body: payload['body'] ?? '',
                payloadType: payload['type'] ?? 'promo',
              );
            } catch (e) {
              debugPrint('[SSE] Error decoding push data JSON: $e');
            }
          }
        }, onError: (err) {
          debugPrint('[SSE] Stream error: $err. Reconnecting in 5 seconds...');
          client.close();
          if (_sseClient == client) _sseClient = null;
          Future.delayed(const Duration(seconds: 5), _startSSEConnection);
        }, onDone: () {
          debugPrint('[SSE] Stream connection closed. Reconnecting in 5 seconds...');
          client.close();
          if (_sseClient == client) _sseClient = null;
          Future.delayed(const Duration(seconds: 5), _startSSEConnection);
        });
      } else {
        debugPrint('[SSE] Connection failed or invalid content type. Status: ${response.statusCode}, Content-Type: $contentType. Retrying in 5 seconds...');
        client.close();
        if (_sseClient == client) _sseClient = null;
        Future.delayed(const Duration(seconds: 5), _startSSEConnection);
      }
    } catch (e) {
      debugPrint('[SSE] Error establishing connection: $e. Retrying in 5 seconds...');
      _sseClient = null;
      Future.delayed(const Duration(seconds: 5), _startSSEConnection);
    }
  }
}
