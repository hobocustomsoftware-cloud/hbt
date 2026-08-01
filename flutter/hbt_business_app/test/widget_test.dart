import 'package:flutter_test/flutter_test.dart';
import 'package:hbt_business_app/main.dart';

void main() {
  testWidgets('shows the HBT Business sign-in screen', (tester) async {
    await tester.pumpWidget(const HbtBusinessApp(restoreSession: false));
    await tester.pump();

    expect(find.text('HBT Business'), findsOneWidget);
    expect(find.text('ဝင်မည်'), findsOneWidget);
  });
}
