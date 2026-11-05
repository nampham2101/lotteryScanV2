import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestDefaultBinaryMessenger;

import 'camera_app.dart' as camera_app;

// The real app for the tests of ticket #18: the same start as camera_app.dart,
// with the real camera and the real screens. Only ML Kit's answers are in the
// tests' hands, because a test has to choose what a photo "reads", and has to
// keep a read unfinished for as long as it needs.
//
// ML Kit is reached through its add-on's message channel. Everything the add-on
// does goes through it, so the tests don't depend on how the app calls ML Kit.
// The tests give orders through a service extension, so camera_app.dart, which
// the tests of tickets #8, #9 and #10 use, stays as it is.

const _readerChannel = MethodChannel('google_mlkit_text_recognizer');
const _readMethod = 'vision#startTextRecognizer';

final _reads = <_Read>[];
final _errors = <String>[];
var _isUsingRealReader = false;

void main() {
  developer.registerExtension('ext.lotteryscan.reader', _obey);
  camera_app.main();
  _watchForErrors();
  _messenger.setMockMethodCallHandler(_readerChannel, _answerReader);
}

TestDefaultBinaryMessenger get _messenger =>
    ServicesBinding.instance.defaultBinaryMessenger
        as TestDefaultBinaryMessenger;

/// One time the app asked ML Kit to read a photo.
class _Read {
  _Read(this.photoHash);

  /// Which picture ML Kit was given, as it was at that moment.
  final int? photoHash;
  final answer = Completer<Object?>();

  /// What real ML Kit gave, or what a test chose.
  String? text;
  bool isFinished = false;

  Map<String, Object?> toJson() => {
    'photoHash': photoHash,
    'isFinished': isFinished,
    'text': text,
  };
}

/// Stays on the phone's own log as well, so a failed run can be read there.
void _watchForErrors() {
  final showError = FlutterError.onError;
  FlutterError.onError = (details) {
    _errors.add(details.exceptionAsString());
    showError?.call(details);
  };
  final handleError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    _errors.add('$error');
    return handleError?.call(error, stack) ?? false;
  };
}

Future<Object?> _answerReader(MethodCall call) {
  if (call.method != _readMethod) {
    return _isUsingRealReader ? _askRealReader(call) : Future.value();
  }
  final read = _Read(_hashOfPicture(call));
  _reads.add(read);
  return _isUsingRealReader ? _readForReal(read, call) : read.answer.future;
}

Future<Object?> _askRealReader(MethodCall call) => MethodChannel(
  _readerChannel.name,
  const StandardMethodCodec(),
  _messenger.delegate,
).invokeMethod<Object?>(call.method, call.arguments);

Future<Object?> _readForReal(_Read read, MethodCall call) async {
  try {
    final answer = await _askRealReader(call);
    read.text = (answer! as Map<Object?, Object?>)['text']! as String;
    return answer;
  } finally {
    read.isFinished = true;
  }
}

int? _hashOfPicture(MethodCall call) {
  final arguments = call.arguments as Map<Object?, Object?>;
  final picture = arguments['imageData']! as Map<Object?, Object?>;
  final path = picture['path'] as String?;
  final bytes = picture['bytes'] as List<int>?;
  if (path != null && File(path).existsSync()) {
    return _hash(File(path).readAsBytesSync());
  }
  return bytes == null ? null : _hash(bytes);
}

/// FNV-1a. The tests on the Mac work out the same number from the kept photo.
int _hash(List<int> bytes) {
  var hash = 2166136261;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 16777619) & 0xffffffff;
  }
  return hash;
}

Future<developer.ServiceExtensionResponse> _obey(
  String method,
  Map<String, String> order,
) async {
  switch (order['do']) {
    case 'start':
      _reads.clear();
      _errors.clear();
      _isUsingRealReader = order['reader'] == 'real';
    case 'finish':
      _finish(int.parse(order['read']!), order['text']!);
    case 'fail':
      _fail(int.parse(order['read']!));
  }
  return developer.ServiceExtensionResponse.result(jsonEncode(_report()));
}

void _finish(int number, String text) {
  final read = _reads[number]
    ..text = text
    ..isFinished = true;
  read.answer.complete(_answerWith(text));
}

void _fail(int number) {
  final read = _reads[number]..isFinished = true;
  read.answer.completeError(
    PlatformException(
      code: 'read_failed',
      message: 'the test failed this read',
    ),
  );
}

/// What ML Kit sends for [text]. The blocks come in the opposite order to the
/// text, so only ML Kit's `text` value gives the right order on screen.
Map<String, Object> _answerWith(String text) => {
  'text': text,
  'blocks': [
    if (text.isNotEmpty)
      for (final line in text.split('\n').reversed) _block(line),
  ],
};

Map<String, Object> _block(String line) {
  const place = {'left': 0, 'top': 0, 'right': 0, 'bottom': 0};
  return {
    'text': line,
    'rect': place,
    'recognizedLanguages': <Object>[],
    'points': <Object>[],
    'lines': [
      {
        'text': line,
        'rect': place,
        'confidence': 1.0,
        'angle': 0.0,
        'recognizedLanguages': <Object>[],
        'points': <Object>[],
        'elements': <Object>[],
      },
    ],
  };
}

Map<String, Object?> _report() => {
  'reads': [for (final read in _reads) read.toJson()],
  'errors': _errors,
  'scrollAreas': _scrollAreas(),
};

/// Everything on screen that scrolls: how far along it is, and where it sits in
/// phone pixels. Like camera_app.dart, this asks the accessibility tree, so it
/// accepts any way of building the scrolling part.
List<Map<String, Object>> _scrollAreas() {
  final areas = <Map<String, Object>>[];

  void visit(SemanticsNode node, Matrix4 toScreen) {
    final transform = node.transform;
    final nodeToScreen = transform == null
        ? toScreen
        : toScreen.multiplied(transform);
    final data = node.getSemanticsData();
    final position = data.scrollPosition;
    if (position != null) {
      final rect = MatrixUtils.transformRect(nodeToScreen, node.rect);
      areas.add({
        'position': position,
        'end': data.scrollExtentMax ?? 0,
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      });
    }
    node.visitChildren((child) {
      visit(child, nodeToScreen);
      return true;
    });
  }

  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner
      ?.semanticsOwner
      ?.rootSemanticsNode;
  if (root != null) visit(root, Matrix4.identity());
  return areas;
}
