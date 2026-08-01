import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_video_generator/config/theme.dart';

void main() {
  testWidgets('App theme builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
