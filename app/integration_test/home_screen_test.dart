import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lotteryscan/main.dart' as app;

import '../test/helpers/home_screen_checks.dart';

// Integration tests for ticket #4: the real app, started the way the phone
// starts it, on the Pixel_10 emulator with its real screen and fonts.

Future<void> _openApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('1. opening Dò Vé Số on Pixel_10 shows the home screen, '
      'not a blank screen', (tester) async {
    await _openApp(tester);

    expectHomeScreenTexts();
  });

  testWidgets('2. on Pixel_10 the home screen shows the sketch 1 texts '
      'with every accent and no text cut off', (tester) async {
    await _openApp(tester);

    expectHomeScreenTexts();
    expectNoTextCutOff(tester);
  });
}
