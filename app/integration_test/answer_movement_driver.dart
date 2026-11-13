import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/answer_screens.dart';
import 'helpers/app_screen.dart';
import 'helpers/camera_start.dart';
import 'helpers/driven_app.dart';
import 'helpers/movement.dart';
import 'helpers/results.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #32, on the Pixel_10 emulator: 4a and 4b in the
// real app, once their movement has ended, and "Quét vé khác" and back while
// it plays. How the movement itself looks and when it plays are widget tests
// (test/answer_movement_test.dart). These run on the Mac and talk to the real
// app started from camera_start_app.dart, where the tests decide what ML Kit
// reads and what the results site answers, as in ticket #31. From app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/answer_movement_driver.dart \
//     --target=integration_test/camera_start_app.dart
//
// Each test starts from the home screen. Don't touch the emulator during a
// run. "The saved feed" is helpers/saved_feed.dart, as in ticket #31: 123482
// wins Giải Tám at Bạc Liêu on 10/11/2026, and 111111 wins nothing there. With
// MOVEMENT_RECORDINGS set to a folder, the tests also record the screen for
// the manual steps (docs/tests/32.md).

/// One of the screens that move: what ML Kit reads on its ticket, what it
/// shows, ticket #31's screenshot of it, the name of its recording for the
/// manual steps, and when its movement is surely playing, after the page
/// change: 4a's confetti falls for about 2 seconds, and 4b's smiley moves
/// about half a second after it opens.
typedef _MovingScreen = ({
  String name,
  String text,
  AnswerScreen answer,
  String saved,
  String recording,
  Duration playingFrom,
  Duration playingUntil,
});

const _playingUntil = Duration(milliseconds: 1500);

final _won = (
  name: '4a',
  text: ticketText(number: '123482', province: 'BẠC LIÊU', date: '10-11-2026'),
  answer: wonScreen([
    (name: 'Giải Tám', amount: '100.000đ'),
  ], ticketCard(number: '123482', province: 'Bạc Liêu', date: '10/11/2026')),
  saved: '$evidenceOf31/4a-one-prize.png',
  recording: '4a-one-prize',
  playingFrom: afterPageChange,
  playingUntil: _playingUntil,
);

/// 117988 wins Giải Sáu and Giải Tám at Bình Dương on 06/11/2026.
final _wonTwice = (
  name: '4a (two prizes)',
  text: ticketText(
    number: '117988',
    province: 'BÌNH DƯƠNG',
    date: '06-11-2026',
  ),
  answer: wonScreen([
    (name: 'Giải Sáu', amount: '400.000đ'),
    (name: 'Giải Tám', amount: '100.000đ'),
  ], ticketCard(number: '117988', province: 'Bình Dương', date: '06/11/2026')),
  saved: '$evidenceOf31/4a-two-prizes.png',
  recording: '4a-two-prizes',
  playingFrom: afterPageChange,
  playingUntil: _playingUntil,
);

final _lost = (
  name: '4b',
  text: ticketText(number: '111111', province: 'BẠC LIÊU', date: '10-11-2026'),
  answer: lostScreen(
    ticketCard(number: '111111', province: 'Bạc Liêu', date: '10/11/2026'),
  ),
  saved: '$evidenceOf31/4b.png',
  recording: '4b',
  playingFrom: afterPageChange,
  playingUntil: _playingUntil,
);

/// "Doesn't play again while the screen stays open", watched this long.
const _stillWatch = Duration(seconds: 10);

/// "Straight away, just as when the screen is still": pressing while it moves
/// may take at most this much longer than pressing on the still screen. A
/// press that waited for 4a's movement to end would take over a second more.
const _cameraAllowance = Duration(seconds: 1);
const _backAllowance = Duration(milliseconds: 300);

/// When [screen]'s ticket is scanned. Returns when its screen first showed.
Future<DateTime> _whenScanned(_MovingScreen screen) async {
  await whenTicketScanned(screen.text);
  return waitForTitle(screen.answer.title);
}

/// Given: the home screen, ready for a scan, from wherever the test is. Going
/// home may close a camera, which raises the camera add-on's known "release a
/// second time" error (see camera_start_app.dart). That happens before
/// [holdReads] forgets the errors so far, so it isn't counted.
Future<void> _givenHomeReadyToScan() async {
  await letCameraStart();
  await givenHomeScreen();
  await holdReads();
  await resetSite();
}

/// Waits until [screen]'s movement is surely playing, then does [act] at once.
Future<void> _whileMoving(
  _MovingScreen screen,
  DateTime shownAt,
  Future<void> Function() act,
) async {
  final movingAt = await movingSeen(
    shownAt,
    from: screen.playingFrom,
    until: screen.playingUntil,
  );
  expect(
    movingAt,
    isNotNull,
    reason:
        '${screen.name} was not moving between '
        '${screen.playingFrom.inMilliseconds} and '
        '${screen.playingUntil.inMilliseconds} ms after it showed, so it '
        'couldn\'t be pressed while its movement played',
  );
  await act();
}

bool _isCameraScreen(AppScreen screen) =>
    screen.shows(cameraHint) && !screen.shows(scanButtonLabel);

bool _isHomeScreen(AppScreen screen, String leftTitle) =>
    screen.shows(homeTitle) &&
    screen.shows(homeSubtitle) &&
    screen.shows(scanButtonLabel) &&
    !screen.shows(leftTitle);

/// How long after the tap on "Quét vé khác" the camera screen shows.
Future<Duration> _timeToCamera() => timeUntil(
  () async => _isCameraScreen(await appScreen()),
  reason: 'the camera screen did not open after "$scanAnotherLabel"',
);

/// How long after back the home screen shows, with [screen] gone.
Future<Duration> _timeToHome(_MovingScreen screen) => timeUntil(
  () async => _isHomeScreen(await appScreen(), screen.answer.title),
  reason: 'the home screen did not show after back on ${screen.name}',
);

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(_givenHomeReadyToScan);

  group('Once the movement has ended', () {
    for (final screen in [_won, _wonTwice, _lost]) {
      test(
        'Given a ticket for ${screen.name}, when it opens, then it moves, and '
        'once the movement has ended the screen stays still, exactly as in '
        '#31, and the movement doesn\'t play again',
        () async {
          final stopRecording = await recordScreenIfAsked(screen.recording);
          final shownAt = await _whenScanned(screen);
          final movingAt = await movingSeen(
            shownAt,
            from: screen.playingFrom,
            until: screen.playingUntil,
          );

          await waitUntilMovementEnds();
          await stopRecording();
          await expectAnswerScreen(screen.answer);
          await expectScreenAsSaved(screen.saved);
          await expectStillFor(
            _stillWatch,
            reason: 'the movement played again',
          );
          await expectScreenAsSaved(screen.saved);
          expect(
            movingAt,
            isNotNull,
            reason:
                '${screen.name} did not move: nothing moved between '
                '${screen.playingFrom.inMilliseconds} and '
                '${screen.playingUntil.inMilliseconds} ms after it showed',
          );
          await expectNoAppErrors();
        },
        timeout: testTimeout,
      );
    }
  });

  group('Pressing while it moves', () {
    for (final screen in [_won, _lost]) {
      test('Given ${screen.name} while the movement is still playing, when '
          '"Quét vé khác" is tapped, then the camera opens straight away, just '
          'as when the screen is still', () async {
        await _whenScanned(screen);
        await waitUntilMovementEnds();
        await tapInApp(scanAnotherLabel);
        final whenStill = await _timeToCamera();
        await expectCameraScreenOpensAndStays();
        await _givenHomeReadyToScan();

        final shownAt = await _whenScanned(screen);
        await _whileMoving(screen, shownAt, () => tapInApp(scanAnotherLabel));
        final whenMoving = await _timeToCamera();

        expect(
          whenMoving,
          lessThanOrEqualTo(whenStill + _cameraAllowance),
          reason:
              'the camera did not open straight away: ${whenMoving.inMilliseconds}'
              ' ms after the tap while ${screen.name} moved, and '
              '${whenStill.inMilliseconds} ms when it was still',
        );
        await expectCameraScreenOpensAndStays();
        await expectNoAppErrors();
      }, timeout: testTimeout);

      test('Given ${screen.name} while the movement is still playing, when '
          'back is pressed, then home shows straight away, just as when the '
          'screen is still', () async {
        await _whenScanned(screen);
        await waitUntilMovementEnds();
        await pressBackInApp();
        final whenStill = await _timeToHome(screen);
        await expectHomeScreenShowsAndStays();
        await _givenHomeReadyToScan();

        final shownAt = await _whenScanned(screen);
        var wasMoving = false;
        await _whileMoving(screen, shownAt, () async {
          wasMoving = await pressBackInApp();
        });
        final whenMoving = await _timeToHome(screen);

        expect(
          wasMoving,
          isTrue,
          reason: '${screen.name} had stopped moving when back was pressed',
        );
        expect(
          whenMoving,
          lessThanOrEqualTo(whenStill + _backAllowance),
          reason:
              'home did not show straight away: ${whenMoving.inMilliseconds} '
              'ms after back while ${screen.name} moved, and '
              '${whenStill.inMilliseconds} ms when it was still',
        );
        await expectHomeScreenShowsAndStays();
        await expectNoAppErrors();
      }, timeout: testTimeout);
    }
  });
}
