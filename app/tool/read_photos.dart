// Ticket #16: a throw-away runner that shows what ML Kit reads on the ticket
// photos. It is NOT part of the normal app: it has its own entry point, started
// with `-t tool/read_photos.dart` (see read_photos.sh), and the photos are never
// built into the app. They are copied to the emulator with adb first.
//
// For each `photos/<name>.jpg` in the app's files folder it writes
// `mlkit_out/<name>.json` with everything ML Kit read (blocks, lines, elements,
// symbols, each with text, bounding box and corner points), the picture's size
// and the device the run used. It writes `mlkit_out/DONE` when finished.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

Map<String, Object?> _rect(Rect r) => {
  'left': r.left,
  'top': r.top,
  'right': r.right,
  'bottom': r.bottom,
};

List<Map<String, int>> _points(List<Point<int>> points) => [
  for (final p in points) {'x': p.x, 'y': p.y},
];

Map<String, Object?> _symbol(TextSymbol s) => {
  'text': s.text,
  'boundingBox': _rect(s.boundingBox),
  'cornerPoints': _points(s.cornerPoints),
  'confidence': s.confidence,
  'angle': s.angle,
};

Map<String, Object?> _element(TextElement e) => {
  'text': e.text,
  'boundingBox': _rect(e.boundingBox),
  'cornerPoints': _points(e.cornerPoints),
  'recognizedLanguages': e.recognizedLanguages,
  'confidence': e.confidence,
  'angle': e.angle,
  'symbols': [for (final s in e.symbols) _symbol(s)],
};

Map<String, Object?> _line(TextLine l) => {
  'text': l.text,
  'boundingBox': _rect(l.boundingBox),
  'cornerPoints': _points(l.cornerPoints),
  'recognizedLanguages': l.recognizedLanguages,
  'confidence': l.confidence,
  'angle': l.angle,
  'elements': [for (final e in l.elements) _element(e)],
};

Map<String, Object?> _block(TextBlock b) => {
  'text': b.text,
  'boundingBox': _rect(b.boundingBox),
  'cornerPoints': _points(b.cornerPoints),
  'recognizedLanguages': b.recognizedLanguages,
  'lines': [for (final l in b.lines) _line(l)],
};

Future<String> _prop(String name) async {
  final result = await Process.run('getprop', [name]);
  return (result.stdout as String).trim();
}

Future<Map<String, Object?>> _device() async => {
  'model': await _prop('ro.product.model'),
  'product': await _prop('ro.product.name'),
  'manufacturer': await _prop('ro.product.manufacturer'),
  'androidRelease': await _prop('ro.build.version.release'),
  'apiLevel': await _prop('ro.build.version.sdk'),
  'cpuAbi': await _prop('ro.product.cpu.abi'),
  // Non-empty on an emulator, empty on a real phone.
  'qemu': await _prop('ro.kernel.qemu'),
  'avdName': await _prop('ro.boot.qemu.avd_name'),
  'fingerprint': await _prop('ro.build.fingerprint'),
};

Future<void> _run() async {
  final home = await getApplicationSupportDirectory();
  final photos = Directory('${home.path}/photos');
  final out = Directory('${home.path}/mlkit_out')..createSync(recursive: true);
  final device = await _device();
  debugPrint('MLKIT device: ${jsonEncode(device)}');

  final files =
      photos
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  debugPrint('MLKIT found ${files.length} pictures in ${photos.path}');

  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.jpg', '');
    try {
      final bytes = await file.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      descriptor.dispose();
      buffer.dispose();

      final watch = Stopwatch()..start();
      final result = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      watch.stop();
      final json = {
        'picture': '$name.jpg',
        'script': 'latin',
        'pictureSize': {'width': width, 'height': height},
        'sizeNote':
            'Size of the picture file as Flutter decodes it, which is what '
            'ML Kit is handed (the files carry no rotation note).',
        'device': device,
        'readMilliseconds': watch.elapsedMilliseconds,
        'text': result.text,
        'blocks': [for (final b in result.blocks) _block(b)],
      };
      File('${out.path}/$name.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
      debugPrint(
        'MLKIT $name: ${width}x$height, ${result.blocks.length} blocks, '
        '${watch.elapsedMilliseconds} ms',
      );
    } catch (e, s) {
      debugPrint('MLKIT $name FAILED: $e\n$s');
      File('${out.path}/$name.error.txt').writeAsStringSync('$e\n$s');
    }
  }
  await recognizer.close();
  File('${out.path}/DONE').writeAsStringSync('done');
  debugPrint('MLKIT DONE');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('ML Kit test runner'))),
    ),
  );
  _run();
}
