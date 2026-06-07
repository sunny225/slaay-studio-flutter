import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clothing_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:clothing_app/features/auth/providers/auth_provider.dart';
import 'package:clothing_app/features/auth/screens/splash_screen.dart';

// Mock classes
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
  testWidgets('App smoke test - shows onboarding', (WidgetTester tester) async {
    // Set SharedPreferences mock to skip onboarding during the smoke test
    SharedPreferences.setMockInitialValues({'completed_onboarding': true});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('completed_onboarding', true);
    
    // Run the test inside the HttpOverrides zone
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(const SlaayApp());
      // Pump frames until SharedPreferences completes initializing in AuthProvider
      final element = tester.element(find.byType(SplashScreen));
      final auth = Provider.of<AuthProvider>(element, listen: false);
      while (!auth.completedOnboarding) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Pump frames incrementally until navigation is performed and SplashScreen is popped/removed
      while (tester.any(find.byType(SplashScreen))) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Pump one final frame to allow home screen layout to build
      await tester.pump();

      // Verify that MainNavigationWrapper loads with HomeScreen showing welcome header
      expect(find.text('Hello, Welcome 👋'), findsOneWidget);
    }, createHttpClient: (context) => MockHttpClient());
  });
}
