import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'app_screen.dart';
import 'phone.dart';

// Compares what's on the phone's screen with a photo file, for ticket #10. This
// accepts any way of drawing the photo: all it asks is that the picture is
// there, whole, as large as the screen allows, the way a person would see it.

/// The screen and the photo are compared in squares of this many phone pixels,
/// so resizing the photo doesn't count as a difference.
const _squareSize = 8;
const _samplesPerSquare = 4;

/// How far the screen may be from the photo and still be showing it, on a
/// scale of 0 (the same) to 255. Measured on the emulator's room: the right
/// photo scores about 3, a cropped one about 20, and a sideways or older one
/// about 50.
const samePictureLimit = 10.0;

/// A photo the way a person should see it. Cameras often store a photo on its
/// side, with a note in the file saying which way is up.
img.Image uprightPhoto(List<int> jpeg) {
  final photo = img.decodeJpg(Uint8List.fromList(jpeg));
  if (photo == null) throw StateError('the kept photo is not a JPEG');
  return img.bakeOrientation(photo);
}

/// How far the screen is from showing [photo] whole, at the largest size that
/// fits, on the full screen or between the phone's bars. The photo may sit
/// anywhere in the room left over. The phone's bars are not compared.
double differenceFromScreen(
  img.Image photo,
  ScreenPixels pixels,
  AppScreen screen,
) {
  final squares = _ScreenSquares(pixels);
  final firstRow = (screen.barsTop / _squareSize).ceil();
  final lastRow = ((screen.height - screen.barsBottom) / _squareSize).floor();

  double differenceWhenFittedTo(double width, double height) {
    final scale = min(width / photo.width, height / photo.height);
    final fitted = img.copyResize(
      photo,
      width: (photo.width * scale / _squareSize).round(),
      height: (photo.height * scale / _squareSize).round(),
      interpolation: img.Interpolation.average,
    );
    var smallest = double.infinity;
    for (var top = 0; top <= squares.rows - fitted.height; top++) {
      for (var left = 0; left <= squares.columns - fitted.width; left++) {
        final difference = squares.differenceFrom(
          fitted,
          left: left,
          top: top,
          firstRow: firstRow,
          lastRow: lastRow,
        );
        smallest = min(smallest, difference);
      }
    }
    return smallest;
  }

  return min(
    differenceWhenFittedTo(screen.width, screen.height),
    differenceWhenFittedTo(
      screen.width,
      screen.height - screen.barsTop - screen.barsBottom,
    ),
  );
}

/// The screen as a grid of squares, each holding its average brightness.
class _ScreenSquares {
  _ScreenSquares(ScreenPixels pixels)
    : columns = pixels.width ~/ _squareSize,
      rows = pixels.height ~/ _squareSize {
    final sampleStep = _squareSize ~/ _samplesPerSquare;
    _brightness = [
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          _averageBrightness(pixels, column, row, sampleStep),
    ];
  }

  final int columns;
  final int rows;
  late final List<double> _brightness;

  double _averageBrightness(
    ScreenPixels pixels,
    int column,
    int row,
    int step,
  ) {
    var total = 0;
    for (var y = 0; y < _squareSize; y += step) {
      for (var x = 0; x < _squareSize; x += step) {
        total += pixels.brightness(
          column * _squareSize + x,
          row * _squareSize + y,
        );
      }
    }
    return total / (_samplesPerSquare * _samplesPerSquare);
  }

  /// The average difference per square with [fitted] placed at [left], [top].
  double differenceFrom(
    img.Image fitted, {
    required int left,
    required int top,
    required int firstRow,
    required int lastRow,
  }) {
    var total = 0.0;
    var compared = 0;
    for (final pixel in fitted) {
      final row = top + pixel.y;
      if (row < firstRow || row >= lastRow) continue;
      final brightness = (pixel.r + pixel.g + pixel.b) / 3;
      total += (_brightness[row * columns + left + pixel.x] - brightness).abs();
      compared++;
    }
    return total / compared;
  }
}
