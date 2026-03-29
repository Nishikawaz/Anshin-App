import 'package:flutter_test/flutter_test.dart';

import 'package:anshin_flutter/main.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const AnshinApp());
    expect(find.byType(AnshinApp), findsOneWidget);
  });
}
