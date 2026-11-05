import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #18, on the Pixel_10 emulator. They run on the
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

/// Accents, a repeated line, two spaces, and an order no sorting would give, so
/// a tidied-up text doesn't match.
const _ticketText =
    'XỔ SỐ KIẾN THIẾT\n'
    'BẾN TRE\n'
    '05-11-2026  LOẠI VÉ 10.000Đ\n'
    '123456\n'
    'BẾN TRE';

const _earlierText = 'ĐÀ LẠT\n654321';
const _newText = 'BẠC LIÊU\n111222';

/// More lines than any phone can show below the photo.
final _longText = [
  for (var line = 1; line <= 150; line++) 'Dòng thứ $line của vé',
].join('\n');

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

    test('Given "Đang đọc vé..." is showing, when ML Kit finishes and has '
        'found text, then "Đang đọc vé..." goes away and ML Kit\'s text value '
        'shows below the photo, exactly as ML Kit gives it, with the same line '
        'breaks and order', () async {
      final photo = await givenReadingShows();

      await finishRead(0, _ticketText);

      await expectOnlyTextIs(_ticketText);
      await expectScreenShows(photo);
      await expectReadWasOfKeptPhoto(0);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a photo taken in the app, when real ML Kit reads it, then the '
        'screen shows exactly what ML Kit gave, or "Không đọc được vé" if it '
        'gave nothing', () async {
      await useRealReader();
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      final read = await finishedRealRead(0);
      final text = read.text ?? '';
      await expectOnlyTextIs(text.isEmpty ? couldNotReadText : text);
      await expectScreenShows(await keptPhotoSince(tappedAt));
      await expectReadWasOfKeptPhoto(0);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Long text', () {
    test('Given the text is longer than the space below the photo, when the '
        'person swipes on the text, then the text scrolls to its last line and '
        'the photo stays in place', () async {
      final photo = await givenReadingShows();
      await finishRead(0, _longText);
      final start = await scrollingTextArea();
      expect(start.isAtEnd, isFalse, reason: 'the text must start at its top');
      final place = await photoPlaceNow(photo);

      final end = await swipeToEndOfText();

      expect(end.position, greaterThan(start.position));
      expect(end.isAtEnd, isTrue, reason: 'the text did not reach its end');
      expect((await appScreen()).shows('Dòng thứ 150 của vé'), isTrue);
      await expectPhotoStaysAt(photo, place);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Failure cases', () {
    test('Given a photo with no readable text, when ML Kit finishes, then '
        '"Không đọc được vé" shows below the photo and "Đang đọc vé..." is '
        'gone', () async {
      final photo = await givenReadingShows();

      await finishRead(0, '');

      await expectOnlyTextIs(couldNotReadText);
      await expectScreenShows(photo);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given ML Kit\'s read fails, when the failure comes back, then '
        '"Không đọc được vé" shows below the photo and "Đang đọc vé..." is '
        'gone', () async {
      final photo = await givenReadingShows();

      await failRead(0);

      await expectOnlyTextIs(couldNotReadText);
      await expectScreenShows(photo);
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
        endRead: () => finishRead(0, _ticketText),
      );
    }, timeout: testTimeout);

    test('Given "Đang đọc vé..." is showing, when the person uses the phone\'s '
        'back gesture, then home shows, with no error when ML Kit finishes '
        'afterwards', () {
      return expectLeavingWhileReadingGoesHome(
        goBack: useBackGesture,
        endRead: () => finishRead(0, _ticketText),
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
      await finishRead(0, _ticketText);
      await expectOnlyTextIs(_ticketText);

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
      await expectOnlyTextIs(_earlierText);

      final newPhoto = await leaveAndTakeNewPhoto();

      await expectScreenDoesNotShow(earlierPhoto);
      await finishRead(1, _newText);
      await expectOnlyTextIs(_newText);
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
      await expectOnlyTextIs(_newText);
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
      await expectOnlyTextIs(_newText);
      await finishRead(0, _earlierText);

      await expectOnlyTextStays(_newText);
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
      await expectOnlyTextIs(_newText);
      await expectScreenShows(newPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
