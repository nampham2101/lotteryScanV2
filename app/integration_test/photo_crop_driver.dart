import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/photo_crop.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #22, on the Pixel_10 emulator. They run on the
// Mac, because only the Mac can take screenshots of the camera screen, read the
// kept photo, look through the app's folders and the gallery, and turn the
// emulator's camera. They talk to the real app started from photo_crop_app.dart,
// where the tests decide what ML Kit answers and can spoil or hold back the
// camera's picture. Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/photo_crop_driver.dart \
//     --target=integration_test/photo_crop_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run.

/// Accents, a repeated line and two spaces, so a tidied-up text doesn't match.
const _ticketText =
    'XỔ SỐ KIẾN THIẾT\n'
    'BẾN TRE\n'
    '05-11-2026  LOẠI VÉ 10.000Đ\n'
    '123456\n'
    'BẾN TRE';

const _newText = 'BẠC LIÊU\n111222';

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(() async {
    await holdReads();
    await startCameraWatch();
  });

  group('Normal case', () {
    test('Given the camera screen is open, when the person taps the shutter, '
        'then the temporary screen opens straight away, with a square photo '
        'of exactly what was inside the dashed frame, shown whole, and "Đang '
        'đọc vé..." below it', () async {
      final seen = await givenCameraScreenWithFrame();

      final tappedAt = await tapShutter();

      // ML Kit hasn't answered, so the screen didn't wait for it.
      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyTextIs(readingText);
      final photo = await croppedPhotoKeptSince(tappedAt, seen);
      await expectScreenShows(photo);
      await expectReadAsked(0);
      expect((await readerReport()).reads.single.isFinished, isFalse);
    }, timeout: testTimeout);

    test('Given "Đang đọc vé..." is showing, when ML Kit finishes, then the '
        'text it read from the cropped photo shows below it, exactly as ML '
        'Kit gives it', () async {
      final seen = await givenCameraScreenWithFrame();
      final tappedAt = await tapShutter();
      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyTextIs(readingText);
      final photo = await croppedPhotoKeptSince(tappedAt, seen);
      await expectReadAsked(0);

      await finishRead(0, _ticketText);

      await expectOnlyTextIs(_ticketText);
      await expectReadWasOfKeptPhoto(0);
      await expectScreenShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Only the cropped photo is kept', () {
    test('Given the person has taken a photo, when the temporary screen '
        'opens, then the app holds only one photo, the cropped one, and no '
        'full-size copy is left anywhere, including the camera\'s own '
        'copy', () async {
      await givenPhotoKeptEarlier();
      final galleryBefore = await phone.galleryPhotos();
      final seen = await givenCameraScreenWithFrame();

      await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyCroppedPhotoKept(seen, galleryBefore: galleryBefore);
    }, timeout: testTimeout);
  });

  group('Crop fails', () {
    test('Given the camera screen is open, when the person taps the shutter '
        'and the crop fails, then the camera screen stays open, the note shows '
        'near the bottom and fades after a few seconds, no photo is kept from '
        'this try, and any photo kept before stays unchanged', () async {
      await givenPhotoKeptEarlier();
      final before = await appPhotosNow();
      expect(before.inside, hasLength(1), reason: 'SETUP: no earlier photo');
      await givenCameraScreenOpen();
      await spoilNextPhoto();

      await tapShutter();

      await expectSpoiledPictureHandedOver();
      await expectNoteShowsAndFades();
      await expectPhotosUnchanged(before);
      await expectCamerasCopyGone();
    }, timeout: testTimeout);

    test('Given the note is showing, when the person taps the shutter again, '
        'then a new photo is taken and, if the crop works, the temporary '
        'screen opens as normal', () async {
      final seen = await givenCameraScreenWithFrame();
      await spoilNextPhoto();
      await tapShutter();
      await expectSpoiledPictureHandedOver();
      await expectNoteShows();

      final tappedAt = await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyTextIs(readingText);
      expect(
        (await cameraReport()).pictures,
        hasLength(2),
        reason: 'the second tap must take a new photo',
      );
      final photo = await croppedPhotoKeptSince(tappedAt, seen);
      await expectScreenShows(photo);
      // The failed try may or may not have been read: the new photo's read is
      // the latest one.
      await expectReadAsked(0);
      final read = (await readerReport()).reads.length - 1;
      await finishRead(read, _ticketText);
      await expectOnlyTextIs(_ticketText);
      await expectReadWasOfKeptPhoto(read);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Leaving the screen', () {
    test('Given the person taps the shutter, when they press back before the '
        'temporary screen opens, then home shows and no photo is '
        'kept', () async {
      await givenPhotoKeptEarlier();
      final before = await appPhotosNow();
      await givenCameraScreenOpen();

      await tapShutterThenBack();

      await expectHomeWithNoPhotoScreen();
      await expectPhotosUnchanged(before);
      await expectCamerasCopyGone();
    }, timeout: testTimeout);

    test('Given the person left a photo, when they take a new one, then the '
        'screen shows only the new cropped photo and its own text', () async {
      addTearDown(phone.turnCameraBack);
      final galleryBefore = await phone.galleryPhotos();
      final earlierPhoto = await givenPhotoKeptEarlier();
      await phone.turnCamera();
      final seen = await givenCameraScreenWithFrame();

      final tappedAt = await tapShutter();

      await expectPhotoScreenOpensWithoutHome();
      final newPhoto = await croppedPhotoKeptSince(tappedAt, seen);
      await expectScreenDoesNotShow(earlierPhoto);
      await expectReadAsked(1);
      await finishRead(1, _newText);
      await expectOnlyTextIs(_newText);
      await expectScreenShows(newPhoto);
      await expectScreenDoesNotShow(earlierPhoto);
      await expectReadWasOfKeptPhoto(1);
      await expectOnlyCroppedPhotoKept(seen, galleryBefore: galleryBefore);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
