import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_ai_app/main.dart';

void main() {
  testWidgets('Voice AI App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceAIApp());

    // Verify that Voice AI Assistant title is shown
    expect(find.text('Voice AI Assistant'), findsOneWidget);
    
    // Verify bottom navigation
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    
    // Verify recording button exists
    expect(find.byIcon(Icons.mic), findsWidgets);
  });
}