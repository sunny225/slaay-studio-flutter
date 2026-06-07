import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clothing_app/features/home/screens/home_screen.dart';
import 'package:clothing_app/features/product/providers/product_provider.dart';
import 'package:clothing_app/features/cart/providers/cart_provider.dart';
import 'package:clothing_app/features/auth/providers/auth_provider.dart';
import 'package:clothing_app/features/home/providers/cms_provider.dart';
import 'package:clothing_app/features/notification/providers/notification_provider.dart';

// Mock Http Client for network images
class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl ||
        invocation.memberName == #openUrl ||
        invocation.memberName == #get ||
        invocation.memberName == #open) {
      return Future.value(MockHttpClientRequest());
    }
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  static const List<int> _transparentPixel = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0,
    0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84, 120,
    156, 99, 98, 0, 0, 0, 2, 0, 1, 230, 217, 10, 24, 0, 0, 0, 0, 73, 69, 78, 68,
    174, 66, 96, 130
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPixel.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPixel]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #compressionState) {
      return HttpClientResponseCompressionState.notCompressed;
    }
    return null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen Hero Slider tests - render, scroll, tap CTAs', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      // Build the HomeScreen inside MultiProvider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => CmsProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Let the providers populate empty states/loading
      await tester.pump();

      // Check if welcome header exists
      expect(find.text('Hello, Welcome 👋'), findsOneWidget);

      // Verify Festive Edit slide text exists (first slide)
      expect(find.text('FESTIVE EDIT'), findsOneWidget);
      expect(find.text('The Premium\nChanderi Story'), findsOneWidget);
      expect(find.text('EXPLORE EDIT'), findsOneWidget);

      // Verify there are three dot page indicators by index structure
      // Tap on the CTA button of first slide
      await tester.tap(find.text('EXPLORE EDIT'));
      await tester.pump();

      // Verify that tapping on CTA button triggers snackbar
      expect(find.text('Switched to Anarkalis Edit'), findsOneWidget);

      // Transition to page 1 via controller
      final PageView pageView = tester.widget(find.byType(PageView));
      pageView.controller!.jumpToPage(1);
      
      // Settle layout transitions without triggering the 4-second autoplay timer
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verify that after swipe, second slide 'ROYAL SILKS' is visible
      expect(find.text('ROYAL SILKS'), findsOneWidget);
      expect(find.text('Heritage Silk\nCollection'), findsOneWidget);
      expect(find.text('VIEW HERITAGE'), findsOneWidget);

      // Tap on second CTA
      await tester.tap(find.text('VIEW HERITAGE'));
      
      // Pump enough time for the previous snackbar to clear and the new snackbar to animate in
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      expect(find.text('Switched to Sarees Edit'), findsOneWidget);

    }, createHttpClient: (context) => MockHttpClient());
  });
}
