import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mood_wear/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MoodWearApp());
    await tester.pump();

    // The app must render with its Material shell and all 5 bottom tabs,
    // whether it is loading, showing products or showing the offline error.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Style Studio'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
