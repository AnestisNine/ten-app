import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/main.dart';
import 'package:tbn_manager/screens/auth_screen.dart';

void main() {
  testWidgets('shows the sign-in form (no public sign-up)', (tester) async {
    await tester.pumpWidget(const TbnManagerApp(home: AuthScreen()));
    await tester.pumpAndSettle();
    expect(find.text('TBN MANAGER'), findsOneWidget);
    expect(find.text('Σύνδεση'), findsOneWidget);
    expect(find.text('Ξέχασα τον κωδικό'), findsOneWidget);
    expect(find.text('Sign up'), findsNothing);
  });
}
