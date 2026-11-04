import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';

// Integration tests for ticket #10, on the Pixel_10 emulator. They run on the
// Mac, because only the Mac can read the kept photo, compare it with the screen,
// turn the emulator's camera and put two fingers on the screen. They talk to the
// real app started from camera_app.dart. Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/photo_screen_driver.dart \
//     --target=integration_test/camera_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run.

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  group('Taking the photo', () {
    test('Given the camera screen is open, when the person taps the shutter, '
        'then the photo screen shows the photo just taken, and the home '
        'screen doesn\'t show', () async {
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      await expectScreenShows(await keptPhotoSince(tappedAt));
    }, timeout: testTimeout);

    test('Given a photo was taken earlier, when the person takes another, '
        'then the photo screen shows the new photo, not the old one', () async {
      addTearDown(phone.turnCameraBack);
      final oldPhoto = await givenPhotoTakenEarlier();
      await phone.turnCamera();
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      await expectScreenShows(await keptPhotoSince(tappedAt));
      await expectScreenDoesNotShow(oldPhoto);
    }, timeout: testTimeout);
  });

  group('The photo screen', () {
    // How the whole screen looks is manual step 1.
    test('Given the photo screen is open, then the whole photo fits on the '
        'screen, the right way up', () async {
      final photo = await givenPhotoScreenOpen();

      await expectScreenShows(photo);
    }, timeout: testTimeout);

    test(
      'Given the photo screen is open, then it has no text and no buttons',
      () async {
        await givenPhotoScreenOpen();

        final screen = await appScreen();
        expect(screen.texts, isEmpty, reason: 'there must be no text');
        expect(screen.buttons, isEmpty, reason: 'there must be no buttons');
      },
      timeout: testTimeout,
    );

    test('Given the photo screen is open, when the person pinches outwards, '
        'then the photo stays the same size', () {
      return expectPinchLeavesPhotoAlone(isSpreading: true);
    }, timeout: testTimeout);

    test('Given the photo screen is open, when the person pinches inwards, '
        'then the photo stays the same size', () {
      return expectPinchLeavesPhotoAlone(isSpreading: false);
    }, timeout: testTimeout);

    test('Given the photo screen is open, when the person double-taps, '
        'then the photo stays the same size', () {
      return expectDoubleTapLeavesPhotoAlone();
    }, timeout: testTimeout);
  });

  group('Leaving', () {
    Future<void> expectBackGoesHome(Future<void> Function() goBack) async {
      await givenPhotoScreenOpen();

      await goBack();

      await expectHomeScreenShows();
      await Future<void>.delayed(settleTime);
      await expectHomeScreenShows();
    }

    test('Given the photo screen is open, when the person uses the phone\'s '
        'back button, then the home screen shows', () {
      return expectBackGoesHome(phone.pressBackButton);
    }, timeout: testTimeout);

    test('Given the photo screen is open, when the person uses the phone\'s '
        'back gesture, then the home screen shows', () {
      return expectBackGoesHome(useBackGesture);
    }, timeout: testTimeout);

    Future<void> expectCameraOpensAfterLeaving(
      Future<void> Function() goBack,
    ) async {
      await givenPhotoScreenOpen();
      await goBack();
      await expectHomeScreenShows();

      await tapScanButton();

      await expectCameraScreenOpens();
      await expectAppUsingCamera();
    }

    test('Given the person left the photo screen with the back button, when '
        'they tap "Quét vé", then the camera screen opens', () {
      return expectCameraOpensAfterLeaving(phone.pressBackButton);
    }, timeout: testTimeout);

    test('Given the person left the photo screen with the back gesture, when '
        'they tap "Quét vé", then the camera screen opens', () {
      return expectCameraOpensAfterLeaving(useBackGesture);
    }, timeout: testTimeout);

    // With a photo kept from before, so a photo screen that opens whenever the
    // camera closes is caught too.
    Future<void> expectBackFromCameraGoesHome(
      Future<void> Function() goBack,
    ) async {
      final earlierPhoto = await givenPhotoTakenEarlier();
      await givenCameraScreenOpen();

      await goBack();

      await expectHomeScreenShowsWithNoPhotoScreen(earlierPhoto);
    }

    test('Given the camera screen is open, when the person uses the phone\'s '
        'back button, then the home screen shows and no photo screen '
        'appears', () {
      return expectBackFromCameraGoesHome(phone.pressBackButton);
    }, timeout: testTimeout);

    test('Given the camera screen is open, when the person uses the phone\'s '
        'back gesture, then the home screen shows and no photo screen '
        'appears', () {
      return expectBackFromCameraGoesHome(useBackGesture);
    }, timeout: testTimeout);
  });
}
