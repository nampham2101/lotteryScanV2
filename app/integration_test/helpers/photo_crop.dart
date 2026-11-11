import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'answers.dart';
import 'app_screen.dart';
import 'dashed_frame.dart';
import 'driven_app.dart';
import 'phone.dart';
import 'photo_hash.dart';
import 'photo_screen.dart';
import 'shown_photo.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

// Shared by the tests for ticket #22, which run on the Mac: how they give orders
// about the camera's picture to photo_crop_app.dart, what the dashed frame
// showed, and what the kept photo, the note and the photo folders must be.

const cropFailedNote = 'Lỗi xử lí ảnh. Vui lòng chụp lại ảnh khác';

/// The text read from a photo kept before the one a test is about. It has all
/// three fields, so since ticket #24 the photo screen shows them, not 4d.
/// Since ticket #28 the answer shows below them: 2019 is before the saved
/// feed's oldest day.
const earlierText = 'ĐÀ LẠT\n654321\n24-11-2019';
final _earlierLines = [
  ...fieldLines(number: '654321', province: 'Đà Lạt', date: '24-11-2019'),
  tooOldText,
];

/// "Fades after a few seconds": the note stays long enough to read, then goes
/// away by itself. Watching takes a moment between looks, so the shortest
/// stay counted is a little under two seconds.
const _shortestNote = Duration(milliseconds: 1500);
const _longestNote = Duration(seconds: 10);

/// A note gone for this long has gone, not just been redrawn.
const _goneFor = Duration(seconds: 1);

/// "Near the bottom": the note sits in the bottom third of the screen.
const _noteZoneStart = 2 / 3;

/// A square photo's sides may differ by this share, for rounding.
const _squareSlack = 0.01;

/// Time for the live picture to settle after the camera screen opens.
const _pictureSettleTime = Duration(milliseconds: 1500);

const _watchStep = Duration(milliseconds: 40);

/// One picture the camera took for the app.
class PictureSeen {
  PictureSeen.fromJson(Map<String, dynamic> json)
    : path = json['path'] as String?,
      isSpoiled = json['isSpoiled'] as bool,
      isHandedOver = json['isHandedOver'] as bool,
      isStillThere = json['isStillThere'] as bool;

  /// Where the camera saved it, once it has.
  final String? path;
  final bool isSpoiled;

  /// Whether the app has been given it.
  final bool isHandedOver;

  /// Whether the camera's own file is still at [path].
  final bool isStillThere;
}

class CameraReport {
  CameraReport.fromJson(Map<String, dynamic> json)
    : pictures = [
        for (final picture in json['pictures'] as List<dynamic>)
          PictureSeen.fromJson(picture as Map<String, dynamic>),
      ],
      outsidePhotos = (json['outsidePhotos'] as List<dynamic>).cast<String>();

  final List<PictureSeen> pictures;

  /// Photos in the app's folders on the shared storage.
  final List<String> outsidePhotos;
}

Future<CameraReport> _orderCamera(String order) async {
  final response = await driver.serviceClient.callServiceExtension(
    'ext.lotteryscan.camera',
    isolateId: driver.appIsolate.id,
    args: {'do': order},
  );
  return CameraReport.fromJson(response.json!);
}

Future<CameraReport> cameraReport() => _orderCamera('report');

/// Forgets the pictures of earlier tests.
Future<void> startCameraWatch() => _orderCamera('start');

/// The next picture the camera takes can't be cut to the frame.
Future<void> spoilNextPhoto() => _orderCamera('spoilNext');

/// The next picture the camera takes reaches the app only on [releasePhoto].
Future<void> holdNextPhoto() => _orderCamera('holdNext');

Future<void> releasePhoto() => _orderCamera('release');

/// Waits for the camera to have saved its latest picture, and, unless it's
/// held, for the app to have it.
Future<PictureSeen> _expectCameraTookPicture({required bool isHeld}) async {
  PictureSeen? picture;
  await waitUntil(() async {
    final pictures = (await cameraReport()).pictures;
    picture = pictures.isEmpty ? null : pictures.last;
    return picture?.path != null && (isHeld || picture!.isHandedOver);
  });
  expect(
    picture?.path,
    isNotNull,
    reason:
        'SETUP: no picture came through the camera add-on\'s takePicture, so '
        'the test could not reach it',
  );
  return picture!;
}

/// What the camera screen's dashed frame showed, and where.
typedef FrameSeen = ({FrameOnScreen frame, ScreenPixels pixels});

/// Given: the camera screen is open, with the camera's picture in its frame.
/// Returns what the frame shows just before the shutter. The emulator's room
/// stands still, so that's what the photo will show.
Future<FrameSeen> givenCameraScreenWithFrame() async {
  await givenCameraScreenOpen();
  await Future<void>.delayed(_pictureSettleTime);
  FrameSeen? seen;
  await waitUntil(() async {
    final pixels = await phone.screenshot();
    final frame = findFrame(pixels);
    seen = frame == null ? null : (frame: frame, pixels: pixels);
    return seen != null;
  });
  expect(
    seen,
    isNotNull,
    reason: 'the camera picture inside the dashed frame is not on screen',
  );
  return seen!;
}

/// Then: [photo] is square and shows exactly what the dashed frame showed.
void expectWhatFrameShowed(img.Image photo, FrameSeen seen) {
  final longer = max(photo.width, photo.height);
  expect(
    (photo.width - photo.height).abs(),
    lessThanOrEqualTo(longer * _squareSlack),
    reason: 'the kept photo is ${photo.width}x${photo.height}, not square',
  );
  expect(
    differenceFromFrame(photo, seen.pixels, seen.frame),
    lessThanOrEqualTo(sameAsFrameLimit),
    reason:
        'the kept photo does not show exactly what was inside the dashed '
        'frame at ${seen.frame}: it shows more, less or another part',
  );
}

/// The newest photo inside the app, written after [tappedAt], which must be
/// square and show exactly what the frame showed.
Future<img.Image> croppedPhotoKeptSince(double tappedAt, FrameSeen seen) async {
  final photo = await keptPhotoSince(tappedAt);
  expectWhatFrameShowed(photo, seen);
  return photo;
}

/// Given: a photo was taken and read earlier, and the person is back home.
/// Returns that photo.
Future<img.Image> givenPhotoKeptEarlier() async {
  final photo = await givenReadingShows();
  await finishRead(0, earlierText);
  await expectOnlyLinesAre(_earlierLines);
  await phone.pressBackButton();
  await expectHomeScreenShows();
  return photo;
}

/// Every photo the app holds, and the gallery.
typedef AppPhotos = ({
  List<KeptPhoto> inside,
  List<int> contents,
  List<String> outside,
  List<String> gallery,
});

Future<AppPhotos> appPhotosNow() async {
  final inside = await phone.photosInsideApp();
  return (
    inside: inside,
    contents: [
      for (final photo in inside)
        photoHash(await phone.fileInsideApp(photo.path)),
    ],
    outside: (await cameraReport()).outsidePhotos,
    gallery: await phone.galleryPhotos(),
  );
}

/// Then: the app holds exactly the photos it held in [before], unchanged, and
/// nothing new reached the gallery.
Future<void> expectPhotosUnchanged(AppPhotos before) async {
  final after = await appPhotosNow();
  expect(
    after.inside,
    before.inside,
    reason: 'the photos inside the app changed. Before: ${before.inside}',
  );
  expect(
    after.contents,
    before.contents,
    reason: 'a photo kept before was changed',
  );
  expect(after.outside, before.outside, reason: 'a photo was kept outside');
  expect(after.gallery, before.gallery, reason: 'a photo reached the gallery');
}

/// Then: the camera's own file for its latest picture is gone, unless it is
/// [keptPath], the one photo the app keeps.
Future<void> expectCamerasCopyGone({String? keptPath}) async {
  final picture = (await cameraReport()).pictures.last;
  final isTheKeptPhoto =
      keptPath != null && picture.path!.endsWith(keptPath.substring(1));
  expect(
    picture.isStillThere && !isTheKeptPhoto,
    isFalse,
    reason: 'the camera\'s own copy is still at ${picture.path}',
  );
}

/// Then: the app holds one photo, the cropped one: square, showing what the
/// frame showed. No full-size copy is left inside the app, in its folders on
/// the shared storage, in the gallery, or where the camera saved it.
Future<void> expectOnlyCroppedPhotoKept(
  FrameSeen seen, {
  required List<String> galleryBefore,
}) async {
  final photos = await phone.photosInsideApp();
  expect(
    photos,
    hasLength(1),
    reason: 'the app must hold one photo, the cropped one. It holds: $photos',
  );
  expectWhatFrameShowed(
    uprightPhoto(await phone.fileInsideApp(photos.single.path)),
    seen,
  );
  expect(
    (await cameraReport()).outsidePhotos,
    isEmpty,
    reason: 'a photo was kept in the app\'s folders on the shared storage',
  );
  expect(
    await phone.galleryPhotos(),
    galleryBefore,
    reason: 'a photo reached the gallery',
  );
  await expectCamerasCopyGone(keptPath: photos.single.path);
}

String _words(String text) => text.trim().split(RegExp(r'\s+')).join(' ');

ScreenItem? _noteOn(AppScreen screen) {
  for (final item in screen.texts) {
    if (_words(item.label) == cropFailedNote ||
        item.label.split('\n').contains(cropFailedNote)) {
      return item;
    }
  }
  return null;
}

/// The camera screen, or nothing for a moment while the screen is redrawn.
void _expectStillCameraScreen(AppScreen screen) {
  if (screen.items.isEmpty) return;
  expect(
    screen.shows(cameraHint) &&
        !screen.shows(homeTitle) &&
        !screen.shows(scanButtonLabel) &&
        !screen.shows(readingText),
    isTrue,
    reason: 'the camera screen did not stay open. On screen: ${screen.items}',
  );
}

void _expectNearBottom(ScreenItem note, AppScreen screen) {
  expect(
    note.top >= screen.height * _noteZoneStart && note.bottom <= screen.height,
    isTrue,
    reason:
        'the note must show near the bottom, in the bottom third of the '
        'screen: $note on a screen ${screen.height} high',
  );
}

/// When the crop of the latest picture fails: waits until the app has it.
Future<void> expectSpoiledPictureHandedOver() async {
  final picture = await _expectCameraTookPicture(isHeld: false);
  expect(
    picture.isSpoiled,
    isTrue,
    reason: 'SETUP: the picture the test spoiled is not the latest one',
  );
}

/// Then: the camera screen stays open the whole time, and the note shows near
/// the bottom, stays long enough to read, and goes away by itself.
Future<void> expectNoteShowsAndFades() async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout);
  DateTime? firstSeen;
  DateTime? lastSeen;
  while (true) {
    final now = DateTime.now();
    final screen = await appScreen();
    _expectStillCameraScreen(screen);
    final note = _noteOn(screen);
    if (note != null) {
      _expectNearBottom(note, screen);
      firstSeen ??= now;
      lastSeen = now;
    }
    if (firstSeen == null && now.isAfter(giveUpAt)) {
      fail('"$cropFailedNote" did not show. On screen: ${screen.items}');
    }
    if (lastSeen != null && now.difference(lastSeen) >= _goneFor) break;
    if (firstSeen != null && now.difference(firstSeen) > _longestNote) {
      fail('the note was still showing $_longestNote after it appeared');
    }
    await Future<void>.delayed(_watchStep);
  }
  expect(
    lastSeen.difference(firstSeen!),
    greaterThanOrEqualTo(_shortestNote),
    reason: 'the note went away too soon to read',
  );
  await Future<void>.delayed(settleTime);
  _expectStillCameraScreen(await appScreen());
  expect(
    await isCameraScreenShowing(),
    isTrue,
    reason:
        'the camera screen is gone. In front: ${await phone.windowInFront()}',
  );
  await expectAppUsingCamera();
}

/// Waits until the note shows, on the camera screen.
Future<void> expectNoteShows() async {
  AppScreen? screen;
  final isShowing = await waitUntil(() async {
    screen = await appScreen();
    _expectStillCameraScreen(screen!);
    return _noteOn(screen!) != null;
  });
  expect(
    isShowing,
    isTrue,
    reason: '"$cropFailedNote" did not show. On screen: ${screen?.items}',
  );
}

/// When the person taps the shutter and presses back before the photo
/// arrives, then the photo arrives while they are leaving.
Future<void> tapShutterThenBack() async {
  await holdNextPhoto();
  await tapShutter();
  await _expectCameraTookPicture(isHeld: true);
  await phone.pressBackButton();
  await releasePhoto();
}

/// Then: the home screen shows and stays, and no photo screen ever appears on
/// the way. The reads are held, so a photo screen would show "Đang đọc vé...".
/// The list of what's on screen is empty for a moment whenever a screen
/// closes, so a moment doesn't count.
Future<void> expectHomeWithNoPhotoScreen() async {
  final giveUpAt = DateTime.now().add(screenChangeTimeout);
  DateTime? homeSince;
  while (homeSince == null ||
      DateTime.now().difference(homeSince) < settleTime) {
    final isInFront = await phone.isAppInFront();
    final screen = await appScreen();
    expect(
      screen.shows(readingText),
      isFalse,
      reason: 'the photo screen opened after the person pressed back',
    );
    final isHome =
        isInFront &&
        screen.shows(homeTitle) &&
        screen.shows(homeSubtitle) &&
        screen.shows(scanButtonLabel) &&
        !screen.shows(cameraHint);
    if (!isHome && homeSince != null && screen.items.isNotEmpty) {
      fail('the home screen did not stay. On screen: ${screen.items}');
    }
    if (isHome) homeSince ??= DateTime.now();
    if (homeSince == null && DateTime.now().isAfter(giveUpAt)) {
      fail(
        'the home screen did not show. In front: '
        '${await phone.windowInFront()}',
      );
    }
    await Future<void>.delayed(_watchStep);
  }
}
