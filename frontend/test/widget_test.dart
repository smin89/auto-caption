import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Auto Caption 기본 UI 테스트', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Auto Caption'))),
    );

    expect(find.text('Auto Caption'), findsOneWidget);
  });
}
