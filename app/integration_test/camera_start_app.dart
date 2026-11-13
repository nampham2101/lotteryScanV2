import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestDefaultBinaryMessenger;

import 'movement_report.dart';
import 'ticket_text_app.dart' as ticket_text_app;

// The real app for the "Camera won't start" tests of ticket #24: the same start
// as ticket_text_app.dart, with the real camera, the real screens, and ML Kit's
// answers in the tests' hands, so a test can bring up screen 4d. On top of
// that, the tests can make the next camera start go wrong:
//
// - refuse: the camera add-on answers that camera access is refused, with the
//   same error code Android's refusal gives ("CameraAccessDenied"). Android
//   itself can't refuse here: it closes the app when access is taken back, so
//   a refusal can never reach a screen 4d that's already open.
// - fail: access is allowed, but the camera won't start, the way CameraX
//   answers when it can't find a camera to use.
//
// A real refusal is always the first camera start since the app opened. In this
// fake one, the camera add-on still holds the preview of the camera that took
// the photo, already let go of, and letting it go a second time fails inside
// the add-on. While refusing, the fake answers that for the add-on, as a real
// refusal finds no earlier preview.
//
// The answers are given on the camera add-on's own messages for starting the
// camera, so this works however the app starts it. The one limit: the app must
// start the camera through the camera add-on, as it does today. Orders come
// through a service extension, so ticket_text_app.dart stays as it is.
//
// Since ticket #32, the app also says whether anything on screen is moving
// (movement_report.dart), for the tests of 4a's and 4b's movement.

const _askAccessChannel =
    'dev.flutter.pigeon.camera_android_camerax.SystemServicesManager.'
    'requestCameraPermissions';
const _startChannel =
    'dev.flutter.pigeon.camera_android_camerax.ProcessCameraProvider.'
    'bindToLifecycle';
const _letPreviewGoChannel =
    'dev.flutter.pigeon.camera_android_camerax.Preview.releaseSurfaceProvider';

/// What the camera add-on's Android side sends back for an error: its code,
/// its message and its details.
const _refusedReply = [
  'CameraAccessDenied',
  'Camera access permission was denied.',
  null,
];
const _failedReply = [
  'IllegalArgumentException',
  'java.lang.IllegalArgumentException: Provided camera selector unable to '
      'resolve a camera for the given use case',
  'Cause: null, Stacktrace: the test stopped the camera from starting',
];

enum _Trouble { none, refuse, fail }

var _trouble = _Trouble.none;
var _refusedStarts = 0;
var _failedStarts = 0;

void main() {
  developer.registerExtension('ext.lotteryscan.cameraStart', _obey);
  reportMovement();
  ticket_text_app.main();
  _messenger
    ..setMockMessageHandler(_askAccessChannel, _answerAccess)
    ..setMockMessageHandler(_startChannel, _answerStart)
    ..setMockMessageHandler(_letPreviewGoChannel, _answerLetPreviewGo);
}

TestDefaultBinaryMessenger get _messenger =>
    ServicesBinding.instance.defaultBinaryMessenger
        as TestDefaultBinaryMessenger;

Future<ByteData?> _answerAccess(ByteData? message) async {
  if (_trouble != _Trouble.refuse) {
    return _messenger.delegate.send(_askAccessChannel, message);
  }
  _refusedStarts++;
  return const StandardMessageCodec().encodeMessage(_refusedReply);
}

Future<ByteData?> _answerStart(ByteData? message) async {
  if (_trouble != _Trouble.fail) {
    return _messenger.delegate.send(_startChannel, message);
  }
  _failedStarts++;
  return const StandardMessageCodec().encodeMessage(_failedReply);
}

Future<ByteData?> _answerLetPreviewGo(ByteData? message) async {
  final reply = await _messenger.delegate.send(_letPreviewGoChannel, message);
  if (_trouble != _Trouble.refuse || !_isError(reply)) return reply;
  return const StandardMessageCodec().encodeMessage([null]);
}

/// The add-on's Android side answers with one item, or three for an error.
bool _isError(ByteData? reply) {
  final answer = const StandardMessageCodec().decodeMessage(reply);
  return answer is List && answer.length > 1;
}

Future<developer.ServiceExtensionResponse> _obey(
  String method,
  Map<String, String> order,
) async {
  switch (order['do']) {
    case 'start':
      _trouble = _Trouble.none;
      _refusedStarts = 0;
      _failedStarts = 0;
    case 'refuse':
      _trouble = _Trouble.refuse;
    case 'fail':
      _trouble = _Trouble.fail;
  }
  return developer.ServiceExtensionResponse.result(
    jsonEncode({
      'refusedStarts': _refusedStarts,
      'failedStarts': _failedStarts,
    }),
  );
}
