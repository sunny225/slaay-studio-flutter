import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/product/providers/product_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/home/providers/cms_provider.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/auth/screens/splash_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Make status bar and system navigation immersive and edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  ApiClient.customBaseUrl = prefs.getString('custom_backend_url');
  runApp(const SlaayApp());
}

class SlaayApp extends StatelessWidget {
  const SlaayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CmsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'SLAAY',
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to premium light cream styling, supports dark too
        home: const SplashScreen(),
      ),
    );
  }
}
