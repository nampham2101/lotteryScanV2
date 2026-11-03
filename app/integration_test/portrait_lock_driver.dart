import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/phone.dart';

// Integration tests for ticket #5, on the Pixel_10 emulator. They run on the
// Mac, because only the Mac can turn the emulator, and talk to the real app
// started from portrait_lock_app.dart. Run them from app/ with:
//
//   fvm flutter drive -d emulator-5554 \
//     --driver=integration_test/portrait_lock_driver.dart \
//     --target=integration_test/portrait_lock_app.dart
//
// Criterion 2 runs last because it closes the app.

final phone = Phone.fromEnvironment();
FlutterDriver? driver;

const testTimeout = Timeout(Duration(minutes: 2));
const sideways = [Hold.sidewaysLeft, Hold.sidewaysRight];

/// What the app's screen shows: its size and every text with its place.
Future<Map<String, dynamic>> appScreen() async {
  await driver!.waitUntilNoTransientCallbacks();
  return jsonDecode(await driver!.requestData('screen'))
      as Map<String, dynamic>;
}

/// Makes sure the phone really is held the way the test says, so a pass
/// never comes from a turn that didn't happen.
Future<void> expectPhoneHeld(Hold hold) async {
  final [x, y] = await phone.accelerometer();
  expect(
    (x - hold.x).abs() < 0.5 && (y - hold.y).abs() < 0.5,
    isTrue,
    reason: 'SETUP: the emulator is not held ${hold.label} (reads $x:$y)',
  );
}

/// Given: the app is open on the phone, held upright, with the screen upright.
Future<void> holdUprightWithAppOpen() async {
  await phone.hold(Hold.upright);
  await expectPhoneHeld(Hold.upright);
  expect(
    await phone.isAppInFront(),
    isTrue,
    reason: 'SETUP: the app is not open: ${await phone.windowInFront()}',
  );
  expect(
    await phone.screenRotation(),
    0,
    reason: 'SETUP: the screen is not upright with the phone held upright',
  );
}

/// Then: the app is in front, the screen is upright and it didn't turn at
/// any moment since [since].
Future<void> expectScreenStayedUpright({required double since}) async {
  expect(
    await phone.isAppInFront(),
    isTrue,
    reason: 'the app is no longer in front: ${await phone.windowInFront()}',
  );
  expect(
    await phone.screenRotation(),
    0,
    reason: 'the screen turned with the phone: it is not upright',
  );
  final turns = await phone.screenTurnsSince(since);
  expect(
    turns,
    isEmpty,
    reason: 'the screen turned ${turns.length} time(s) along the way',
  );
}

/// Then, seen from inside the app: it is drawn on a tall screen, not a wide one.
Future<void> expectAppDrawnUpright() async {
  final screen = await appScreen();
  final width = screen['width'] as num;
  final height = screen['height'] as num;
  expect(
    width < height,
    isTrue,
    reason: 'the app is drawn sideways, on a $width x $height screen',
  );
}

void main() {
  bool? wasAutoRotateOn;

  setUpAll(() async {
    // With auto-rotate off no app turns, so the tests could pass without the
    // lock. Turn it on so the lock is what keeps the screen upright.
    wasAutoRotateOn = await phone.isAutoRotateOn();
    await phone.setAutoRotate(isOn: true);
    await phone.hold(Hold.upright);
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver?.close();
    await phone.hold(Hold.upright);
    if (wasAutoRotateOn != null) {
      await phone.setAutoRotate(isOn: wasAutoRotateOn!);
    }
  });

  group('1. Stays upright when turned sideways', () {
    for (final side in sideways) {
      test('with the app open, turning the phone ${side.label} '
          'keeps the screen upright and it does not turn', () async {
        await holdUprightWithAppOpen();
        final turnedAt = await phone.clock();

        await phone.hold(side);
        await expectPhoneHeld(side);

        await expectScreenStayedUpright(since: turnedAt);
        await expectAppDrawnUpright();
      }, timeout: testTimeout);
    }
  });

  group('3. Turning back is normal', () {
    for (final side in sideways) {
      test('after turning the phone ${side.label} with the app open, '
          'turning it back upright leaves the screen upright '
          'with nothing changed', () async {
        await holdUprightWithAppOpen();
        final screenBefore = await appScreen();
        final turnedAt = await phone.clock();
        await phone.hold(side);
        await expectPhoneHeld(side);

        await phone.hold(Hold.upright);
        await expectPhoneHeld(Hold.upright);

        await expectScreenStayedUpright(since: turnedAt);
        await expectAppDrawnUpright();
        expect(
          await appScreen(),
          screenBefore,
          reason: 'what the screen shows changed after turning back',
        );
      }, timeout: testTimeout);
    }
  });

  group('2. Opens upright when the phone is already sideways', () {
    for (final side in sideways) {
      test('with the phone held ${side.label} and the app closed, '
          'opening Dò Vé Số opens it upright', () async {
        await driver?.close();
        driver = null;
        await phone.closeApp();
        await phone.hold(side);
        await expectPhoneHeld(side);
        expect(
          await phone.isAppRunning(),
          isFalse,
          reason: 'SETUP: the app did not close',
        );
        expect(
          await phone.screenRotation(),
          0,
          reason:
              'SETUP: the phone home screen turned sideways too, so it is '
              'not clear whether opening the app turns the screen',
        );
        final openedAt = await phone.clock();

        await phone.openApp();

        await expectPhoneHeld(side);
        await expectScreenStayedUpright(since: openedAt);
      }, timeout: testTimeout);
    }
  });
}
