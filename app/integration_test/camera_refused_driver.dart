import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/refused_camera.dart';

// Integration tests for ticket #9, on the Pixel_10 emulator. They run on the
// Mac, because only the Mac can answer Android's question and use the phone's
// Settings. They talk to the real app started from camera_app.dart. "Android
// is asking" needs a fresh install, so run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   adb -s "$ANDROID_SERIAL" uninstall com.nampham.lotteryscan
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/camera_refused_driver.dart \
//     --target=integration_test/camera_app.dart
//
// The tests are one story, in order: refusing can't be undone during a run,
// because Android closes the app when access is taken back. So run the whole
// file, not one test. Don't touch the emulator during the run.

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  group('Refusing access', () {
    test('Given Android is asking for camera access, when the person refuses, '
        'then the pop-up appears on the home screen and the camera screen '
        'doesn\'t open', () async {
      await expectFreshInstall();
      await givenHomeScreen();
      await tapScanButton();
      await expectAndroidAsks();

      await refuseAndroidQuestion();

      await expectPopUpAppears();
      await Future<void>.delayed(settleTime);
      expect(
        await isCameraScreenShowing(),
        isFalse,
        reason: 'the camera screen opened',
      );
      expect(
        await isPopUpShowing(),
        isTrue,
        reason: 'the pop-up did not stay on screen',
      );
    }, timeout: testTimeout);
  });

  group('The pop-up', () {
    test('Given the pop-up shows, then it reads "Cần dùng camera / Ứng dụng '
        'cần camera để chụp vé. Bạn hãy cho phép dùng camera trong phần Cài '
        'đặt của điện thoại." with an "Đóng" button', () async {
      await givenPopUpShows();

      await expectPopUpWords();
    }, timeout: testTimeout);

    test('Given the pop-up shows, when the person taps "Đóng", '
        'then it closes and the home screen shows', () async {
      await givenPopUpShows();

      await tapCloseButton();

      await expectPopUpClosedOnHomeScreen();
    }, timeout: testTimeout);
  });

  group('Refused for good', () {
    test('Given the person has refused for good, when they tap "Quét vé", '
        'then the same pop-up appears, with no Android question', () async {
      await givenRefusedForGood();

      await tapScanButton();

      final seen = await watchAfterTap(isPopUpShowing);
      expect(seen.wasAsked, isFalse, reason: 'Android asked a question');
      expect(seen.sawPopUp, isTrue, reason: 'the pop-up did not appear');
      await expectPopUpWords();
      expect(
        await isCameraScreenShowing(),
        isFalse,
        reason: 'the camera screen opened',
      );
    }, timeout: testTimeout);
  });

  group('Changing their mind', () {
    test('Given the person refused for good and later allowed the camera in '
        'the phone\'s Settings, when they tap "Quét vé", then the camera '
        'screen opens with no pop-up', () async {
      await givenRefusedForGood();
      await givenAllowedInSettingsAfterThePopUp();

      await expectScanOpensCameraWithNoPopUp();
    }, timeout: testTimeout);
  });
}
