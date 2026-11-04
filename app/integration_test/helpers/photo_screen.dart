import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'app_screen.dart';
import 'driven_app.dart';
import 'phone.dart';
import 'shown_photo.dart';

// Shared by the tests for ticket #10: what the photo screen is, how a photo gets
// there, and what a person's fingers do to it. The ticket leaves open how that
// screen is built, so it's recognised the way a person recognises it: no words,
// no buttons, and the photo that was just taken.

/// How long to wait between screen checks while watching for a brief change.
const _watchStep = Duration(milliseconds: 40);

/// Fewer sampled pixels than this changing means the picture didn't change: a
/// size change on this photo moves thousands of them.
const _picturesStillTheSame = 20;

/// Time for a zoom animation to finish.
const _gestureSettleTime = Duration(seconds: 1);

bool _looksLikePhotoScreen(AppScreen screen) =>
    screen.texts.isEmpty && screen.buttons.isEmpty;

bool _looksLikeHomeScreen(AppScreen screen) =>
    screen.shows(homeTitle) || screen.shows(scanButtonLabel);

/// When the shutter was tapped: watches what the app does next, so that a home
/// screen that only flashes by is caught as well. The app's list of what's on
/// screen is empty for a moment whenever a screen closes, so the photo screen
/// only counts once it has lasted.
Future<void> expectPhotoScreenOpensWithoutHome() async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout + settleTime);
  DateTime? openSince;
  while (DateTime.now().isBefore(giveUpAt)) {
    final screen = await appScreen();
    expect(
      _looksLikeHomeScreen(screen),
      isFalse,
      reason:
          'the home screen showed after the shutter, not the photo screen. '
          'On screen: ${screen.items}',
    );
    openSince = _looksLikePhotoScreen(screen)
        ? openSince ?? DateTime.now()
        : null;
    if (openSince != null &&
        DateTime.now().difference(openSince) >= settleTime) {
      return;
    }
    await Future<void>.delayed(_watchStep);
  }
  fail(
    'the photo screen did not open and stay after the shutter. '
    'On screen: ${(await appScreen()).items}',
  );
}

/// The newest photo inside the app, written after [tappedAt].
Future<img.Image> keptPhotoSince(double tappedAt) async {
  await expectPhotoKeptSince(tappedAt);
  final photos = await phone.photosInsideApp();
  photos.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
  return uprightPhoto(await phone.fileInsideApp(photos.last.path));
}

Future<double> _differenceNow(img.Image photo) async =>
    differenceFromScreen(photo, await phone.screenshot(), await appScreen());

/// Then: the screen shows [photo] whole and upright. Decoding a photo takes a
/// moment, so this waits for it.
Future<void> expectScreenShows(img.Image photo) async {
  var difference = double.infinity;
  await waitUntil(() async {
    difference = await _differenceNow(photo);
    return difference <= samePictureLimit;
  });
  expect(
    difference,
    lessThanOrEqualTo(samePictureLimit),
    reason:
        'the screen is not showing the kept photo whole and upright, fitted '
        'to the screen',
  );
}

/// Then: the screen isn't showing [photo].
Future<void> expectScreenDoesNotShow(img.Image photo) async {
  expect(
    await _differenceNow(photo),
    greaterThan(samePictureLimit),
    reason: 'the screen is still showing the old photo',
  );
}

/// Given: a photo was just taken, so the photo screen is open. Returns it.
Future<img.Image> givenPhotoScreenOpen() async {
  await givenCameraScreenOpen();
  final tappedAt = await tapShutter();
  await expectPhotoScreenOpensWithoutHome();
  final photo = await keptPhotoSince(tappedAt);
  await expectScreenShows(photo);
  return photo;
}

/// Given: a photo was taken earlier, and the person is back on the home screen.
Future<img.Image> givenPhotoTakenEarlier() async {
  final photo = await givenPhotoScreenOpen();
  await phone.pressBackButton();
  await expectHomeScreenShows();
  return photo;
}

/// Then: the home screen shows and stays, and [earlierPhoto] never appears on
/// a screen of its own, on the way there or just after. The picture is checked
/// too, because the list of what's on screen is empty for a moment as the camera
/// screen closes.
Future<void> expectHomeScreenShowsWithNoPhotoScreen(
  img.Image earlierPhoto,
) async {
  var sawPhotoScreen = false;
  Future<void> look() async {
    if (sawPhotoScreen || !_looksLikePhotoScreen(await appScreen())) return;
    sawPhotoScreen = await _differenceNow(earlierPhoto) <= samePictureLimit;
  }

  final isHome = await waitUntil(() async {
    await look();
    return isHomeScreenShowing();
  });
  final stopAt = DateTime.now().add(settleTime);
  while (DateTime.now().isBefore(stopAt)) {
    await look();
    await Future<void>.delayed(_watchStep);
  }
  expect(sawPhotoScreen, isFalse, reason: 'a photo screen appeared');
  expect(
    isHome && await isHomeScreenShowing(),
    isTrue,
    reason:
        'the home screen did not show. In front: '
        '${await phone.windowInFront()}',
  );
}

/// Then: the picture is the same as in [before]. `changedPixels` leaves out the
/// phone's bars, which change by themselves.
Future<void> _expectSamePicture(ScreenPixels before, String when) async {
  final changed = (await phone.screenshot()).changedPixels(before);
  expect(
    changed,
    lessThan(_picturesStillTheSame),
    reason: 'the photo changed $when: $changed sampled pixels moved',
  );
}

/// When the person pinches, then the photo stays the same size, both with the
/// fingers still down and after they lift.
Future<void> expectPinchLeavesPhotoAlone({required bool isSpreading}) async {
  final photo = await givenPhotoScreenOpen();
  final before = await phone.screenshot();
  final screen = await appScreen();

  await phone.pinch(
    screenWidth: screen.width.round(),
    screenHeight: screen.height.round(),
    isSpreading: isSpreading,
    whileHeld: () async {
      await Future<void>.delayed(_gestureSettleTime);
      await _expectSamePicture(before, 'during the pinch');
    },
  );

  await Future<void>.delayed(_gestureSettleTime);
  final after = await appScreen();
  expect(
    after.twoFingerTouches,
    screen.twoFingerTouches + 1,
    reason: 'SETUP: the two fingers never reached the app',
  );
  await _expectSamePicture(before, 'after the pinch');
  await expectScreenShows(photo);
}

/// When the person double-taps, then the photo stays the same size. A zoom can
/// start only after the second tap, so this waits before looking.
Future<void> expectDoubleTapLeavesPhotoAlone() async {
  final photo = await givenPhotoScreenOpen();
  final before = await phone.screenshot();
  final screen = await appScreen();

  await phone.doubleTap(
    x: screen.width ~/ 2,
    y: screen.height ~/ 2,
    screenWidth: screen.width.round(),
    screenHeight: screen.height.round(),
  );

  await Future<void>.delayed(_gestureSettleTime);
  final after = await appScreen();
  expect(
    after.touches,
    screen.touches + 2,
    reason: 'SETUP: the two taps never reached the app',
  );
  await _expectSamePicture(before, 'after the double-tap');
  await expectScreenShows(photo);
}
