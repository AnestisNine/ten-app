import 'package:flutter_test/flutter_test.dart';
import 'package:tbn_manager/main.dart';

void main() {
  testWidgets('TBN Manager launches login screen', (tester) async {
    await tester.pumpWidget(const TbnManagerApp());
    expect(find.text('TBN Manager'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
