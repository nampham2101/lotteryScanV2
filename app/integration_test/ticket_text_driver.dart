import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/answer_screens.dart';
import 'helpers/app_screen.dart';
import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #18, changed by tickets #24, #28 and #31, on the
// Pixel_10 emulator. They run on the
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
// vé" below the photo are replaced by ticket_fields_driver.dart. Since ticket
// #31 the shutter opens sketch 3, then a full answer screen with no photo.

// Since ticket #31 the answer shows on its own screen, with no photo, so the
// earlier and the new photo are told apart by their answers. The earlier
// ticket is too old for the saved feed. The new one loses on a day in it, so
// its screen shows its own ticket card.
const _earlierText = 'ĐÀ LẠT\n654321\n24-11-2019';
const _earlierAnswer = tooOldScreen;
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

  setUp(holdReads);

  group('Normal case', () {
    // Ticket #31 replaced the test that the temporary screen opens straight
    // away with the photo and "Đang đọc vé..." below it: sketch 3 shows
    // instead, tested in answer_screens_driver.dart.

    // Changed by ticket #24: what shows after the read is the three lines or
    // screen 4d. The test doesn't decide what the room reads, so it accepts
    // either, but an empty text must give 4d. Changed by ticket #28: an
    // answer shows below the three lines, and which one depends on what the
    // room reads, so any answer is accepted. Changed by ticket #31: the
    // answer shows on its own screen, with no photo and no three lines.
    test('Given a photo taken in the app, when real ML Kit reads it, then the '
        'read works and an answer screen shows, or screen 4d, and 4d if the '
        'text it gave is empty', () async {
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
      bool showsAnswer(AppScreen screen) =>
          answerTitles.any((title) => wordsFrom(screen, title) != null);

      await waitUntil(() async {
        screen = await appScreen();
        return showsAnswer(screen) || is4d(screen);
      });
      if (read.text!.isEmpty || !showsAnswer(screen)) {
        await expect4dShows(photo);
      } else {
        await expectNoPhotoAnywhere(photo);
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

    test('Given an answer screen is showing, when the person presses back '
        'and taps "Quét vé", then the camera opens as normal', () async {
      await givenReadingShows();
      await finishRead(0, fullTicketText);
      await expectAnswerScreen(fullTicketAnswer);

      await phone.pressBackButton();
      await expectHomeScreenShows();
      await tapScanButton();

      await expectCameraScreenOpens();
      await expectAppUsingCamera();
      await findShutter();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo, when they take a new one, then the '
        'screen shows only the new photo\'s own answer', () async {
      addTearDown(phone.turnCameraBack);
      await givenReadingShows();
      await finishRead(0, _earlierText);
      await expectAnswerScreen(_earlierAnswer);

      final newPhoto = await leaveAndTakeNewPhoto();

      await finishRead(1, _newText);
      await expectAnswerScreen(_newAnswer, photo: newPhoto);
      await expectReadWasOfKeptPhoto(1);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read finishes first, then the screen '
        'shows only the new photo\'s own answer', () async {
      addTearDown(phone.turnCameraBack);
      await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await finishRead(0, _earlierText);

      await expectReadingScreenStays();
      await finishRead(1, _newText);
      await expectAnswerScreen(_newAnswer, photo: newPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read finishes last, then the screen '
        'shows only the new photo\'s own answer', () async {
      addTearDown(phone.turnCameraBack);
      await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await finishRead(1, _newText);
      await expectAnswerScreen(_newAnswer);
      await finishRead(0, _earlierText);

      await Future<void>.delayed(settleTime);
      await expectAnswerScreen(_newAnswer, photo: newPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the person left a photo with its read unfinished, when they '
        'take a new one and the earlier read fails, then the screen still '
        'waits for the new photo\'s own answer', () async {
      addTearDown(phone.turnCameraBack);
      await givenReadingShows();

      final newPhoto = await leaveAndTakeNewPhoto();
      await failRead(0);

      await expectReadingScreenStays();
      await finishRead(1, _newText);
      await expectAnswerScreen(_newAnswer, photo: newPhoto);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
