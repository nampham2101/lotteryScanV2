import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestDefaultBinaryMessenger;
import 'package:path_provider/path_provider.dart';

import 'ticket_text_app.dart' as ticket_text_app;

// The real app for the tests of ticket #22: the same start as
// ticket_text_app.dart, with the real camera, the real screens, and ML Kit's
// answers in the tests' hands. On top of that, the tests can reach the camera's
// finished picture before the app gets it:
//
// - spoil it, so that cutting it to the frame fails, the way a real crop fails
//   on a picture it can't use. The file keeps the start of a JPEG, so a left-
//   over copy is still recognised as a photo, but it holds no picture.
// - hold it back, so that the person can press back before it arrives.
//
// The picture is reached on the camera add-on's own message for taking one,
// so this works however the app crops. The one limit: the app must take its
// photo with the camera add-on's takePicture, as it does today. Orders come
// through a service extension, so ticket_text_app.dart stays as it is.

const _takePictureChannel =
    'dev.flutter.pigeon.camera_android_camerax.ImageCapture.takePicture';

/// The start of a JPEG file with nothing after it that a decoder can use.
final _spoiledPhoto = [
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, //
  0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00,
  ...utf8.encode('the test spoiled this photo. ' * 40),
];

const _imageStarts = [
  [0xFF, 0xD8, 0xFF], // JPEG
  [0x89, 0x50, 0x4E, 0x47], // PNG
  [0x52, 0x49, 0x46, 0x46], // WebP
];

final _pictures = <_Picture>[];
var _isSpoilingNext = false;
var _isHoldingNext = false;

void main() {
  developer.registerExtension('ext.lotteryscan.camera', _obey);
  ticket_text_app.main();
  _messenger.setMockMessageHandler(_takePictureChannel, _passPictureOn);
}

TestDefaultBinaryMessenger get _messenger =>
    ServicesBinding.instance.defaultBinaryMessenger
        as TestDefaultBinaryMessenger;

/// One picture the camera took for the app.
class _Picture {
  _Picture({required this.isSpoiled, required this.isHeld});

  final bool isSpoiled;
  final bool isHeld;
  final release = Completer<void>();

  /// Where the camera saved it, once it has.
  String? path;

  /// Whether the app has been given it.
  bool isHandedOver = false;

  Map<String, Object?> toJson() => {
    'path': path,
    'isSpoiled': isSpoiled,
    'isHeld': isHeld,
    'isHandedOver': isHandedOver,
    'isStillThere': path != null && File(path!).existsSync(),
  };
}

Future<ByteData?> _passPictureOn(ByteData? message) async {
  final picture = _Picture(isSpoiled: _isSpoilingNext, isHeld: _isHoldingNext);
  _isSpoilingNext = false;
  _isHoldingNext = false;
  _pictures.add(picture);
  final reply = await _messenger.delegate.send(_takePictureChannel, message);
  picture.path = _pathIn(reply);
  if (picture.isSpoiled && picture.path != null) {
    File(picture.path!).writeAsBytesSync(_spoiledPhoto, flush: true);
  }
  if (picture.isHeld) await picture.release.future;
  picture.isHandedOver = true;
  return reply;
}

/// The camera answers with a list holding the picture's path, or with three
/// items describing an error.
String? _pathIn(ByteData? reply) {
  try {
    final answer = const StandardMessageCodec().decodeMessage(reply);
    if (answer is List && answer.length == 1 && answer.single is String) {
      return answer.single as String;
    }
  } on Object {
    return null;
  }
  return null;
}

Future<developer.ServiceExtensionResponse> _obey(
  String method,
  Map<String, String> order,
) async {
  switch (order['do']) {
    case 'start':
      _pictures.clear();
      _isSpoilingNext = false;
      _isHoldingNext = false;
    case 'spoilNext':
      _isSpoilingNext = true;
    case 'holdNext':
      _isHoldingNext = true;
    case 'release':
      for (final picture in _pictures) {
        if (!picture.release.isCompleted) picture.release.complete();
      }
  }
  return developer.ServiceExtensionResponse.result(
    jsonEncode({
      'pictures': [for (final picture in _pictures) picture.toJson()],
      'outsidePhotos': await _photosOutsidePrivateFolders(),
    }),
  );
}

/// Every photo in the app's folders on the shared storage, which the Mac's
/// look inside the app's private folders doesn't reach and the gallery leaves
/// out. Recognised by content, whatever the name.
Future<List<String>> _photosOutsidePrivateFolders() async {
  final files = (await getExternalStorageDirectory())?.parent;
  if (files == null) return [];
  final folders = [
    files,
    Directory(files.path.replaceFirst('/Android/data/', '/Android/media/')),
  ];
  return [
    for (final folder in folders)
      if (folder.existsSync())
        for (final entry in folder.listSync(recursive: true))
          if (entry is File && _isImage(entry)) entry.path,
  ];
}

bool _isImage(File file) {
  final RandomAccessFile opened;
  try {
    opened = file.openSync();
  } on FileSystemException {
    return false;
  }
  try {
    final start = opened.readSync(4);
    return _imageStarts.any(
      (magic) =>
          start.length >= magic.length &&
          [for (var i = 0; i < magic.length; i++) start[i]].join(',') ==
              magic.join(','),
    );
  } finally {
    opened.closeSync();
  }
}
