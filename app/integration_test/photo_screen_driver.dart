import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #10, changed by tickets #18, #24 and #31, on the
// Pixel_10 emulator. They run on the Mac, because only the Mac can read the kept
// photo, compare it with the screen, turn the emulator's camera and put two
// fingers on the screen. They talk to the real app started from
// ticket_text_app.dart, where the tests decide what ML Kit reads: since ticket
// #24, a photo of the emulator's room would open screen 4d, which has no photo.
// Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/photo_screen_driver.dart \
//     --target=integration_test/ticket_text_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run.
//
// Ticket #31 removed the photo screen: the shutter opens sketch 3, then a full
// answer screen, and no screen shows the photo. The tests of the photo screen
// itself (the photo shown, the new photo shown, no buttons, pinching,
// double-tapping, and back going home from it) are gone. Sketch 3 and back
// from the answer screens are tested in answer_screens_driver.dart. What's
// left is leaving an answer screen, and leaving the camera with a photo kept
// from before.

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(holdReads);

  group('Leaving', () {
    Future<void> expectCameraOpensAfterLeaving(
      Future<void> Function() goBack,
    ) async {
      await givenAnswerScreenOpen();
      await goBack();
      await expectHomeScreenShows();

      await tapScanButton();

      await expectCameraScreenOpens();
      await expectAppUsingCamera();
    }

    test('Given the person left the answer screen with the back button, when '
        'they tap "Quét vé", then the camera screen opens', () {
      return expectCameraOpensAfterLeaving(phone.pressBackButton);
    }, timeout: testTimeout);

    test('Given the person left the answer screen with the back gesture, when '
        'they tap "Quét vé", then the camera screen opens', () {
      return expectCameraOpensAfterLeaving(useBackGesture);
    }, timeout: testTimeout);

    // With a photo kept from before, so a screen of that scan that opens
    // whenever the camera closes is caught too.
    Future<void> expectBackFromCameraGoesHome(
      Future<void> Function() goBack,
    ) async {
      await givenPhotoTakenEarlier();
      await givenCameraScreenOpen();

      await goBack();

      await expectHomeScreenShowsWithNoScanScreen();
    }

    test('Given the camera screen is open, when the person uses the phone\'s '
        'back button, then the home screen shows and no screen of the earlier '
        'scan appears', () {
      return expectBackFromCameraGoesHome(phone.pressBackButton);
    }, timeout: testTimeout);

    test('Given the camera screen is open, when the person uses the phone\'s '
        'back gesture, then the home screen shows and no screen of the earlier '
        'scan appears', () {
      return expectBackFromCameraGoesHome(useBackGesture);
    }, timeout: testTimeout);
  });
}
