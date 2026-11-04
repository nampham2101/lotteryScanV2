import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'app_screen.dart';
import 'phone.dart';

// Shared by the tests that run on the Mac and drive the real app started from
// camera_app.dart (tickets #8 and #9), so they never drift apart on what the
// home screen and the camera screen are.

const homeTitle = 'Dò vé số';
const homeSubtitle = 'Chụp vé để biết trúng hay không';
const scanButtonLabel = 'Quét vé';
const cameraHint = 'Đặt vé vào khung';

const testTimeout = Timeout(Duration(minutes: 3));
const screenChangeTimeout = Duration(seconds: 15);

/// Time for anything still being saved to show up before checking it didn't.
const settleTime = Duration(seconds: 3);

/// How long to keep watching for a question that arrives after the camera
/// screen has appeared.
const lateQuestionWatch = Duration(seconds: 5);

final phone = Phone.fromEnvironment();
late FlutterDriver driver;

Future<AppScreen> appScreen() async => AppScreen.fromJson(
  jsonDecode(await driver.requestData('screen')) as Map<String, dynamic>,
);

Future<bool> waitUntil(
  Future<bool> Function() isDone, {
  Duration timeout = screenChangeTimeout,
}) async {
  final stopAt = DateTime.now().add(timeout);
  while (!await isDone()) {
    if (DateTime.now().isAfter(stopAt)) return false;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  return true;
}

Future<bool> isHomeScreenShowing() async {
  if (!await phone.isAppInFront()) return false;
  final screen = await appScreen();
  return screen.shows(homeTitle) &&
      screen.shows(homeSubtitle) &&
      screen.shows(scanButtonLabel) &&
      !screen.shows(cameraHint);
}

Future<bool> isCameraScreenShowing() async {
  if (!await phone.isAppInFront()) return false;
  final screen = await appScreen();
  return screen.shows(cameraHint) && !screen.shows(scanButtonLabel);
}

Future<void> tapScanButton() async {
  final button = (await appScreen()).itemWith(scanButtonLabel);
  await phone.tap(button.centerX.round(), button.centerY.round());
}

/// Given: the home screen is showing. Goes back from wherever a test ended.
Future<void> givenHomeScreen() async {
  for (var tries = 0; tries < 3; tries++) {
    if (await isHomeScreenShowing()) return;
    await phone.pressBackButton();
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  fail('SETUP: the home screen is not showing: ${await phone.windowInFront()}');
}

Future<void> expectCameraScreenOpens() async {
  expect(
    await waitUntil(isCameraScreenShowing),
    isTrue,
    reason:
        'the camera screen ("$cameraHint") did not open. In front: '
        '${await phone.windowInFront()}',
  );
}

Future<void> expectHomeScreenShows() async {
  expect(
    await waitUntil(isHomeScreenShowing),
    isTrue,
    reason:
        'the home screen did not show. In front: '
        '${await phone.windowInFront()}',
  );
}
