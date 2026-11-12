import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'answers.dart';
import 'app_screen.dart';
import 'driven_app.dart';
import 'photo_screen.dart';
import 'ticket_fields.dart';

export 'answers.dart';

// Shared by the tests for ticket #31, which run on the Mac, and the older tests
// it changed: what each full answer screen is (4a, 4b, 4c, "too old" and
// "couldn't load"), its ticket card, and how its buttons, its stillness and its
// scrolling are checked. The ticket leaves open how the screens are built, so
// they're recognised the way a person recognises them: by their words, top to
// bottom, and their one button. Their colours and icons are manual steps.

/// One prize as 4a shows it: "Bạn trúng" and its name, then the amount.
typedef Prize = ({String name, String amount});

/// A full answer screen: its words from the title down, and its one button.
class AnswerScreen {
  const AnswerScreen._(this.name, this.words, this.button);

  final String name;

  /// The title first.
  final List<String> words;
  final String button;

  String get title => words.first;

  /// Every word on it, top to bottom, the button last.
  List<String> get allWords => [...words, button];

  @override
  String toString() => '$name ($allWords)';
}

/// 4a: one block per prize, in the order given.
AnswerScreen wonScreen(List<Prize> prizes, String card) =>
    AnswerScreen._('4a', [
      wonTitle,
      for (final prize in prizes) ...[wonLine(prize.name), prize.amount],
      card,
    ], scanAnotherLabel);

/// 4b.
AnswerScreen lostScreen(String card) =>
    AnswerScreen._('4b', [lostTitle, lostHint, card], scanAnotherLabel);

/// 4c. [date] is DD/MM/YYYY, for a draw that isn't today.
AnswerScreen notDrawnScreen(String province, String card, {String? date}) =>
    AnswerScreen._('4c', [
      notDrawnTitle,
      notDrawnHint(province, date: date),
      card,
    ], scanAnotherLabel);

const tooOldScreen = AnswerScreen._('"too old"', [
  tooOldTitle,
  tooOldHint,
], scanAnotherLabel);

const couldNotLoadScreen = AnswerScreen._('"couldn\'t load"', [
  couldNotLoadTitle,
  couldNotLoadHint,
], tryAgainLabel);

/// A ticket's ML Kit text with all three fields, and the answer screen it gets
/// from the saved feed. For tests that need a read to work but aren't about
/// the rule or the answer. Bến Tre is drawn on 10/11/2026 in the saved feed,
/// and 123456 wins nothing there, so it's 4b, which shows the ticket card.
const fullTicketText =
    'XỔ SỐ KIẾN THIẾT\n'
    'BẾN TRE\n'
    '10-11-2026  LOẠI VÉ 10.000Đ\n'
    '123456';
final fullTicketAnswer = lostScreen(
  ticketCard(number: '123456', province: 'Bến Tre', date: '10/11/2026'),
);

/// Then: [expected] shows: from its title down, its words are exactly its
/// own, top to bottom, and its button is the only one. With [photo], the photo
/// isn't anywhere on screen either.
Future<void> expectAnswerScreen(
  AnswerScreen expected, {
  img.Image? photo,
}) async {
  var screen = await appScreen();
  final isShowing = await waitUntil(() async {
    screen = await appScreen();
    return showsOnly(screen, expected.words, expected.button);
  });
  expect(
    isShowing,
    isTrue,
    reason:
        '${expected.name} did not show: from "${expected.title}" down, the '
        'words must be exactly ${expected.allWords}, and "${expected.button}" '
        'its one button. On screen: ${shownLines(screen)}. Buttons: '
        '${screen.buttons}',
  );
  if (photo != null) await expectNoPhotoAnywhere(photo);
}

/// Lines that belong to the temporary screen ticket #31 removed.
const _fieldLineStarts = ['Số vé', 'Tỉnh:', 'Ngày:'];

const _watchStep = Duration(milliseconds: 40);

/// Then: from now until [expected] shows, the screen is sketch 3, or nothing
/// for a moment while it changes, or on its way to [expected]: no field
/// lines, no other answer and no 4d ever show.
Future<void> expectOnlyReadingUntil(AnswerScreen expected) async {
  final otherTitles = [
    for (final title in [...answerTitles, couldNotReadText])
      if (title != expected.title) title,
  ];
  final giveUpAt = DateTime.now().add(screenChangeTimeout);
  while (true) {
    final screen = await appScreen();
    if (showsOnly(screen, expected.words, expected.button)) return;
    final lines = shownLines(screen);
    final wrong = lines.where(
      (line) =>
          _fieldLineStarts.any(line.startsWith) ||
          otherTitles.any(line.startsWith),
    );
    expect(
      wrong,
      isEmpty,
      reason:
          'between sketch 3 and ${expected.name}, something else showed. On '
          'screen: $lines',
    );
    if (DateTime.now().isAfter(giveUpAt)) {
      fail('${expected.name} did not show. On screen: $lines');
    }
    await Future<void>.delayed(_watchStep);
  }
}

/// The ticket card's three parts, as `Vé <number> · <province> · <date>`
/// reads anywhere on screen, or null if there's no card.
({String number, String province, String date})? _cardOn(AppScreen screen) {
  final words = tidy(shownLines(screen).join(' '));
  final card = RegExp(r'Vé (\S+) · (.+?) · (\d{2}/\d{2}/\d{4})')
      .firstMatch(words);
  if (card == null) return null;
  return (number: card[1]!, province: card[2]!, date: card[3]!);
}

/// Then: an answer screen shows the ticket card, and the card's parts that
/// are given here read as given. The date is DD/MM/YYYY.
Future<void> expectCardShows({
  String? number,
  String? province,
  String? date,
}) async {
  var screen = await appScreen();
  await waitUntil(() async {
    screen = await appScreen();
    return _cardOn(screen) != null;
  });
  final card = _cardOn(screen);
  expect(
    card,
    isNotNull,
    reason:
        'no ticket card "Vé <số> · <tỉnh> · <DD/MM/YYYY>" on screen. On '
        'screen: ${shownLines(screen)}',
  );
  if (number != null) {
    expect(card!.number, number, reason: 'the number on the ticket card');
  }
  if (province != null) {
    expect(card!.province, province, reason: 'the province on the card');
  }
  if (date != null) {
    expect(card!.date, date, reason: 'the date on the ticket card');
  }
}

/// A page change takes about this long to settle on the emulator.
const _pageChangeTime = Duration(milliseconds: 700);

/// How long "nothing moves" is watched.
const _stillWatch = Duration(seconds: 3);

/// A screen that stands still changes no sampled pixel. This leaves room for
/// one or two to flicker.
const _stillLimit = 3;

/// Then: nothing on the screen moves. From a moment after the screen showed,
/// so its page change has settled, every screenshot for 3 seconds is the same
/// as the first.
Future<void> expectNothingMoves() async {
  await Future<void>.delayed(_pageChangeTime);
  final first = await phone.screenshot();
  final stopAt = DateTime.now().add(_stillWatch);
  var looks = 0;
  while (DateTime.now().isBefore(stopAt)) {
    final later = await phone.screenshot();
    looks++;
    final changed = later.changedPixels(first);
    expect(
      changed,
      lessThan(_stillLimit),
      reason: 'something on the screen moved: $changed sampled pixels changed',
    );
  }
  expect(looks, greaterThan(1), reason: 'SETUP: no time to watch');
}

/// "Large type": an amount's text is at least this many times as tall as the
/// "Bạn trúng" text above it.
const _largeTypeShare = 1.25;

/// Then: each prize's amount is in larger type than its "Bạn trúng" line. When
/// the two are drawn as one text, their sizes can't be told apart here, and
/// the manual step shows it.
Future<void> expectAmountsInLargeType(List<Prize> prizes) async {
  final screen = await appScreen();
  for (final prize in prizes) {
    final amounts = screen.texts.where((t) => tidy(t.label) == prize.amount);
    final lines = screen.texts.where(
      (t) => tidy(t.label) == wonLine(prize.name),
    );
    if (amounts.isEmpty || lines.isEmpty) continue;
    expect(
      amounts.first.height,
      greaterThanOrEqualTo(lines.first.height * _largeTypeShare),
      reason:
          '"${prize.amount}" is not in larger type than '
          '"${wonLine(prize.name)}": ${amounts.first} and ${lines.first}',
    );
  }
}

const _mostSwipes = 20;

/// Long enough for a slow swipe's glide to stop.
const _swipeSettleTime = Duration(milliseconds: 1200);

bool _isOnScreen(ScreenItem item, AppScreen screen) =>
    item.centerY >= screen.barsTop &&
    item.centerY <= screen.height - screen.barsBottom;

bool _isWholeOnScreen(ScreenItem item, AppScreen screen) =>
    item.top >= screen.barsTop - 1 &&
    item.bottom <= screen.height - screen.barsBottom + 1;

/// Then: everything on [expected] can be seen by scrolling: swiping up from
/// the top until the screen stops moving, the lines that come into view are
/// exactly its words, in order, and its button comes whole into view. On a
/// screen that fits, nothing moves and everything is already in view.
Future<void> expectEverythingSeenByScrolling(AnswerScreen expected) async {
  await waitUntil(
    () async => wordsFrom(await appScreen(), expected.title) != null,
  );
  final seen = <String>[];
  var isButtonSeenWhole = false;
  String? before;
  for (var swipes = 0; ; swipes++) {
    final screen = await appScreen();
    final lines = linesOf(screen.texts.where((t) => _isOnScreen(t, screen)));
    for (final line in lines) {
      if (!seen.contains(line)) seen.add(line);
    }
    isButtonSeenWhole =
        isButtonSeenWhole ||
        screen.buttons.any(
          (button) =>
              tidy(button.label) == expected.button &&
              _isWholeOnScreen(button, screen),
        );
    final now = lines.join('\n');
    if (now == before || swipes >= _mostSwipes) break;
    before = now;
    await phone.swipeUp(
      x: screen.width ~/ 2,
      fromY: (screen.height * 0.7).round(),
      toY: (screen.height * 0.4).round(),
      milliseconds: 1000,
    );
    await Future<void>.delayed(_swipeSettleTime);
  }
  final fromTitle = seen.skipWhile((line) => !line.startsWith(expected.title));
  expect(
    tidy(fromTitle.join(' ')),
    tidy(expected.allWords.join(' ')),
    reason:
        'swiping from the top to the end of ${expected.name}, the lines that '
        'came into view, in order, must be exactly ${expected.allWords}. Seen: '
        '$seen',
  );
  expect(
    isButtonSeenWhole,
    isTrue,
    reason: '"${expected.button}" never came whole into view',
  );
}

/// Then: the home screen shows, and is still there a moment later.
Future<void> expectHomeScreenShowsAndStays() async {
  await expectHomeScreenShows();
  await Future<void>.delayed(settleTime);
  await expectHomeScreenShows();
}

/// Saves a screenshot for the manual steps, as `<name>.png` in the folder
/// named by `ANSWER_SCREENSHOTS`, when it's set. Nothing is saved otherwise.
Future<void> saveScreenshotIfAsked(String name) async {
  final folder = Platform.environment['ANSWER_SCREENSHOTS'];
  if (folder == null || folder.isEmpty) return;
  await phone.saveScreenshot('$folder/$name.png');
}

String _twoDigits(int number) => number.toString().padLeft(2, '0');

/// [day] as a ticket prints it, DD-MM-YYYY.
String ticketDate(DateTime day) =>
    '${_twoDigits(day.day)}-${_twoDigits(day.month)}-${day.year}';

/// A miền Nam province drawn on [day]'s weekday: as ML Kit reads it on the
/// ticket, and as the app shows it. The app doesn't need it to be drawn that
/// day, but a real ticket would be.
({String read, String shown}) provinceDrawnOn(DateTime day) =>
    switch (day.weekday) {
      DateTime.monday => (read: 'CÀ MAU', shown: 'Cà Mau'),
      DateTime.tuesday => (read: 'BẾN TRE', shown: 'Bến Tre'),
      DateTime.wednesday => (read: 'CẦN THƠ', shown: 'Cần Thơ'),
      DateTime.thursday => (read: 'AN GIANG', shown: 'An Giang'),
      DateTime.friday => (read: 'VĨNH LONG', shown: 'Vĩnh Long'),
      DateTime.saturday => (read: 'LONG AN', shown: 'Long An'),
      _ => (read: 'TIỀN GIANG', shown: 'Tiền Giang'),
    };
