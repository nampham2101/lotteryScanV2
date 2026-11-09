import 'dart:math';

import 'package:image/image.dart' as img;

import 'phone.dart';

// For ticket #22: finds the camera screen's dashed frame in a screenshot, and
// compares a photo with what the frame showed. The frame is found the way a
// person sees it, as the one big square of camera picture on the dark screen,
// so this doesn't depend on how the camera screen is built. The Mac can't
// import Flutter, so this must not either.

/// Pixels this close to the background's brightness are background.
const _backgroundSlack = 6;

/// A row or column of the frame is mostly camera picture. The hint and the
/// shutter cover far less of their rows than this.
const _pictureShare = 0.5;

/// The frame's edge carries the dashes and its corners are rounded, so this
/// much of its side is left out of the comparison on each edge.
const _edgeShare = 0.04;

/// The photo and the frame are compared in squares this many phone pixels
/// wide, so a slightly different size or sharpness doesn't count.
const _squareSize = 8;

/// How far a photo may be from what the frame showed and still be the same
/// picture, from 0 (the same) to 255. Measured on the emulator's room, in both
/// of the camera's views, against photos taken by the app before ticket #22:
/// the middle square of the camera's photo scores about 5 and 7, a square cut
/// 3% smaller about 12 and 17, one cut 10% smaller about 23 and 24, and the
/// whole photo squeezed into a square about 27 and 39.
const sameAsFrameLimit = 10.0;

/// Where the dashed frame is on screen, in phone pixels.
class FrameOnScreen {
  const FrameOnScreen({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  /// The frame is square on screen, so a shape that isn't wasn't the frame.
  bool get isSquare => (width - height).abs() <= max(width, height) * 0.03;

  @override
  String toString() => '($left, $top)-($right, $bottom)';
}

/// The camera screen's background: the brightness most of the screen has.
int _backgroundBrightness(ScreenPixels pixels) {
  final counts = List<int>.filled(256, 0);
  for (var y = 0; y < pixels.height; y += 6) {
    for (var x = 0; x < pixels.width; x += 6) {
      counts[pixels.brightness(x, y)]++;
    }
  }
  var most = 0;
  for (var brightness = 1; brightness < 256; brightness++) {
    if (counts[brightness] > counts[most]) most = brightness;
  }
  return most;
}

/// The longest run of places from 0 to [length] where [isPicture] holds, as
/// (start, end), or null if there's none.
(int, int)? _longestRun(int length, bool Function(int place) isPicture) {
  (int, int)? longest;
  int? start;
  for (var place = 0; place <= length; place++) {
    if (place < length && isPicture(place)) {
      start ??= place;
      continue;
    }
    if (start != null &&
        (longest == null || place - start > longest.$2 - longest.$1)) {
      longest = (start, place);
    }
    start = null;
  }
  return longest;
}

/// Where the screenshot shows the dashed frame, or null if it shows no square
/// of camera picture.
FrameOnScreen? findFrame(ScreenPixels pixels) {
  const step = 4;
  final background = _backgroundBrightness(pixels);
  bool isPicture(int x, int y) =>
      (pixels.brightness(x, y) - background).abs() > _backgroundSlack;

  double shareOfRow(int y, int fromX, int toX) {
    var picture = 0;
    var all = 0;
    for (var x = fromX; x < toX; x += step, all++) {
      if (isPicture(x, y)) picture++;
    }
    return picture / all;
  }

  double shareOfColumn(int x, int fromY, int toY) {
    var picture = 0;
    var all = 0;
    for (var y = fromY; y < toY; y += step, all++) {
      if (isPicture(x, y)) picture++;
    }
    return picture / all;
  }

  final rows = _longestRun(
    pixels.height,
    (y) => shareOfRow(y, 0, pixels.width) >= _pictureShare,
  );
  if (rows == null) return null;
  final (top, bottom) = rows;
  final columns = _longestRun(
    pixels.width,
    (x) => shareOfColumn(x, top, bottom) >= _pictureShare,
  );
  if (columns == null) return null;
  final frame = FrameOnScreen(
    left: columns.$1,
    top: top,
    right: columns.$2,
    bottom: bottom,
  );
  final isBigEnough = frame.width >= pixels.width * 0.3;
  return frame.isSquare && isBigEnough ? frame : null;
}

/// How far [photo], upright, is from what [frame] showed in [pixels], from 0
/// (the same picture) to 255. The photo is stretched over the whole frame, so
/// a photo of more, of less, of another part, or of another shape doesn't
/// match.
double differenceFromFrame(
  img.Image photo,
  ScreenPixels pixels,
  FrameOnScreen frame,
) {
  final across = frame.width ~/ _squareSize;
  final down = frame.height ~/ _squareSize;
  final small = img.copyResize(
    photo,
    width: across,
    height: down,
    interpolation: img.Interpolation.average,
  );
  final squareWidth = frame.width / across;
  final squareHeight = frame.height / down;
  final skipAcross = (across * _edgeShare).ceil();
  final skipDown = (down * _edgeShare).ceil();
  final photoSquares = <double>[];
  final screenSquares = <double>[];
  for (var row = skipDown; row < down - skipDown; row++) {
    for (var column = skipAcross; column < across - skipAcross; column++) {
      final pixel = small.getPixel(column, row);
      photoSquares.add((pixel.r + pixel.g + pixel.b) / 3);
      screenSquares.add(
        _averageBrightness(
          pixels,
          left: frame.left + (column * squareWidth).round(),
          top: frame.top + (row * squareHeight).round(),
          right: frame.left + ((column + 1) * squareWidth).round(),
          bottom: frame.top + ((row + 1) * squareHeight).round(),
        ),
      );
    }
  }
  // The photo comes out a little brighter than the live picture, the same
  // amount all over, so only differences from each one's own average count.
  final photoAverage = _average(photoSquares);
  final screenAverage = _average(screenSquares);
  var total = 0.0;
  for (var square = 0; square < photoSquares.length; square++) {
    total +=
        ((photoSquares[square] - photoAverage) -
                (screenSquares[square] - screenAverage))
            .abs();
  }
  return total / photoSquares.length;
}

double _average(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _averageBrightness(
  ScreenPixels pixels, {
  required int left,
  required int top,
  required int right,
  required int bottom,
}) {
  var total = 0;
  var count = 0;
  for (var y = top; y < bottom; y += 2) {
    for (var x = left; x < right; x += 2) {
      total += pixels.brightness(x, y);
      count++;
    }
  }
  return total / count;
}
