import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/refused_camera.dart';

// Integration test for ticket #9, on the Pixel_10 emulator: changing their mind
// after one refusal. It needs its own fresh install, because the story in
// camera_refused_driver.dart ends refused for good, and Android closes the app
// when access is taken back. Run it from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   adb -s "$ANDROID_SERIAL" uninstall com.nampham.lotteryscan
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/camera_refused_once_driver.dart \
//     --target=integration_test/camera_app.dart

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  test('Given the person refused once and later allowed the camera in the '
      'phone\'s Settings, when they tap "Quét vé", then the camera screen '
      'opens with no pop-up', () async {
    await expectFreshInstall();
    await givenAllowedInSettingsAfterThePopUp();

    await expectScanOpensCameraWithNoPopUp();
  }, timeout: testTimeout);
}
