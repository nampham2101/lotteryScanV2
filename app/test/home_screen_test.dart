import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotteryscan/main.dart';

import 'helpers/home_screen_checks.dart';

// Widget tests for ticket #4, one group per "Done when" criterion.

Future<void> _openApp(WidgetTester tester) async {
  // Same screen as the Pixel_10 emulator: 1080 x 2424 pixels at density 420.
  tester.view.physicalSize = const Size(1080, 2424);
  tester.view.devicePixelRatio = 420 / 160;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const LotteryScanApp());
  await tester.pumpAndSettle();
}

void main() {
  group('1. Opens to the home screen', () {
    testWidgets('the app opens to the home screen, not a blank screen', (
      tester,
    ) async {
      await _openApp(tester);

      expect(find.byType(Text), findsWidgets, reason: 'the screen is blank');
      expect(find.text(homeTitle), findsOneWidget);
    });
  });

  group('2. Shows what is in sketch 1', () {
    testWidgets('shows the title "Dò vé số"', (tester) async {
      await _openApp(tester);

      expect(find.text(homeTitle), findsOneWidget);
    });

    testWidgets('shows the line "Chụp vé để biết trúng hay không" '
        'under the title', (tester) async {
      await _openApp(tester);

      expect(find.text(homeSubtitle), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(homeSubtitle)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text(homeTitle)).dy),
        reason: 'the line must sit under the title',
      );
    });

    testWidgets('shows a "Quét vé" button under the line', (tester) async {
      final semantics = tester.ensureSemantics();
      await _openApp(tester);

      expect(find.text(scanButtonLabel), findsOneWidget);
      expect(
        tester.getSemantics(find.text(scanButtonLabel)),
        isSemantics(isButton: true),
        reason: '"$scanButtonLabel" must be a button',
      );
      expect(
        tester.getTopLeft(find.text(scanButtonLabel)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text(homeSubtitle)).dy),
        reason: 'the button must sit under the line',
      );
      semantics.dispose();
    });

    testWidgets('every Vietnamese accent is spelled correctly', (tester) async {
      await _openApp(tester);

      // find.text matches the exact characters, so a dropped or wrong
      // accent fails here. How the accents look is a manual step.
      expectHomeScreenTexts();
    });

    testWidgets('no text is cut off', (tester) async {
      await _openApp(tester);

      expectHomeScreenTexts();
      expectNoTextCutOff(tester);
    });
  });
}
