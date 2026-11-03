import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotteryscan/main.dart';

void main() {
  testWidgets('app starts and shows one blank screen', (tester) async {
    await tester.pumpWidget(const LotteryScanApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
