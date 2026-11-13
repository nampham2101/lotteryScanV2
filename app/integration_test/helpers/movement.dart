import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'driven_app.dart';
import 'phone.dart';
import 'ticket_fields.dart';

// Shared by the tests of ticket #32, which run on the Mac, and the tests of
// ticket #31 it changed: whether the app is moving, as the app itself reports
// it (movement_report.dart), pressing while it moves, and comparing a still
// screen with a screenshot ticket #31 saved. Only the tests on the Mac use
// this, so it must not import Flutter.

Future<bool> _orderMovement(String order) async {
  final response = await driver.serviceClient.callServiceExtension(
    'ext.lotteryscan.movement',
    isolateId: driver.appIsolate.id,
    args: {'do': order},
  );
  return response.json!['isMoving'] as bool;
}

/// Whether anything on the app's screen is moving now.
Future<bool> isAppMoving() => _orderMovement('look');

/// When the person presses the phone's back button, done inside the app so it
/// lands at once. Returns whether the app was moving at that moment.
Future<bool> pressBackInApp() => _orderMovement('back');

/// When the person taps the button that reads [label], done inside the app so
/// it lands at once. Flutter Driver would otherwise wait for any movement to
/// stop before tapping.
Future<void> tapInApp(String label) =>
    driver.runUnsynchronized(() => driver.tap(find.text(label)));

const _quickLook = Duration(milliseconds: 10);

/// Waits until a screen whose title starts with [title] shows, looking as
/// often as the app answers. Returns when it was first seen.
Future<DateTime> waitForTitle(String title) async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout);
  while (true) {
    final screen = await appScreen();
    if (wordsFrom(screen, title) != null) return DateTime.now();
    if (DateTime.now().isAfter(giveUpAt)) {
      fail('"$title" did not show. On screen: ${shownLines(screen)}');
    }
    await Future<void>.delayed(_quickLook);
  }
}

/// A page change takes 450 ms on Android. From this long after a screen first
/// shows, a movement on it is its own, not the page change.
const afterPageChange = Duration(milliseconds: 500);

/// Looks for movement from [from] to [until] after [shownAt]. Returns how long
/// after [shownAt] it was first seen, or null if nothing moved.
Future<Duration?> movingSeen(
  DateTime shownAt, {
  required Duration from,
  required Duration until,
}) async {
  final startAt = shownAt.add(from);
  final now = DateTime.now();
  if (now.isBefore(startAt)) {
    await Future<void>.delayed(startAt.difference(now));
  }
  while (DateTime.now().isBefore(shownAt.add(until))) {
    if (await isAppMoving()) return DateTime.now().difference(shownAt);
    await Future<void>.delayed(_quickLook);
  }
  return null;
}

/// "The movement has ended": nothing has moved for this long.
const _quietFor = Duration(seconds: 1);

/// The movement is over by this long after this starts waiting, or it never
/// ends.
const _longestMovement = Duration(seconds: 10);

const _movementLook = Duration(milliseconds: 50);

/// Waits until nothing on the app's screen has moved for a second.
Future<void> waitUntilMovementEnds() async {
  final giveUpAt = DateTime.now().add(_longestMovement);
  DateTime? stillSince;
  while (true) {
    final now = DateTime.now();
    if (await isAppMoving()) {
      stillSince = null;
    } else {
      stillSince ??= now;
      if (now.difference(stillSince) >= _quietFor) return;
    }
    if (now.isAfter(giveUpAt)) {
      fail('the screen was still moving ${_longestMovement.inSeconds} s on');
    }
    await Future<void>.delayed(_movementLook);
  }
}

/// Then: nothing on the app's screen moves for [howLong].
Future<void> expectStillFor(Duration howLong, {required String reason}) async {
  final stopAt = DateTime.now().add(howLong);
  while (DateTime.now().isBefore(stopAt)) {
    expect(await isAppMoving(), isFalse, reason: reason);
    await Future<void>.delayed(_movementLook);
  }
}

/// How long until [isDone], looking as often as the app answers.
Future<Duration> timeUntil(
  Future<bool> Function() isDone, {
  required String reason,
}) async {
  final startedAt = DateTime.now();
  while (!await isDone()) {
    final waited = DateTime.now().difference(startedAt);
    if (waited > screenChangeTimeout) fail(reason);
    await Future<void>.delayed(_quickLook);
  }
  return DateTime.now().difference(startedAt);
}

/// Starts recording the screen for the manual steps, saved as `<name>.mp4` in
/// the folder named by `MOVEMENT_RECORDINGS`, when it's set. Returns what
/// stops and saves it. Nothing is recorded otherwise.
Future<Future<void> Function()> recordScreenIfAsked(String name) async {
  final folder = Platform.environment['MOVEMENT_RECORDINGS'];
  if (folder == null || folder.isEmpty) return () async {};
  return phone.recordScreen('$folder/$name.mp4');
}

/// Where ticket #31 saved its screenshots, from app/, where the tests run.
const evidenceOf31 = '../docs/evidence/31';

/// The screenshot at [path] as the emulator gives its screen, so the two
/// compare the way ticket #31's "nothing moves" compares screenshots.
ScreenPixels _savedScreen(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'SETUP: $path is missing');
  final saved = img.decodePng(file.readAsBytesSync())!;
  final header = ByteData(16)
    ..setUint32(0, saved.width, Endian.little)
    ..setUint32(4, saved.height, Endian.little)
    ..setUint32(8, 1, Endian.little);
  return ScreenPixels([
    ...header.buffer.asUint8List(),
    ...saved.getBytes(order: img.ChannelOrder.rgba),
  ]);
}

/// A screen that hasn't changed changes no sampled pixel. As in ticket #31's
/// "nothing moves", this leaves room for one or two to flicker.
const _sameLimit = 3;

/// Then: the screen looks exactly as the screenshot at [path], apart from the
/// phone's own bars.
Future<void> expectScreenAsSaved(String path) async {
  final saved = _savedScreen(path);
  final now = await phone.screenshot();
  expect(
    '${now.width} x ${now.height}',
    '${saved.width} x ${saved.height}',
    reason: 'SETUP: the emulator\'s screen is not the size it was for $path',
  );
  final changed = now.changedPixels(saved);
  expect(
    changed,
    lessThan(_sameLimit),
    reason:
        'the screen is not exactly as $path: $changed sampled pixels differ',
  );
}
