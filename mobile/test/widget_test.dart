import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:engivault_mobile/app/app.dart';

void main() {
  testWidgets('EngivaultApp initializes smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EngivaultApp(),
      ),
    );
    expect(find.byType(EngivaultApp), findsOneWidget);

    // Allow splash timer (900ms) to elapse
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpWidget(Container());
  });
}
