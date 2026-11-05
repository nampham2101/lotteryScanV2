import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'app_screen.dart';
import 'phone.dart';

// Compares what's on the phone's screen with a photo file, for tickets #10 and
// #18. This accepts any way of drawing the photo: all it asks is that the
// picture is there, whole, above any text, the way a person would see it. Its
// size is free, because #18 leaves it open how the space is shared with the
// text, so the photo is searched for at every size.

/// The screen and the photo are compared in squares of this many phone pixels,
/// so resizing the photo doesn't count as a difference.
const _squareSize = 8;
const _samplesPerSquare = 4;

/// How far the screen may be from the photo and still be showing it, on a
/// scale of 0 (the same) to 255. Measured on the emulator's room: the right
/// photo scores about 3, a cropped one about 20, and a sideways or older one
/// about 50.
const samePictureLimit = 10.0;

/// Below this share of the screen's width there's too little picture for a
/// match to mean anything.
const _smallestPhotoShare = 0.25;

/// The photo's edges may land up to this many squares past the room it has,
/// because they rarely sit exactly on a square.
const _edgeSlack = 1;

/// Where a photo is drawn on screen, in squares, and how far it is from the
/// real photo.
class PhotoPlace {
  const PhotoPlace({
    required this.left,
    required this.top,
    required this.difference,
    required this.columns,
  });

  final int left;
  final int top;
  final int columns;
  final double difference;
}

/// A photo the way a person should see it. Cameras often store a photo on its
/// side, with a note in the file saying which way is up.
img.Image uprightPhoto(List<int> jpeg) {
  final photo = img.decodeJpg(Uint8List.fromList(jpeg));
  if (photo == null) throw StateError('the kept photo is not a JPEG');
  return img.bakeOrientation(photo);
}

/// Where the screen shows [photo] whole, at any size that fits between the
/// phone's top bar and the first text, or null if it doesn't. A cropped,
/// stretched or sideways photo isn't found.
PhotoPlace? findPhoto(img.Image photo, ScreenPixels pixels, AppScreen screen) {
  final squares = _ScreenSquares(pixels);
  final firstRow = (screen.barsTop / _squareSize).ceil();
  final endRow = (_topOfText(screen) / _squareSize).floor();
  PhotoPlace? best;
  final smallest = (squares.columns * _smallestPhotoShare).ceil();
  for (var columns = squares.columns; columns >= smallest; columns--) {
    final found = squares.bestPlace(
      _fitted(photo, columns, squares.columns),
      firstRow: firstRow,
      endRow: endRow,
      limit: best?.difference ?? samePictureLimit,
    );
    best = found ?? best;
  }
  return best;
}

/// How far the screen is from [photo] at the place it was found earlier.
double differenceAtPlace(
  img.Image photo,
  PhotoPlace place,
  ScreenPixels pixels,
  AppScreen screen,
) {
  final squares = _ScreenSquares(pixels);
  return squares.differenceFrom(
    _fitted(photo, place.columns, squares.columns),
    left: place.left,
    top: place.top,
    firstRow: (screen.barsTop / _squareSize).ceil(),
    limit: double.infinity,
  )!;
}

/// Where the first text starts, or the phone's bottom bar if there's no text.
double _topOfText(AppScreen screen) => screen.texts.fold(
  screen.height - screen.barsBottom,
  (top, text) => min(top, text.top),
);

/// Every search would otherwise shrink the photo again at each size.
final _fittedPhotos = Expando<Map<int, _FittedPhoto>>();

_FittedPhoto _fitted(img.Image photo, int columns, int screenColumns) {
  final sizes = _fittedPhotos[photo] ??= {};
  return sizes[columns] ??= _FittedPhoto(
    _shrunk(photo, screenColumns),
    columns,
  );
}

/// The photo a little larger than it can ever be compared at.
final _shrunkPhotos = Expando<img.Image>();

img.Image _shrunk(img.Image photo, int screenColumns) =>
    _shrunkPhotos[photo] ??= img.copyResize(
      photo,
      width: screenColumns * 2,
      interpolation: img.Interpolation.average,
    );

/// A photo at one size, one brightness per square.
class _FittedPhoto {
  _FittedPhoto(img.Image photo, this.columns)
    : rows = (columns * photo.height / photo.width).round() {
    final fitted = img.copyResize(
      photo,
      width: columns,
      height: rows,
      interpolation: img.Interpolation.average,
    );
    brightness = Float64List(columns * rows);
    for (final pixel in fitted) {
      brightness[pixel.y * columns + pixel.x] =
          (pixel.r + pixel.g + pixel.b) / 3;
    }
  }

  final int columns;
  final int rows;
  late final Float64List brightness;
}

/// The screen as a grid of squares, each holding its average brightness.
class _ScreenSquares {
  _ScreenSquares(ScreenPixels pixels)
    : columns = pixels.width ~/ _squareSize,
      rows = pixels.height ~/ _squareSize {
    final sampleStep = _squareSize ~/ _samplesPerSquare;
    _brightness = Float64List.fromList([
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          _averageBrightness(pixels, column, row, sampleStep),
    ]);
  }

  final int columns;
  final int rows;
  late final Float64List _brightness;

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

  /// The closest place for [fitted] between the rows, if any is under [limit].
  PhotoPlace? bestPlace(
    _FittedPhoto fitted, {
    required int firstRow,
    required int endRow,
    required double limit,
  }) {
    PhotoPlace? best;
    final lowestTop = max(0, firstRow - _edgeSlack);
    final highestTop = min(endRow + _edgeSlack, rows) - fitted.rows;
    for (var top = lowestTop; top <= highestTop; top++) {
      for (var left = 0; left <= columns - fitted.columns; left++) {
        final difference = differenceFrom(
          fitted,
          left: left,
          top: top,
          firstRow: firstRow,
          limit: best?.difference ?? limit,
        );
        if (difference == null) continue;
        best = PhotoPlace(
          left: left,
          top: top,
          columns: fitted.columns,
          difference: difference,
        );
      }
    }
    return best;
  }

  /// The average difference per square with [fitted] placed at [left], [top],
  /// or null as soon as it can't stay under [limit]. Rows under the phone's
  /// top bar aren't compared.
  double? differenceFrom(
    _FittedPhoto fitted, {
    required int left,
    required int top,
    required int firstRow,
    required double limit,
  }) {
    final startY = max(0, firstRow - top);
    final compared = (fitted.rows - startY) * fitted.columns;
    final mostAllowed = limit * compared;
    var total = 0.0;
    for (var y = startY; y < fitted.rows; y++) {
      final screenStart = (top + y) * columns + left;
      final photoStart = y * fitted.columns;
      for (var x = 0; x < fitted.columns; x++) {
        total +=
            (_brightness[screenStart + x] - fitted.brightness[photoStart + x])
                .abs();
      }
      if (total > mostAllowed) return null;
    }
    return total / compared;
  }
}
