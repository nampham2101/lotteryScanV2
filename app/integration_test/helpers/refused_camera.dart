import 'package:test/test.dart';

import 'driven_app.dart';
import 'phone.dart';

// Shared by the tests for ticket #9: what the pop-up says, and how a person
// refuses Android's question, closes the pop-up and changes their mind.

const popUpTitle = 'Cần dùng camera';
const popUpMessage =
    'Ứng dụng cần camera để chụp vé. Bạn hãy cho phép dùng camera trong phần '
    'Cài đặt của điện thoại.';
const closeButtonLabel = 'Đóng';

Future<bool> isPopUpShowing() async {
  if (!await phone.isAppInFront()) return false;
  return (await appScreen()).shows(popUpTitle);
}

/// Android's own window on screen with its question. Checking the question
/// too matters: Android can flash an empty window when it won't ask.
Future<bool> isAndroidAsking() async =>
    await phone.isAndroidAskingForPermission() &&
    await phone.permissionQuestion() != null;

Future<void> expectFreshInstall() async {
  expect(
    await phone.cameraAccess(),
    CameraAccess.neverAsked,
    reason:
        'SETUP: Android already asked this app. Uninstall it before running '
        'these tests: adb uninstall $appPackage',
  );
}

/// Then: Android's question appeared, about the camera, in front of the home
/// screen. The camera screen isn't open behind it.
Future<void> expectAndroidAsks() async {
  expect(
    await waitUntil(isAndroidAsking),
    isTrue,
    reason:
        'Android did not ask for camera access. In front: '
        '${await phone.windowInFront()}',
  );
  final behindQuestion = await appScreen();
  expect(
    behindQuestion.shows(cameraHint),
    isFalse,
    reason: 'the camera screen is already open behind Android\'s question',
  );
  expect(
    behindQuestion.shows(scanButtonLabel),
    isTrue,
    reason: 'the home screen is not behind Android\'s question',
  );
}

Future<void> refuseAndroidQuestion() async {
  final question = await phone.permissionQuestion();
  expect(question, isNotNull, reason: 'Android is not asking');
  await phone.tap(question!.refuseX, question.refuseY);
  expect(
    await waitUntil(() async => !await isAndroidAsking()),
    isTrue,
    reason: 'Android\'s question is still on screen after refusing',
  );
}

Future<void> expectPopUpAppears() async {
  expect(
    await waitUntil(isPopUpShowing),
    isTrue,
    reason:
        'the pop-up ("$popUpTitle") did not appear. In front: '
        '${await phone.windowInFront()}',
  );
}

/// Then: the pop-up reads exactly what the ticket says, and its only button
/// is "Đóng".
Future<void> expectPopUpWords() async {
  final screen = await appScreen();
  expect(
    screen.showsExactly(popUpTitle),
    isTrue,
    reason: 'the title must read "$popUpTitle". On screen: ${screen.items}',
  );
  expect(
    screen.showsExactly(popUpMessage),
    isTrue,
    reason: 'the message must read "$popUpMessage". On screen: ${screen.items}',
  );
  expect(
    screen.itemWith(popUpTitle).top,
    lessThanOrEqualTo(screen.itemWith(popUpMessage).top),
    reason: 'the title must come before the message',
  );
  expect(screen.buttons.map((button) => button.label), [
    closeButtonLabel,
  ], reason: 'the pop-up must have one button, "$closeButtonLabel"');
}

Future<void> tapCloseButton() async {
  final button = (await appScreen()).itemWith(closeButtonLabel);
  await phone.tap(button.centerX.round(), button.centerY.round());
}

/// Then: the pop-up is gone and only the home screen is left.
Future<void> expectPopUpClosedOnHomeScreen() async {
  expect(
    await waitUntil(() async {
      return await isHomeScreenShowing() && !await isPopUpShowing();
    }),
    isTrue,
    reason:
        'the pop-up did not close to the home screen. In front: '
        '${await phone.windowInFront()}. '
        'On screen: ${(await appScreen()).items}',
  );
}

/// Given: the pop-up shows, left open by an earlier test or brought up now.
Future<void> givenPopUpShows() async {
  if (await isPopUpShowing()) return;
  await givenHomeScreen();
  await tapScanButton();
  await waitUntil(() async {
    return await isAndroidAsking() || await isPopUpShowing();
  });
  if (await isAndroidAsking()) await refuseAndroidQuestion();
  await expectPopUpAppears();
}

/// Given: the person refused for good. Android only stops asking after a
/// second refusal, and that second refusal must bring up the pop-up too.
Future<void> givenRefusedForGood() async {
  await givenHomeScreen();
  for (var tries = 0; tries < 2; tries++) {
    if (await phone.isCameraRefusedForGood()) return;
    await tapScanButton();
    await expectAndroidAsks();
    await refuseAndroidQuestion();
    await expectPopUpAppears();
    await tapCloseButton();
    await expectPopUpClosedOnHomeScreen();
  }
  expect(
    await phone.isCameraRefusedForGood(),
    isTrue,
    reason: 'SETUP: Android still has not recorded a refusal for good',
  );
}

/// Given: the person read the pop-up, then allowed the camera in Settings and
/// came back to the home screen.
Future<void> givenAllowedInSettingsAfterThePopUp() async {
  await givenPopUpShows();
  await tapCloseButton();
  await expectPopUpClosedOnHomeScreen();

  await phone.allowCameraInSettings();

  expect(
    await phone.cameraAccess(),
    CameraAccess.allowed,
    reason: 'SETUP: Settings did not allow the camera',
  );
  await expectHomeScreenShows();
}

/// What showed up after a tap, watched until [isFinished] says the app has
/// answered and then a little longer, so a late question or pop-up is caught.
Future<({bool wasAsked, bool sawPopUp})> watchAfterTap(
  Future<bool> Function() isFinished,
) async {
  var wasAsked = false;
  var sawPopUp = false;
  Future<bool> hasInterrupted() async {
    wasAsked = wasAsked || await isAndroidAsking();
    sawPopUp = sawPopUp || await isPopUpShowing();
    return wasAsked;
  }

  await waitUntil(() async {
    return await hasInterrupted() || await isFinished();
  });
  await waitUntil(hasInterrupted, timeout: lateQuestionWatch);
  return (wasAsked: wasAsked, sawPopUp: sawPopUp);
}

/// When the person taps "Quét vé", then the camera screen opens with no pop-up
/// and no question.
Future<void> expectScanOpensCameraWithNoPopUp() async {
  await tapScanButton();

  final seen = await watchAfterTap(isCameraScreenShowing);

  expect(seen.sawPopUp, isFalse, reason: 'the pop-up appeared');
  expect(seen.wasAsked, isFalse, reason: 'Android asked a question');
  await expectCameraScreenOpens();
}
