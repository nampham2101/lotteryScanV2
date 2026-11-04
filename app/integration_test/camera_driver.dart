import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/app_screen.dart';
import 'helpers/driven_app.dart';
import 'helpers/phone.dart';

// Integration tests for ticket #8, on a real phone (the Pixel 7), because the
// Pixel_10 emulator's back camera shows a still scene. They run on the Mac,
// because only the Mac can answer Android's question, look into the phone's
// gallery and use the back gesture. They talk to the real app started from
// camera_app.dart. "Has never asked" needs a fresh install, so run them from
// app/ with the phone's serial from `adb devices`:
//
//   export ANDROID_SERIAL=<serial>
//   adb uninstall com.nampham.lotteryscan
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/camera_driver.dart \
//     --target=integration_test/camera_app.dart
//
// Hold the phone in the hand so the picture moves during the run, and don't
// touch the screen: a tap by hand can answer Android's question before the
// test does.
//
// The first two tests are one story, in order: Android asks, the person allows.

/// The picture only changes when the view does, so this needs the phone held
/// in the hand during the run. A phone lying still can fail it.
Future<bool> isPictureMoving() async {
  const enoughChangedPixels = 20;
  final first = await phone.screenshot();
  for (var look = 0; look < 3; look++) {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final later = await phone.screenshot();
    if (later.changedPixels(first) >= enoughChangedPixels) return true;
  }
  return false;
}

/// The one thing on the camera screen that can be tapped.
Future<ScreenItem> findShutter() async {
  final tappable = (await appScreen()).tappable;
  expect(
    tappable,
    hasLength(1),
    reason: 'the camera screen must have the shutter and no other button',
  );
  return tappable.single;
}

/// Taps the shutter and says when, by the phone's clock.
Future<double> tapShutter() async {
  final shutter = await findShutter();
  final tappedAt = await phone.clock();
  await phone.tap(shutter.centerX.round(), shutter.centerY.round());
  return tappedAt;
}

/// Given: access is already allowed.
Future<void> givenCameraAllowed() async {
  await phone.allowCameraAccess();
  expect(
    await phone.cameraAccess(),
    CameraAccess.allowed,
    reason: 'the app does not request camera access from Android',
  );
}

/// Given: the camera screen is open, showing the moving picture, as it is when
/// a person looks at it and taps the shutter.
Future<void> givenCameraScreenOpen() async {
  await givenHomeScreen();
  await givenCameraAllowed();
  await tapScanButton();
  await expectCameraScreenOpens();
  expect(
    await waitUntil(phone.isAppUsingCamera),
    isTrue,
    reason: 'the camera screen is open but the app is not using the camera',
  );
  expect(
    await waitUntil(isPictureMoving),
    isTrue,
    reason: 'the camera screen is open but its picture is not moving',
  );
}

Future<void> takePhoto() async {
  await givenCameraScreenOpen();
  final tappedAt = await tapShutter();
  await expectHomeScreenShows();
  await expectPhotoKeptSince(tappedAt);
}

/// Then: a photo written after the shutter tap is inside the app. File times
/// are in whole seconds, so the tap time is rounded down.
Future<void> expectPhotoKeptSince(double tappedAt) async {
  var photos = <KeptPhoto>[];
  final isKept = await waitUntil(() async {
    photos = await phone.photosInsideApp();
    return photos.any((photo) => photo.modifiedAt >= tappedAt.floor());
  });
  expect(
    isKept,
    isTrue,
    reason: 'no new photo inside the app. It holds: $photos',
  );
}

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  group('First time, allowing access', () {
    test('Given the app has never asked for camera access, when the person '
        'taps "Quét vé", then Android asks for camera access', () async {
      expect(
        await phone.cameraAccess(),
        CameraAccess.neverAsked,
        reason:
            'SETUP: Android already asked this app. Uninstall it before '
            'running these tests: adb uninstall $appPackage',
      );
      await givenHomeScreen();

      await tapScanButton();

      expect(
        await waitUntil(phone.isAndroidAskingForPermission),
        isTrue,
        reason:
            'Android did not ask for camera access. In front: '
            '${await phone.windowInFront()}',
      );
      final question = await phone.permissionQuestion();
      expect(
        question?.message,
        contains('take pictures'),
        reason: 'Android asked, but not for the camera',
      );
    }, timeout: testTimeout);

    test('Given Android is asking, when the person allows it, '
        'then the camera screen opens', () async {
      final question = await phone.permissionQuestion();
      expect(
        question,
        isNotNull,
        reason:
            'Android is not asking for camera access, so there is nothing '
            'to allow. In front: ${await phone.windowInFront()}',
      );
      final behindQuestion = await appScreen();
      expect(
        behindQuestion.shows(cameraHint),
        isFalse,
        reason:
            'the camera screen is already open behind Android\'s question, '
            'so allowing is not what opens it',
      );
      expect(
        behindQuestion.shows(scanButtonLabel),
        isTrue,
        reason: 'the home screen is not behind Android\'s question',
      );

      await phone.tap(question!.allowX, question.allowY);

      await expectCameraScreenOpens();
      expect(await phone.cameraAccess(), CameraAccess.allowed);
    }, timeout: testTimeout);
  });

  group('Camera screen', () {
    test('Given access is already allowed, when the person taps "Quét vé", '
        'then the camera screen opens with no question', () async {
      await givenHomeScreen();
      await givenCameraAllowed();

      await tapScanButton();

      var wasAsked = false;
      Future<bool> isAskedNow() async {
        wasAsked = await phone.isAndroidAskingForPermission();
        return wasAsked;
      }

      await waitUntil(() async {
        return await isAskedNow() || await isCameraScreenShowing();
      });
      await waitUntil(isAskedNow, timeout: lateQuestionWatch);
      expect(wasAsked, isFalse, reason: 'Android asked a question');
      await expectCameraScreenOpens();
    }, timeout: testTimeout);

    // The dashed frame and how the whole screen looks are manual step 2.
    group('Given the camera screen is open, then it matches sketch 2', () {
      test('it shows "Đặt vé vào khung" at the top', () async {
        await givenCameraScreenOpen();

        final screen = await appScreen();
        expect(
          screen.itemWith(cameraHint).centerY,
          lessThan(screen.height / 4),
          reason: 'the text must be at the top of the screen',
        );
      }, timeout: testTimeout);

      test('it shows one round shutter button at the bottom middle '
          'and no added buttons', () async {
        await givenCameraScreenOpen();

        final screen = await appScreen();
        final shutter = await findShutter();
        expect(
          shutter.width,
          closeTo(shutter.height, shutter.height * 0.04),
          reason: 'a round button is as wide as it is tall: $shutter',
        );
        expect(
          shutter.centerY,
          greaterThan(screen.height * 0.7),
          reason: 'the shutter must be at the bottom of the screen: $shutter',
        );
        expect(
          shutter.centerX,
          closeTo(screen.width / 2, screen.width * 0.03),
          reason: 'the shutter must be in the middle: $shutter',
        );
      }, timeout: testTimeout);

      test('it has a dark background', () async {
        await givenCameraScreenOpen();

        // Beside the text and the shutter, and in the bottom corners: places
        // in the sketch that are outside the frame, so never the picture.
        const darkest = 64;
        final screen = await appScreen();
        final hint = screen.itemWith(cameraHint);
        final shutter = await findShutter();
        final margin = (screen.width * 0.04).round();
        final rightSide = screen.width.round() - margin;
        final bottom = (screen.height * 0.94).round();
        final hintY = hint.centerY.round();
        final shutterY = shutter.centerY.round();
        final pixels = await phone.screenshot();
        for (final (x, y) in [
          (margin, hintY),
          (rightSide, hintY),
          (margin, shutterY),
          (rightSide, shutterY),
          (margin, bottom),
          (rightSide, bottom),
        ]) {
          expect(
            pixels.brightness(x, y),
            lessThanOrEqualTo(darkest),
            reason: 'the background at ($x, $y) is not dark',
          );
        }
      }, timeout: testTimeout);

      test('it shows a live camera picture', () async {
        await givenCameraScreenOpen();

        expect(
          await phone.isAppUsingCamera(),
          isTrue,
          reason: 'Android says the app is not using the camera',
        );
        expect(
          await isPictureMoving(),
          isTrue,
          reason: 'the picture on the screen is not moving',
        );
      }, timeout: testTimeout);
    });
  });

  group('Taking the photo', () {
    test(
      'Given the camera screen is open, when the person taps the shutter, '
      'then the photo is kept inside the app and the home screen shows',
      () async {
        await givenCameraScreenOpen();

        final tappedAt = await tapShutter();

        await expectHomeScreenShows();
        await expectPhotoKeptSince(tappedAt);
      },
      timeout: testTimeout,
    );

    test('Given a photo is already kept, when the person takes another, '
        'then only the new photo is kept', () async {
      await takePhoto();
      // File times are in whole seconds: this tells the two photos apart.
      await Future<void>.delayed(const Duration(seconds: 2));

      await givenCameraScreenOpen();
      final tappedAt = await tapShutter();

      await expectHomeScreenShows();
      await expectPhotoKeptSince(tappedAt);
      await Future<void>.delayed(settleTime);
      final photos = await phone.photosInsideApp();
      expect(
        photos.where((photo) => photo.modifiedAt < tappedAt.floor()),
        isEmpty,
        reason: 'an older photo is still kept',
      );
    }, timeout: testTimeout);

    test('Given a photo was taken, then nothing new appears in the phone\'s '
        'gallery', () async {
      final galleryBefore = await phone.galleryPhotos();

      await takePhoto();

      await Future<void>.delayed(settleTime);
      expect(await phone.galleryPhotos(), galleryBefore);
    }, timeout: testTimeout);
  });

  group('Leaving without a photo', () {
    /// Then: the home screen shows, and nothing was added or replaced.
    Future<void> expectLeftWithoutPhoto(Future<void> Function() goBack) async {
      await givenCameraScreenOpen();
      final photosBefore = await phone.photosInsideApp();
      final galleryBefore = await phone.galleryPhotos();

      await goBack();

      await expectHomeScreenShows();
      await Future<void>.delayed(settleTime);
      expect(
        await phone.photosInsideApp(),
        photosBefore,
        reason: 'a photo was taken',
      );
      expect(
        await phone.galleryPhotos(),
        galleryBefore,
        reason: 'a photo was taken',
      );
    }

    test('Given the camera screen is open, when the person uses the phone\'s '
        'back button, then the home screen shows and no photo is taken', () {
      return expectLeftWithoutPhoto(phone.pressBackButton);
    }, timeout: testTimeout);

    test(
      'Given the camera screen is open, when the person uses the phone\'s '
      'back gesture, then the home screen shows and no photo is taken',
      () async {
        expect(
          await phone.usesBackGesture(),
          isTrue,
          reason: 'SETUP: the phone is not using gesture navigation',
        );

        await expectLeftWithoutPhoto(() async {
          final screen = await appScreen();
          await phone.swipeBack(
            screenWidth: screen.width.round(),
            screenHeight: screen.height.round(),
          );
        });
      },
      timeout: testTimeout,
    );
  });
}
