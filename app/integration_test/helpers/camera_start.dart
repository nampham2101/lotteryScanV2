import 'package:test/test.dart';

import 'app_screen.dart';
import 'driven_app.dart';
import 'refused_camera.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

// Shared by the "Camera won't start" tests of ticket #24, which run on the Mac:
// how they tell camera_start_app.dart to make the camera refuse or fail, and
// what the home screen must show then.

const cameraErrorNote = 'Lỗi camera, thử lại';

/// "Fades after about 3 seconds": the note is seen for at least this long...
/// Watching takes a moment between looks, so a note shown for 3 seconds is
/// seen for a little less.
const _shortestNote = Duration(seconds: 2);

/// ...and is gone by this long after it was first seen. This leaves room for
/// the note sliding in and out.
const _longestNote = Duration(milliseconds: 4500);

/// A note gone for this long has gone, not just been redrawn.
const _goneFor = Duration(seconds: 1);

const _watchStep = Duration(milliseconds: 40);

/// How often the camera was asked to start since the test began, and went
/// wrong because the test said so.
typedef CameraStarts = ({int refused, int failed});

Future<CameraStarts> _orderCamera(String order) async {
  final response = await driver.serviceClient.callServiceExtension(
    'ext.lotteryscan.cameraStart',
    isolateId: driver.appIsolate.id,
    args: {'do': order},
  );
  final json = response.json!;
  return (
    refused: json['refusedStarts'] as int,
    failed: json['failedStarts'] as int,
  );
}

Future<CameraStarts> _cameraStarts() => _orderCamera('report');

/// The camera starts as normal, until a test says otherwise.
Future<void> letCameraStart() => _orderCamera('start');

/// Given: camera access has been refused. Every camera start from now on is
/// refused.
Future<void> givenCameraAccessRefused() => _orderCamera('refuse');

/// Given: the camera fails to start for a reason other than refused access.
/// Every camera start from now on fails.
Future<void> givenCameraFailsToStart() => _orderCamera('fail');

/// Given: screen 4d shows, with the camera able to start until now.
Future<void> given4dShows() async {
  final photo = await givenReadingShows();
  await finishRead(0, '');
  await expect4dShows(photo);
}

/// Given: the home screen shows, with camera access allowed.
Future<void> givenHomeScreenWithCameraAllowed() async {
  await givenHomeScreen();
  await givenCameraAllowed();
}

Future<String> _whatHappened(AppScreen screen) async {
  final starts = await _cameraStarts();
  return 'On screen: ${screen.items}. In front: '
      '${await phone.windowInFront()}. Camera starts the test refused: '
      '${starts.refused}, failed: ${starts.failed}. App errors: '
      '${(await readerReport()).errors}';
}

/// Then: the home screen shows with the "Cần dùng camera" pop-up, and closing
/// the pop-up leaves the home screen.
Future<void> expectHomeWithRefusedPopUp() async {
  final isShowing = await waitUntil(isPopUpShowing);
  expect(
    isShowing,
    isTrue,
    reason:
        'the "$popUpTitle" pop-up did not appear. '
        '${await _whatHappened(await appScreen())}',
  );
  await expectPopUpWords();

  await tapCloseButton();

  final isHome = await waitUntil(() async {
    return await isHomeScreenShowing() && !await isPopUpShowing();
  });
  expect(
    isHome,
    isTrue,
    reason:
        'the pop-up was not on the home screen: closing it did not leave the '
        'home screen. ${await _whatHappened(await appScreen())}',
  );
}

String _words(String text) => text.trim().split(RegExp(r'\s+')).join(' ');

bool _showsNote(AppScreen screen) => screen.texts.any(
  (item) =>
      _words(item.label) == cameraErrorNote ||
      item.label.split('\n').map(_words).contains(cameraErrorNote),
);

/// The home screen, or nothing for a moment while the screen is redrawn.
bool _isHomeOrRedrawing(AppScreen screen) =>
    screen.items.isEmpty ||
    (screen.shows(homeTitle) &&
        screen.shows(scanButtonLabel) &&
        !screen.shows(cameraHint) &&
        !screen.shows(popUpTitle));

/// Then: the home screen shows with the note "Lỗi camera, thử lại", the note
/// fades after about 3 seconds, and the home screen is still there after it.
/// No "Cần dùng camera" pop-up shows, because access wasn't refused.
///
/// With [isHomeTheWholeTime], the home screen must also be the only screen
/// from now on: the camera screen never opens, not even for a moment.
Future<void> expectHomeWithFadingNote({
  required bool isHomeTheWholeTime,
}) async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout);
  DateTime? firstSeen;
  DateTime? lastSeen;
  while (true) {
    final now = DateTime.now();
    final screen = await appScreen();
    final isHome = _isHomeOrRedrawing(screen);
    if (isHomeTheWholeTime || firstSeen != null) {
      expect(
        isHome,
        isTrue,
        reason: firstSeen == null
            ? 'the home screen did not stay. '
                  '${await _whatHappened(screen)}'
            : 'the note showed, but the home screen did not stay. '
                  '${await _whatHappened(screen)}',
      );
    }
    if (_showsNote(screen)) {
      expect(
        isHome && screen.items.isNotEmpty,
        isTrue,
        reason:
            'the note showed, but not on the home screen. '
            '${await _whatHappened(screen)}',
      );
      firstSeen ??= now;
      lastSeen = now;
    }
    if (firstSeen == null && now.isAfter(giveUpAt)) {
      fail(
        'the home screen with the note "$cameraErrorNote" did not show. '
        '${await _whatHappened(screen)}',
      );
    }
    if (lastSeen != null && now.difference(lastSeen) >= _goneFor) break;
    if (firstSeen != null && now.difference(firstSeen) > _longestNote) {
      fail(
        'the note was still showing $_longestNote after it appeared, not '
        'fading after about 3 seconds',
      );
    }
    await Future<void>.delayed(_watchStep);
  }
  expect(
    lastSeen.difference(firstSeen!),
    greaterThanOrEqualTo(_shortestNote),
    reason:
        'the note went away after ${lastSeen.difference(firstSeen)}, sooner '
        'than about 3 seconds',
  );
  await Future<void>.delayed(settleTime);
  final screen = await appScreen();
  expect(
    await isHomeScreenShowing() && !screen.shows(popUpTitle),
    isTrue,
    reason:
        'the home screen did not stay after the note faded. '
        '${await _whatHappened(screen)}',
  );
}
