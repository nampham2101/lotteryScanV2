import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'answers.dart';
import 'driven_app.dart';
import 'photo_hash.dart';
import 'photo_screen.dart';
import 'ticket_fields.dart';

// Shared by the tests for ticket #18, which run on the Mac, and the tickets
// after it: how they give orders to ML Kit's stand-in in ticket_text_app.dart,
// and, since ticket #31, that sketch 3 shows while it reads.

/// A real read on the emulator can take longer than a screen change.
const _realReadTimeout = Duration(seconds: 45);

const _mostSwipes = 40;

/// Long enough for a swipe's glide to stop.
const _swipeSettleTime = Duration(milliseconds: 1500);

/// One time the app asked ML Kit to read a photo.
class ReadSeen {
  ReadSeen.fromJson(Map<String, dynamic> json)
    : photoHash = json['photoHash'] as int?,
      isFinished = json['isFinished'] as bool,
      text = json['text'] as String?,
      failure = json['failure'] as String?;

  final int? photoHash;
  final bool isFinished;
  final String? text;

  /// Why real ML Kit gave no answer.
  final String? failure;
}

/// Something on screen that scrolls. Its place is in phone pixels.
class ScrollArea {
  ScrollArea.fromJson(Map<String, dynamic> json)
    : position = (json['position'] as num).toDouble(),
      end = (json['end'] as num).toDouble(),
      left = (json['left'] as num).toDouble(),
      top = (json['top'] as num).toDouble(),
      right = (json['right'] as num).toDouble(),
      bottom = (json['bottom'] as num).toDouble();

  final double position;
  final double end;
  final double left;
  final double top;
  final double right;
  final double bottom;

  bool get isAtEnd => position >= end - 1;
}

class ReaderReport {
  ReaderReport.fromJson(Map<String, dynamic> json)
    : reads = [
        for (final read in json['reads'] as List<dynamic>)
          ReadSeen.fromJson(read as Map<String, dynamic>),
      ],
      errors = (json['errors'] as List<dynamic>).cast<String>(),
      scrollAreas = [
        for (final area in json['scrollAreas'] as List<dynamic>)
          ScrollArea.fromJson(area as Map<String, dynamic>),
      ];

  final List<ReadSeen> reads;
  final List<String> errors;
  final List<ScrollArea> scrollAreas;
}

Future<ReaderReport> _orderReader(Map<String, String> order) async {
  final response = await driver.serviceClient.callServiceExtension(
    'ext.lotteryscan.reader',
    isolateId: driver.appIsolate.id,
    args: order,
  );
  return ReaderReport.fromJson(response.json!);
}

Future<ReaderReport> readerReport() => _orderReader({'do': 'report'});

/// From now on, no read finishes until a test says so.
Future<void> holdReads() => _orderReader({'do': 'start'});

/// From now on, real ML Kit reads the photos.
Future<void> useRealReader() => _orderReader({'do': 'start', 'reader': 'real'});

/// ML Kit finishes read number [read] of this test, counted from 0, and gives
/// [text] as its `text` value. An empty text is a photo with nothing to read.
Future<void> finishRead(int read, String text) =>
    _orderReader({'do': 'finish', 'read': '$read', 'text': text});

/// ML Kit's read number [read] fails.
Future<void> failRead(int read) =>
    _orderReader({'do': 'fail', 'read': '$read'});

/// Waits for the app to have asked ML Kit for read number [read].
Future<void> expectReadAsked(int read) async {
  expect(
    await waitUntil(() async => (await readerReport()).reads.length > read),
    isTrue,
    reason: 'the app did not ask ML Kit to read the photo',
  );
}

/// What ML Kit answered in a read that real ML Kit does, once it has finished.
Future<ReadSeen> finishedRealRead(int read) async {
  await expectReadAsked(read);
  expect(
    await waitUntil(
      () async => (await readerReport()).reads[read].isFinished,
      timeout: _realReadTimeout,
    ),
    isTrue,
    reason: 'real ML Kit did not finish',
  );
  return (await readerReport()).reads[read];
}

/// Then: what ML Kit was given for read number [read] is the photo kept now.
Future<void> expectReadWasOfKeptPhoto(int read) async {
  expect(
    (await readerReport()).reads[read].photoHash,
    photoHash(await newestPhotoFile()),
    reason: 'ML Kit was given something other than the photo just taken',
  );
}

/// Then: sketch 3 is showing, and still is a while later.
Future<void> expectReadingScreenStays() async {
  var screen = await appScreen();
  await waitUntil(() async {
    screen = await appScreen();
    return isReadingScreen(screen);
  });
  await Future<void>.delayed(settleTime);
  screen = await appScreen();
  expect(
    isReadingScreen(screen),
    isTrue,
    reason:
        'sketch 3 did not stay, with only "$readingTitle" and "$readingHint". '
        'On screen: ${shownLines(screen)}',
  );
}

/// Then: the app has had no error since this test began.
Future<void> expectNoAppErrors() async {
  expect((await readerReport()).errors, isEmpty);
}

/// Given: a photo was just taken and ML Kit is still reading it, read number
/// [read], so sketch 3 shows. Returns the photo.
Future<img.Image> givenReadingShows({int read = 0}) async {
  final photo = await givenPhotoTaken();
  await expectReadAsked(read);
  expect(
    isReadingScreen(await appScreen()),
    isTrue,
    reason: 'sketch 3 did not stay while ML Kit was reading',
  );
  return photo;
}

/// When the person goes home, then takes a new photo of a different view while
/// ML Kit reads it, read number [read]. Returns the new photo. Call
/// `phone.turnCameraBack` when the test ends.
Future<img.Image> leaveAndTakeNewPhoto({int read = 1}) async {
  await phone.pressBackButton();
  await expectHomeScreenShows();
  await phone.turnCamera();
  return givenReadingShows(read: read);
}

/// The part of the screen that scrolls, once the text is showing. There must
/// be one, because the text doesn't fit.
Future<ScrollArea> scrollingTextArea() async {
  ScrollArea? area;
  await waitUntil(() async {
    final scrolling = (await readerReport()).scrollAreas.where(
      (area) => area.end > 0,
    );
    area = scrolling.isEmpty ? null : scrolling.first;
    return area != null;
  });
  expect(
    area,
    isNotNull,
    reason:
        'nothing scrolls, though the text is longer than the space. On screen: '
        '${(await appScreen()).items}',
  );
  return area!;
}

/// One finger swiping up on [area].
Future<void> _swipeUp(ScrollArea area) {
  final height = area.bottom - area.top;
  return phone.swipeUp(
    x: (area.left + area.right) ~/ 2,
    fromY: (area.top + height * 0.8).round(),
    toY: (area.top + height * 0.2).round(),
  );
}

/// When the person swipes on the text until it stops moving. Returns the area
/// as it ends up.
Future<ScrollArea> swipeToEndOfText() async {
  var area = await scrollingTextArea();
  for (var swipes = 0; swipes < _mostSwipes && !area.isAtEnd; swipes++) {
    await _swipeUp(area);
    await Future<void>.delayed(_swipeSettleTime);
    area = await scrollingTextArea();
  }
  return area;
}
