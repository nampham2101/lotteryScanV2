import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'answer_screens.dart';
import 'app_screen.dart';
import 'driven_app.dart';
import 'shown_photo.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

// Shared by the tests for tickets #10, #18, #22, #24, #28 and #31: what shows
// after the shutter, and how a photo gets taken and kept. Until ticket #31 the
// shutter opened a temporary "photo screen" with the photo and the reading
// below it. Since ticket #31 it opens sketch 3, with no photo, until one full
// answer screen shows (answer_screens.dart). The tickets leave open how the
// screens are built, so they're recognised the way a person recognises them:
// by their words and buttons.

const couldNotReadText = 'Không đọc được vé';

/// How long to wait between screen checks while watching for a brief change.
const _watchStep = Duration(milliseconds: 40);

bool _looksLikeHomeScreen(AppScreen screen) =>
    screen.shows(homeTitle) || screen.shows(scanButtonLabel);

/// Whether "Đang đọc vé…" (or "Đang đọc vé...") is anywhere on screen.
bool showsReading(AppScreen screen) =>
    screen.texts.any((item) => item.label.contains(readingTitleStart));

/// Whether the screen is sketch 3: from its title down, its words are exactly
/// "Đang đọc vé…" and "Chỉ mất vài giây", and it has no buttons. The spinner
/// above the title isn't counted, even if it has a name for screen readers.
bool isReadingScreen(AppScreen screen) {
  final words = wordsFrom(screen, readingTitleStart);
  return words != null &&
      words.replaceFirst(readingTitleWithDots, readingTitle) ==
          tidy('$readingTitle $readingHint') &&
      screen.buttons.isEmpty;
}

/// When the shutter was tapped: watches what the app does next, so that a home
/// screen that only flashes by is caught as well. The app's list of what's on
/// screen is empty for a moment whenever a screen closes, so sketch 3 only
/// counts once it has lasted.
Future<void> expectReadingScreenOpensWithoutHome() async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout + settleTime);
  DateTime? openSince;
  while (DateTime.now().isBefore(giveUpAt)) {
    final screen = await appScreen();
    expect(
      _looksLikeHomeScreen(screen),
      isFalse,
      reason:
          'the home screen showed after the shutter, not sketch 3. On '
          'screen: ${shownLines(screen)}',
    );
    openSince = isReadingScreen(screen) ? openSince ?? DateTime.now() : null;
    if (openSince != null &&
        DateTime.now().difference(openSince) >= settleTime) {
      return;
    }
    await Future<void>.delayed(_watchStep);
  }
  fail(
    'sketch 3 did not open and stay after the shutter: it must show only '
    '"$readingTitle" and "$readingHint", with no buttons. On screen: '
    '${shownLines(await appScreen())}',
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

/// Then: the screen isn't showing [photo] above its text.
Future<void> expectScreenDoesNotShow(img.Image photo) async {
  expect(
    await _differenceNow(photo),
    greaterThan(samePictureLimit),
    reason: 'the screen is still showing the old photo',
  );
}

/// Then: [photo] isn't anywhere on the screen, at any size from a quarter of
/// the screen's width up, above, below or behind the words.
Future<void> expectNoPhotoAnywhere(img.Image photo) async {
  final screen = await appScreen();
  // With no texts, the search runs from the top bar down to the bottom bar.
  final wholeScreen = AppScreen.fromJson({
    'width': screen.width,
    'height': screen.height,
    'barsTop': screen.barsTop,
    'barsBottom': screen.barsBottom,
    'touches': screen.touches,
    'twoFingerTouches': screen.twoFingerTouches,
    'items': <Object>[],
  });
  final place = findPhoto(photo, await phone.screenshot(), wholeScreen);
  expect(
    place == null || place.difference > samePictureLimit,
    isTrue,
    reason: 'the photo just taken shows on the screen',
  );
}

/// Given: a photo was just taken, so sketch 3 is showing, and its read may
/// still be going on. Returns the photo.
Future<img.Image> givenPhotoTaken() async {
  await givenCameraScreenOpen();
  final tappedAt = await tapShutter();
  await expectReadingScreenOpensWithoutHome();
  return keptPhotoSince(tappedAt);
}

/// Given: a photo was just taken and has been read, so nothing on the screen
/// changes by itself any more. Returns the photo.
///
/// The read finds all three fields of `fullTicketText`, and the saved feed
/// gives it 4b. This needs the app started from ticket_text_app.dart, or an
/// app built on it, with the reads held.
Future<img.Image> givenAnswerScreenOpen() async {
  final photo = await givenPhotoTaken();
  await expectReadAsked(0);
  final latestRead = (await readerReport()).reads.length - 1;
  await finishRead(latestRead, fullTicketText);
  await expectAnswerScreen(fullTicketAnswer);
  return photo;
}

/// Given: a photo was taken earlier, and the person is back on the home screen.
Future<img.Image> givenPhotoTakenEarlier() async {
  final photo = await givenAnswerScreenOpen();
  await phone.pressBackButton();
  await expectHomeScreenShows();
  return photo;
}

/// Whether the screen is one that follows the shutter: sketch 3, an answer
/// screen or 4d.
bool _looksLikeScanScreen(AppScreen screen) =>
    showsReading(screen) ||
    screen.texts.any(
      (item) => [
        ...answerTitles,
        couldNotReadText,
      ].any((title) => tidy(item.label).startsWith(title)),
    );

/// Then: the home screen shows and stays, and no screen that follows the
/// shutter (sketch 3, an answer screen or 4d) appears on the way there or just
/// after.
Future<void> expectHomeScreenShowsWithNoScanScreen() async {
  var seen = <String>[];
  Future<void> look() async {
    final screen = await appScreen();
    if (seen.isEmpty && _looksLikeScanScreen(screen)) seen = shownLines(screen);
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
  expect(seen, isEmpty, reason: 'a screen of the earlier scan appeared');
  expect(
    isHome && await isHomeScreenShowing(),
    isTrue,
    reason:
        'the home screen did not show. In front: '
        '${await phone.windowInFront()}',
  );
}
