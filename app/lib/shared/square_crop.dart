import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The middle square of the picture, turned upright and saved as a JPEG with
/// none of the camera's notes (EXIF) in it. The notes can hold a small copy of
/// the whole uncropped picture, and only the cropped photo may be kept. Throws
/// when the bytes are not a picture.
Uint8List cropToMiddleSquare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Not a picture');
  // The camera may note the turn in the file instead of turning the pixels.
  final upright = img.bakeOrientation(decoded);
  final side = math.min(upright.width, upright.height);
  final square = img.copyCrop(
    upright,
    x: (upright.width - side) ~/ 2,
    y: (upright.height - side) ~/ 2,
    width: side,
    height: side,
  );
  // An empty note makes the encoder write no EXIF segment at all.
  square.exif = img.ExifData();
  return img.encodeJpg(square, quality: 95);
}
