import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our initial state is correct.
    expect(find.text('No image selected.'), findsOneWidget);
    expect(find.text('Pick Receipt/Screenshot'), findsOneWidget);
  });
}
