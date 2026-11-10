import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/app_screen.dart';
import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #18, changed by ticket #24, on the Pixel_10
// emulator. They run on the
// Mac, because only the Mac can read the kept photo, compare it with the screen,
// turn the emulator's camera and swipe on the screen. They talk to the real app
// started from ticket_text_app.dart, where the tests decide what ML Kit answers
// and when. Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/ticket_text_driver.dart \
//     --target=integration_test/ticket_text_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run.
//
// Since ticket #24 the screen shows three lines read from ML Kit's text in
// place of the text itself, and 4d when a field is missing or the read fails.
// The tests that expected ML Kit's own text, its scrolling, or "Không đọc được
// vé" below the photo are replaced by ticket_fields_driver.dart.

const _earlierText = 'ĐÀ LẠT\n654321\n24-11-2019';
final _earlierLines = fieldLines(
  number: '654321',
  province: 'Đà Lạt',
  date: '24-11-2019',
);
const _newText = 'BẠC LIÊU\n111222\n20-10-2026';
final _newLines = fieldLines(
  number: '111222',
  province: 'Bạc Liêu',
  date: '20-10-2026',
);

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(holdReads);

  group('Normal case', () {
    test('Given the camera screen is open, when the person taps the shutter, '
        'then the temporary screen opens straight away, with the photo on top, '
        'whole and not cut off, and "Đang đọc vé..." below it', () async {
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      // ML Kit hasn't answered, so the screen didn't wait for it.
      await expectPhotoScreenOpensWithoutHome();
      await expectOnlyTextIs(readingText);
      await expectScreenShows(await keptPhotoSince(tappedAt));
      await expectReadAsked(0);
      expect((await readerReport()).reads.single.isFinished, isFalse);
    }, timeout: testTimeout);

    // Changed by ticket #24: what shows after the read is the three lines or
    // screen 4d. The test doesn't decide what the room reads, so it accepts
    // either, but an empty text must give 4d.
    test('Given a photo taken in the app, when real ML Kit reads it, then the '
        'read works and the screen shows the three lines below the photo, or '
        'screen 4d, and 4d if the text it gave is empty', () async {
      await useRealReader();
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      final read = await finishedRealRead(0);
      expect(
        read.text,
        isNotNull,
        reason: 'real ML Kit did not give an answer: ${read.failure}',
      );
      final photo = await keptPhotoSince(tappedAt);
      await expectReadWasOfKeptPhoto(0);
      var screen = await appScreen();
      bool showsLines(AppScreen screen) {
        final lines = shownLines(screen);
        return lines.length == 3 &&
            lines[0].startsWith(numberLabel) &&
            lines[1].startsWith(provinceLabel) &&
            lines[2].startsWith(dateLabel);
      }

      await waitUntil(() async {
        screen = await appScreen();
        return showsLines(screen) || is4d(screen);
      });
      if (read.text!.isEmpty || !showsLines(screen)) {
        await expect4dShows(photo);
      } else {
        await expectScreenShows(photo);
      }
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Leaving the screen', () {
    Future<void> expectLeavingWhileReadingGoesHome({
      required Future<void> Function() goBack,
      required Future<void> Function() endRead,
    }) async {
      await givenReadingShows();

      await goBack();

      await expectHomeScreenShows();
      await endRead();
      await Future<void>.delayed(settleTime);
      await expectHomeScreenShows();
      await expectNoAppErrors();
    }

    test('Given "Đang đọc vé..." is showing, when the person presses the '
        'phone\'s back button, then home shows, with no error when ML Kit '
        'finishes afterwards', () {
      return expectLeavingWhileReadingGoesHome(
        goBack: phone.pressBackButton,
        endRead: () => finishRead(0, fullTicketText),
      );
    }, timeout: testTimeout);

    test('Given "Đang đọc vé..." is showing, when the person uses the phone\'s '
        'back gesture, then home shows, with no error when ML Kit finishes '
        'afterwards', () {
      return expectLeavingWhileReadingGoesHome(
        goBack: useBackGesture,
        endRead: () => finishRead(0, fullTicketText),
      );
    }, timeout: testTimeout);

    test('Given "Đang đọc vé..." is showing, when the person presses the '
        'phone\'s back button, then home shows, with no error when ML Kit '
        'fails afterwards', () {
      return expectLeavingWhileReadingGoesHome(
        goBack: phone.pressBackButton,
        endRead: () => failRead(0),
      );
    }, timeout: testTimeout);

    test('Given the text is showing, when the person presses back and taps '
        '"Quét vé", then the camera opens as normal', () async {
      await givenReadingShows();
      await finishRead(0, fullTicketText);
      await expectOnlyLinesAre(fullTicketLines);

      await phone.pressBackButton();
      await expectHomeScreenShows();
      await tapScanButton();

      await expectCameraScreenOpens();
      await expectAppUsingCamera();
      await findShutter();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo, when they take a new one, then the '
        'screen shows only the new photo and its own text', () async {
      addTearDown(phone.turnCameraBack);
      final earlierPhoto = await givenReadingShows();
      await finishRead(0, _earlierText);
      await expectOnlyLinesAre(_earlierLines);

      final newPhoto = await leaveAndTakeNewPhoto();

      await expectScreenDoesNotShow(earlierPhoto);
      await finishRead(1, _newText);
      await expectOnlyLinesAre(_newLines);
      await expectScreenShows(newPhoto);
      await expectScreenDoesNotShow(earlierPhoto);
      await expectReadWasOfKeptPhoto(1);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read finishes first, then the screen '
        'shows only the new photo and its own text', () async {
      addTearDown(phone.turnCameraBack);
      final earlierPhoto = await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await finishRead(0, _earlierText);

      await expectOnlyTextStays(readingText);
      await expectScreenShows(newPhoto);
      await finishRead(1, _newText);
      await expectOnlyLinesAre(_newLines);
      await expectScreenShows(newPhoto);
      await expectScreenDoesNotShow(earlierPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read finishes last, then the screen '
        'shows only the new photo and its own text', () async {
      addTearDown(phone.turnCameraBack);
      final earlierPhoto = await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await finishRead(1, _newText);
      await expectOnlyLinesAre(_newLines);
      await finishRead(0, _earlierText);

      await expectOnlyLinesStay(_newLines);
      await expectScreenShows(newPhoto);
      await expectScreenDoesNotShow(earlierPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read fails, then the screen still '
        'waits for the new photo\'s own text', () async {
      addTearDown(phone.turnCameraBack);
      await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await failRead(0);

      await expectOnlyTextStays(readingText);
      await finishRead(1, _newText);
      await expectOnlyLinesAre(_newLines);
      await expectScreenShows(newPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
