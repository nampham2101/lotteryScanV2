import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/camera_start.dart';
import 'helpers/driven_app.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #24's "Camera won't start" items, on the
// Pixel_10 emulator. They run on the Mac and talk to the real app started from
// camera_start_app.dart, where the tests decide what ML Kit's text is, and can
// make the camera refuse or fail when it next starts. Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/camera_start_driver.dart \
//     --target=integration_test/camera_start_app.dart
//
// Each test starts from the home screen, with the camera able to start, so
// they can run one at a time. Don't touch the emulator during a run.

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(() async {
    await letCameraStart();
    await holdReads();
  });

  group('Camera won\'t start', () {
    test('Given 4d shows and camera access has been refused, when "Thử lại" '
        'is tapped, then the home screen shows with the "Cần dùng camera" '
        'pop-up', () async {
      await given4dShows();
      await givenCameraAccessRefused();

      await tapTryAgain();

      await expectHomeWithRefusedPopUp();
    }, timeout: testTimeout);

    test('Given 4d shows and camera access has been refused, when the phone\'s '
        'back button is pressed, then the home screen shows with the "Cần '
        'dùng camera" pop-up', () async {
      await given4dShows();
      await givenCameraAccessRefused();

      await phone.pressBackButton();

      await expectHomeWithRefusedPopUp();
    }, timeout: testTimeout);

    test('Given 4d shows and the camera fails to start for a reason other '
        'than refused access, when "Thử lại" is tapped, then the home screen '
        'shows with the note "Lỗi camera, thử lại", which fades after about '
        '3 seconds', () async {
      await given4dShows();
      await givenCameraFailsToStart();

      await tapTryAgain();

      await expectHomeWithFadingNote(isHomeTheWholeTime: false);
    }, timeout: testTimeout);

    test('Given 4d shows and the camera fails to start for a reason other '
        'than refused access, when the phone\'s back button is pressed, then '
        'the home screen shows with the note "Lỗi camera, thử lại", which '
        'fades after about 3 seconds', () async {
      await given4dShows();
      await givenCameraFailsToStart();

      await phone.pressBackButton();

      await expectHomeWithFadingNote(isHomeTheWholeTime: false);
    }, timeout: testTimeout);

    test('Given the home screen shows and the camera fails to start for a '
        'reason other than refused access, when "Quét vé" is tapped, then '
        'the home screen stays and shows the note "Lỗi camera, thử lại", '
        'which fades after about 3 seconds', () async {
      await givenHomeScreenWithCameraAllowed();
      await givenCameraFailsToStart();

      await tapScanButton();

      await expectHomeWithFadingNote(isHomeTheWholeTime: true);
    }, timeout: testTimeout);
  });
}
