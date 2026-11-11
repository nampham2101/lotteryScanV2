import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'app_screen.dart';
import 'driven_app.dart';
import 'phone.dart';
import 'shown_photo.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

// Shared by the tests for tickets #10, #18 and #24: what the photo screen is,
// how a photo gets there, and what a person's fingers do to it. The tickets
// leave open how that screen is built, so it's recognised the way a person
// recognises it: words about the reading, no buttons, and the photo that was
// just taken.

const readingText = 'Đang đọc vé...';
const couldNotReadText = 'Không đọc được vé';

/// How long to wait between screen checks while watching for a brief change.
const _watchStep = Duration(milliseconds: 40);

/// Fewer sampled pixels than this changing means the picture didn't change: a
/// size change on this photo moves thousands of them.
const _picturesStillTheSame = 20;

/// Time for a zoom animation to finish.
const _gestureSettleTime = Duration(seconds: 1);

/// Words show on it the whole time: the reading, then the ticket's three lines
/// and, since ticket #28, the answer below them.
bool _looksLikePhotoScreen(AppScreen screen) =>
    screen.texts.isNotEmpty &&
    screen.buttons.isEmpty &&
    !_looksLikeHomeScreen(screen) &&
    !screen.shows(cameraHint);

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
    'the photo screen did not open and stay after the shutter: it must show '
    'text and no buttons. On screen: ${(await appScreen()).items}',
  );
}

/// The contents of the newest photo inside the app.
Future<List<int>> newestPhotoFile() async {
  final photos = await phone.photosInsideApp();
  photos.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
  return phone.fileInsideApp(photos.last.path);
}

/// The newest photo inside the app, written after [tappedAt].
Future<img.Image> keptPhotoSince(double tappedAt) async {
  await expectPhotoKeptSince(tappedAt);
  return uprightPhoto(await newestPhotoFile());
}

Future<double> _differenceNow(img.Image photo) async =>
    findPhoto(photo, await phone.screenshot(), await appScreen())?.difference ??
    double.infinity;

/// Then: the screen shows [photo] whole and upright, above any text. Decoding a
/// photo takes a moment, so this waits for it.
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
        'the screen is not showing the kept photo whole and upright, above '
        'the text',
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

/// Given: a photo was just taken, so the photo screen is open, and its read may
/// still be going on. Returns the photo.
Future<img.Image> givenPhotoTaken() async {
  await givenCameraScreenOpen();
  final tappedAt = await tapShutter();
  await expectPhotoScreenOpensWithoutHome();
  final photo = await keptPhotoSince(tappedAt);
  await expectScreenShows(photo);
  return photo;
}

/// Given: a photo was just taken and has been read, so nothing on the screen
/// changes by itself any more. Returns the photo.
///
/// Since ticket #24 a read with no ticket in it opens screen 4d, which has no
/// photo, so the test chooses a read that finds all three fields: the photo
/// screen stays, with the three lines below the photo. Since ticket #28 it
/// also waits for the answer below them, from the saved feed. This needs the
/// app started from ticket_text_app.dart, with the reads held.
Future<img.Image> givenPhotoScreenOpen() async {
  final photo = await givenPhotoTaken();
  await expectReadAsked(0);
  final latestRead = (await readerReport()).reads.length - 1;
  await finishRead(latestRead, fullTicketText);
  await expectOnlyLinesAre(fullTicketLines);
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
/// a screen of its own, on the way there or just after.
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
