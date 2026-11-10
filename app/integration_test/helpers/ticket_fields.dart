import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'app_screen.dart';
import 'driven_app.dart';
import 'photo_screen.dart';

// Shared by the tests for ticket #24, which run on the Mac, and by the tests of
// tickets #10, #18 and #22 that ticket #24 changed: the three lines the
// temporary screen shows once the ticket's fields are read, and what screen 4d
// ("Không đọc được vé", sketch 4d) is.

const numberLabel = 'Số vé:';
const provinceLabel = 'Tỉnh:';
const dateLabel = 'Ngày:';

/// Sketch 4d's words, top to bottom. Its title is the same words as
/// `couldNotReadText`.
const cantReadHint = 'Chụp lại ở nơi đủ sáng, giữ vé phẳng và rõ nét.';
const tryAgainLabel = 'Thử lại';

/// A ticket's ML Kit text with all three fields, and the lines the screen
/// shows for it. For tests that need the read to work but aren't about the
/// rule itself.
const fullTicketText =
    'XỔ SỐ KIẾN THIẾT\n'
    'BẾN TRE\n'
    '05-11-2026  LOẠI VÉ 10.000Đ\n'
    '123456';
const fullTicketLines = ['Số vé: 123456', 'Tỉnh: Bến Tre', 'Ngày: 05-11-2026'];

/// The three lines, in their order on screen.
List<String> fieldLines({
  required String number,
  required String province,
  required String date,
}) => ['$numberLabel $number', '$provinceLabel $province', '$dateLabel $date'];

String _tidy(String line) => line.replaceAll(RegExp(r'\s+'), ' ').trim();

bool _isOneLine(ScreenItem item) => !item.label.contains('\n');

/// The words on screen as a person reads them, top to bottom, one entry per
/// line. Texts side by side on one line, such as `Số vé:` and `871723` drawn
/// apart, count as one line. A text that holds line breaks gives one entry for
/// each of its lines. Runs of spaces count as one space.
List<String> shownLines(AppScreen screen) => _linesOf(screen.texts);

List<String> _linesOf(Iterable<ScreenItem> items) {
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
        _tidy(line),
  ];
}

/// Then: the lines on screen are exactly [lines], top to bottom, and nothing
/// else is written there.
Future<void> expectOnlyLinesAre(List<String> lines) async {
  var shown = <String>[];
  await waitUntil(() async {
    shown = shownLines(await appScreen());
    return _same(shown, lines);
  });
  expect(shown, lines, reason: 'the words on screen, top to bottom');
}

/// Then: nothing changes for a while: only [lines] stay written on screen.
Future<void> expectOnlyLinesStay(List<String> lines) async {
  await Future<void>.delayed(settleTime);
  expect(shownLines(await appScreen()), lines);
}

bool _same(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);

/// Then: the screen's line for [label] reads `[label] [value]`, and it's the
/// only line for [label].
Future<void> expectFieldShows(String label, String value) async {
  var screen = await appScreen();
  List<String> fieldLinesOn(AppScreen screen) => [
    for (final line in shownLines(screen))
      if (line.startsWith(label)) line,
  ];
  await waitUntil(() async {
    screen = await appScreen();
    return fieldLinesOn(screen).isNotEmpty;
  });
  expect(fieldLinesOn(screen), [
    '$label $value',
  ], reason: 'the line for "$label". On screen: ${shownLines(screen)}');
}

/// Whether the screen is 4d: its words, top to bottom, are exactly the title,
/// the hint and "Thử lại", and "Thử lại" is its one button. A line break in
/// place of a space is allowed. Something that can't be tapped above the
/// title, such as the icon given a name for screen readers, isn't counted.
bool is4d(AppScreen screen) {
  final titles = screen.texts.where(
    (item) => _tidy(item.label).startsWith(couldNotReadText),
  );
  if (titles.isEmpty) return false;
  final titleTop = titles.first.top;
  final counted = screen.texts.where(
    (item) => item.canTap || item.bottom > titleTop,
  );
  final words = _tidy(_linesOf(counted).join(' '));
  final buttons = screen.buttons;
  return words == _tidy('$couldNotReadText $cantReadHint $tryAgainLabel') &&
      buttons.length == 1 &&
      _tidy(buttons.single.label) == tryAgainLabel;
}

/// Then: screen 4d shows in place of the temporary screen: its title, its hint
/// and its one button "Thử lại", top to bottom, nothing else written, and no
/// photo. How it looks is manual step 1.
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

/// When the person taps "Thử lại" on screen 4d.
Future<void> tapTryAgain() async {
  final button = (await appScreen()).buttons.singleWhere(
    (item) => _tidy(item.label) == tryAgainLabel,
  );
  await phone.tap(button.centerX.round(), button.centerY.round());
}

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
