import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/shared/services/api_client.dart';
import 'package:hbt_business_app/features/auth/screens/sign_in_screen.dart';
import 'package:hbt_business_app/core/widgets/app_button.dart';
import 'package:hbt_business_app/features/auth/controllers/session_controller.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SignInScreen', () {
    testWidgets('renders form fields and BusyButton', (tester) async {
      final session = createMockSession(authenticated: false);
      await tester.pumpWidget(
        wrapInApp(SignInScreen(session: session)),
      );
      await tester.pump();

      expect(find.text('HBT Business'), findsOneWidget);
      expect(find.text('ဝင်မည်'), findsOneWidget);
      expect(find.byType(BusyButton), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('submitting shows BusyButton spinner', (tester) async {
      final session = createMockSession(authenticated: false);
      // Replace api with one that never completes
      final delayedApi = _DelayedApi();
      // We need a new session with the delayed API
      final storage = MockStorage();
      final delayedSession = SessionController(api: delayedApi, storage: storage);
      delayedSession.loading = false;
      delayedSession.authenticated = false;

      await tester.pumpWidget(
        wrapInApp(SignInScreen(session: delayedSession)),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        '0912345678',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'secret123',
      );

      await tester.tap(find.text('ဝင်မည်'));
      await tester.pump();

      final busyButton = tester.widget<BusyButton>(find.byType(BusyButton));
      expect(busyButton.busy, isTrue);
    });

    testWidgets('shows error snackbar on failed sign-in', (tester) async {
      final failingApi = _FailingApi();
      final storage = MockStorage();
      final session = SessionController(api: failingApi, storage: storage);
      session.loading = false;
      session.authenticated = false;

      await tester.pumpWidget(
        wrapInApp(SignInScreen(session: session)),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        '0912345678',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrong',
      );

      await tester.tap(find.text('ဝင်မည်'));
      await tester.pumpAndSettle();

      expect(find.text('Login failed'), findsOneWidget);
    });

    testWidgets('validation prevents empty submission', (tester) async {
      final session = createMockSession(authenticated: false);

      await tester.pumpWidget(
        wrapInApp(SignInScreen(session: session)),
      );
      await tester.pump();

      await tester.tap(find.text('ဝင်မည်'));
      await tester.pump();

      final busyButton = tester.widget<BusyButton>(find.byType(BusyButton));
      expect(busyButton.busy, isFalse);
    });
  });
}

class _DelayedApi extends ApiClient {
  _DelayedApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    // Never completes — no timer created, so no test-framework timer leak
    return Completer<Map<String, dynamic>>().future;
  }
}

class _FailingApi extends ApiClient {
  _FailingApi() : super(baseUrl: 'https://test.example.com');

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    throw ApiException('Login failed');
  }
}
