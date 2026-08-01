import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hbt_business_app/features/onboarding/company_onboarding_screen.dart';
import 'package:hbt_business_app/features/onboarding/onboarding_data.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('onboarding wizard shows step 1 (Create Company) in Myanmar',
      (tester) async {
    final session = createMockSession(authenticated: false);
    await tester.pumpWidget(
      wrapInApp(CompanyOnboardingScreen(session: session)),
    );
    await tester.pump();

    // Step 1 title (Myanmar default) + progress indicator present.
    expect(find.text('ကုမ္ပဏီ ဖန်တီးရန်'), findsOneWidget);
    expect(find.text('ကုမ္ပဏီ အမည် ဖြည့်ပါ'), findsOneWidget);
    expect(find.text('ရှေ့ဆက်ရန်'), findsOneWidget);
  });

  testWidgets('onboarding step 1 requires a company name', (tester) async {
    final session = createMockSession(authenticated: false);
    await tester.pumpWidget(
      wrapInApp(CompanyOnboardingScreen(session: session)),
    );
    await tester.pump();

    // Tap next with empty name — stays on step 1.
    await tester.tap(find.text('ရှေ့ဆက်ရန်'));
    await tester.pump();
    expect(find.text('ကုမ္ပဏီ အမည် ဖြည့်ပါ'), findsOneWidget);
  });

  testWidgets('onboarding advances after entering a company name',
      (tester) async {
    final session = createMockSession(authenticated: false);
    await tester.pumpWidget(
      wrapInApp(CompanyOnboardingScreen(session: session)),
    );
    await tester.pump();

    await tester.enterText(
      find.byType(TextField).first,
      'Green Line Express',
    );
    await tester.tap(find.text('ရှေ့ဆက်ရန်'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2 — Company Information.
    expect(find.text('တရားဝင် အချက်အလက်များ'), findsOneWidget);
  });

  testWidgets('onboarding data defaults are Myanmar-first', (tester) async {
    final data = OnboardingData();
    expect(data.defaultLanguage, 'my');
    expect(data.timezone, 'Asia/Yangon');
    expect(data.currency, 'MMK');
    expect(data.businessType, 'bus_operator');
  });
}
