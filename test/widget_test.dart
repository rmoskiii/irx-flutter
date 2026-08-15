import 'package:flutter_test/flutter_test.dart';

import 'package:irl_app/main.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IrlApp());

    expect(find.text('IRX'), findsOneWidget);
    expect(find.text('Interactive Reality Xperience'), findsOneWidget);
    expect(find.text('SAVVY'), findsOneWidget);
    expect(find.text('INTEGRITY'), findsOneWidget);
    expect(find.text('STREET SMARTS'), findsOneWidget);
  });
}
