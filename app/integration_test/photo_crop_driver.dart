import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/answer_screens.dart';
import 'helpers/driven_app.dart';
import 'helpers/photo_crop.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #22, changed by tickets #24, #28 and #31, on the
// Pixel_10 emulator. They run on the
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

// Since ticket #24 the screen shows three lines read from ML Kit's text in
// place of the text itself, so the reads below give texts with all three
// fields and the tests expect those lines.

// Since ticket #31 the shutter opens sketch 3, with no photo, then a full
// answer screen. The crop is checked on the photo kept, which is what a photo
// on screen was compared with before. The new ticket below loses on a day in
// the saved feed, so its screen shows its own ticket card.
const _newText = 'BẠC LIÊU\n111222\n10-11-2026';
final _newAnswer = lostScreen(
  ticketCard(number: '111222', province: 'Bạc Liêu', date: '10/11/2026'),
);

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
    // Changed by ticket #31: sketch 3 opens in place of the temporary screen,
    // and no screen shows the photo.
    test('Given the camera screen is open, when the person taps the shutter, '
        'then sketch 3 opens straight away, and the photo kept is a square of '
        'exactly what was inside the dashed frame', () async {
      final seen = await givenCameraScreenWithFrame();

      final tappedAt = await tapShutter();

      // ML Kit hasn't answered, so the screen didn't wait for it.
      await expectReadingScreenOpensWithoutHome();
      await croppedPhotoKeptSince(tappedAt, seen);
      await expectReadAsked(0);
      expect((await readerReport()).reads.single.isFinished, isFalse);
    }, timeout: testTimeout);

    // Changed by ticket #24: the three lines read from ML Kit's text show in
    // place of the text itself. Changed by ticket #28: the answer shows below
    // them. Changed by ticket #31: the answer shows on its own screen, whose
    // ticket card shows what was read.
    test('Given "Đang đọc vé..." is showing, when ML Kit finishes, then the '
        'answer screen for what it read from the cropped photo shows, with '
        'its ticket card', () async {
      final seen = await givenCameraScreenWithFrame();
      final tappedAt = await tapShutter();
      await expectReadingScreenOpensWithoutHome();
      final photo = await croppedPhotoKeptSince(tappedAt, seen);
      await expectReadAsked(0);

      await finishRead(0, fullTicketText);

      await expectAnswerScreen(fullTicketAnswer, photo: photo);
      await expectReadWasOfKeptPhoto(0);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Only the cropped photo is kept', () {
    test('Given the person has taken a photo, when sketch 3 opens, then the '
        'app holds only one photo, the cropped one, and no full-size copy is '
        'left anywhere, including the camera\'s own copy', () async {
      await givenPhotoKeptEarlier();
      final galleryBefore = await phone.galleryPhotos();
      final seen = await givenCameraScreenWithFrame();

      await tapShutter();

      await expectReadingScreenOpensWithoutHome();
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
        'then a new photo is taken and, if the crop works, sketch 3 opens as '
        'normal, then the answer', () async {
      final seen = await givenCameraScreenWithFrame();
      await spoilNextPhoto();
      await tapShutter();
      await expectSpoiledPictureHandedOver();
      await expectNoteShows();

      final tappedAt = await tapShutter();

      await expectReadingScreenOpensWithoutHome();
      expect(
        (await cameraReport()).pictures,
        hasLength(2),
        reason: 'the second tap must take a new photo',
      );
      final photo = await croppedPhotoKeptSince(tappedAt, seen);
      // The failed try may or may not have been read: the new photo's read is
      // the latest one.
      await expectReadAsked(0);
      final read = (await readerReport()).reads.length - 1;
      await finishRead(read, fullTicketText);
      await expectAnswerScreen(fullTicketAnswer, photo: photo);
      await expectReadWasOfKeptPhoto(read);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Leaving the screen', () {
    test('Given the person taps the shutter, when they press back before '
        'sketch 3 opens, then home shows and no photo is kept', () async {
      await givenPhotoKeptEarlier();
      final before = await appPhotosNow();
      await givenCameraScreenOpen();

      await tapShutterThenBack();

      await expectHomeWithNoPhotoScreen();
      await expectPhotosUnchanged(before);
      await expectCamerasCopyGone();
    }, timeout: testTimeout);

    test('Given the person left a photo, when they take a new one, then the '
        'app keeps only the new cropped photo, and only its own answer '
        'shows', () async {
      addTearDown(phone.turnCameraBack);
      final galleryBefore = await phone.galleryPhotos();
      await givenPhotoKeptEarlier();
      await phone.turnCamera();
      final seen = await givenCameraScreenWithFrame();

      final tappedAt = await tapShutter();

      await expectReadingScreenOpensWithoutHome();
      final newPhoto = await croppedPhotoKeptSince(tappedAt, seen);
      await expectReadAsked(1);
      await finishRead(1, _newText);
      await expectAnswerScreen(_newAnswer, photo: newPhoto);
      await expectReadWasOfKeptPhoto(1);
      await expectOnlyCroppedPhotoKept(seen, galleryBefore: galleryBefore);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
