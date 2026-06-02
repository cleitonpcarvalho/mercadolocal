import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Mercado Local'))),
    );

    expect(find.text('Mercado Local'), findsOneWidget);
  });
}
