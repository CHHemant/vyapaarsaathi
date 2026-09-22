import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VyapaarSaathi renders successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('VyapaarSaathi'),
        ),
      ),
    );

    expect(find.text('VyapaarSaathi'), findsOneWidget);
  });
}
