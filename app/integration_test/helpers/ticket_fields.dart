import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'app_screen.dart';
import 'driven_app.dart';
import 'photo_screen.dart';

// Shared by the tests for ticket #24, which run on the Mac, and by the tests of
// tickets #10, #18, #22, #28 and #31: how the words on screen are read, top to
// bottom, and what screen 4d ("Không đọc được vé", sketch 4d) is. Since ticket
// #31 the temporary screen and its three lines (`Số vé:`, `Tỉnh:`, `Ngày:`)
// are gone: the fields read show on the answer screens' ticket card, which
// answer_screens.dart reads.

/// Sketch 4d's words, top to bottom. Its title is the same words as
/// `couldNotReadText`.
const cantReadHint = 'Chụp lại ở nơi đủ sáng, giữ vé phẳng và rõ nét.';
const tryAgainLabel = 'Thử lại';

/// [line] with every run of spaces and line breaks as one space.
String tidy(String line) => line.replaceAll(RegExp(r'\s+'), ' ').trim();

bool _isOneLine(ScreenItem item) => !item.label.contains('\n');

/// The words on screen as a person reads them, top to bottom, one entry per
/// line. Texts side by side on one line, such as `Vé 871723` and `· Bạc Liêu`
/// drawn apart, count as one line. A text that holds line breaks gives one
/// entry for each of its lines. Runs of spaces count as one space.
List<String> shownLines(AppScreen screen) => linesOf(screen.texts);

/// [items] as lines, the way [shownLines] reads the whole screen.
List<String> linesOf(Iterable<ScreenItem> items) {
  final texts = items.toList()
    ..sort((a, b) {
      final byTop = a.top.compareTo(b.top);
      return byTop != 0 ? byTop : a.left.compareTo(b.left);
    });
  final rows = <List<ScreenItem>>[];
  for (final item in texts) {
    final row = rows.isEmpty ? null : rows.last;
    final isSameLine =
        row != null &&
        _isOneLine(item) &&
        row.every(_isOneLine) &&
        item.centerY >= row.first.top &&
        item.centerY <= row.first.bottom;
    if (isSameLine) {
      row.add(item);
    } else {
      rows.add([item]);
    }
  }
  return [
    for (final row in rows)
      for (final line
          in (row..sort((a, b) => a.left.compareTo(b.left)))
              .map((item) => item.label)
              .join(' ')
              .split('\n'))
        tidy(line),
  ];
}

/// The words on screen from the first text that starts with [titleStart] down,
/// as one line of words, or null if no text starts with it. Something that
/// can't be tapped above the title, such as an icon given a name for screen
/// readers, isn't counted.
String? wordsFrom(AppScreen screen, String titleStart) {
  final titles = screen.texts.where(
    (item) => tidy(item.label).startsWith(titleStart),
  );
  if (titles.isEmpty) return null;
  final titleTop = titles.first.top;
  final counted = screen.texts.where(
    (item) => item.canTap || item.bottom > titleTop,
  );
  return tidy(linesOf(counted).join(' '));
}

/// Whether the screen's words, top to bottom from its title, are exactly
/// [words] and then [button], and [button] is its one button. The first of
/// [words] is the title. A line break in place of a space is allowed.
bool showsOnly(AppScreen screen, List<String> words, String button) {
  final buttons = screen.buttons;
  return wordsFrom(screen, words.first) == tidy([...words, button].join(' ')) &&
      buttons.length == 1 &&
      tidy(buttons.single.label) == button;
}

/// Whether the screen is 4d: its words, top to bottom, are exactly the title,
/// the hint and "Thử lại", and "Thử lại" is its one button.
bool is4d(AppScreen screen) =>
    showsOnly(screen, [couldNotReadText, cantReadHint], tryAgainLabel);

/// Then: screen 4d shows: its title, its hint and its one button "Thử lại",
/// top to bottom, nothing else written, and no photo. How it looks is ticket
/// #24's manual step 1.
Future<void> expect4dShows(img.Image photo) async {
  var screen = await appScreen();
  final isShowing = await waitUntil(() async {
    screen = await appScreen();
    return is4d(screen);
  });
  expect(
    isShowing,
    isTrue,
    reason:
        'screen 4d did not show: it must have "$couldNotReadText", '
        '"$cantReadHint" and a "$tryAgainLabel" button, and nothing else. On '
        'screen: ${screen.items}',
  );
  await expectScreenDoesNotShow(photo);
}

/// When the person taps the button that reads [label].
Future<void> tapButton(String label) async {
  final button = (await appScreen()).buttons.singleWhere(
    (item) => tidy(item.label) == label,
  );
  await phone.tap(button.centerX.round(), button.centerY.round());
}

/// When the person taps "Thử lại" on screen 4d, or on "couldn't load".
Future<void> tapTryAgain() => tapButton(tryAgainLabel);

/// Then: the camera screen opens with its shutter, Android says the app is
/// using the camera, and it's still there a moment later.
Future<void> expectCameraScreenOpensAndStays() async {
  await expectCameraScreenOpens();
  await expectAppUsingCamera();
  await findShutter();
  await Future<void>.delayed(settleTime);
  expect(
    await isCameraScreenShowing(),
    isTrue,
    reason:
        'the camera screen did not stay. In front: '
        '${await phone.windowInFront()}',
  );
}
