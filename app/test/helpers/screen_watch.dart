import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Shared by the widget tests of ticket #32: opening a screen the way the app
// does, then watching it frame by frame with the test's own clock. The ticket
// leaves open how the movement is built, so it's watched the way a person sees
// it: how large each thing is drawn, and what the screen's pixels show.

/// The Pixel_10's screen in logical pixels. It's drawn at one pixel each, so
/// that a picture of it stays small enough to take at every frame.
const phoneScreen = Size(411, 923);

/// One frame at 60 frames a second, rounded down.
const frame = Duration(milliseconds: 16);

/// What the screen under the opened one shows.
const belowScreenText = 'Màn hình bên dưới';

/// Page changes here draw no movement of their own, so anything that moves is
/// the opened screen's own. The page change still takes its usual time.
class _NoPageMovement extends PageTransitionsBuilder {
  const _NoPageMovement();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Opens [screen] the way the app opens an answer screen: as a new page on top
/// of another screen. Returns once its first frame is drawn, which is time
/// zero for the watching that follows.
Future<void> openScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = phoneScreen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // The debug banner would sit in the top corner, where the smiley is
      // looked for.
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const _NoPageMovement(),
          },
        ),
      ),
      home: const Scaffold(body: Center(child: Text(belowScreenText))),
    ),
  );
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  final page = MaterialPageRoute<void>(builder: (_) => screen);
  unawaited(navigator.push(page));
  // A new page is laid out off screen for its first frame, so its heroes can
  // be measured. It opens on the first frame it's drawn on screen.
  bool isOnScreen() {
    final object = page.subtreeContext?.findRenderObject();
    return object != null && _opacityOf(object) > 0;
  }

  await tester.pump();
  for (var tries = 0; tries < 5 && !isOnScreen(); tries++) {
    await tester.pump();
  }
  expect(isOnScreen(), isTrue, reason: 'SETUP: the screen never opened');
}

/// How see-through [object] is drawn, from 0 (not at all) to 1 (fully), from
/// every fade above it.
double _opacityOf(RenderObject object) {
  var opacity = 1.0;
  RenderObject? node = object;
  while (node != null) {
    if (node is RenderOffstage && node.offstage) return 0;
    if (node is RenderOpacity) opacity *= node.opacity;
    if (node is RenderAnimatedOpacityMixin) opacity *= node.opacity.value;
    node = node.parent;
  }
  return opacity;
}

/// Below this, a fade counts as not shown yet.
const _shownOpacity = 0.05;

/// Where the first thing [finder] finds is drawn on screen now, with any
/// growing or shrinking applied, or null when it isn't shown: not there, not
/// drawn, faded out or of no size.
Rect? shownRect(Finder finder) {
  final elements = finder.evaluate();
  return elements.isEmpty ? null : _shownRectOf(elements.first);
}

/// Where everything [finder] finds is drawn on screen now, leaving out what
/// isn't shown.
List<Rect> shownRects(Finder finder) => [
  for (final element in finder.evaluate()) ?_shownRectOf(element),
];

Rect? _shownRectOf(Element element) {
  final object = element.renderObject;
  if (object is! RenderBox || !object.attached || !object.hasSize) return null;
  if (_opacityOf(object) < _shownOpacity) return null;
  final rect = Rect.fromPoints(
    object.localToGlobal(Offset.zero),
    object.localToGlobal(object.size.bottomRight(Offset.zero)),
  );
  return rect.width < 0.5 || rect.height < 0.5 ? null : rect;
}

/// A picture of the whole screen, pixel by pixel.
class ScreenPicture {
  ScreenPicture(this.width, this.height, this._rgba);

  final int width;
  final int height;
  final Uint8List _rgba;

  /// Every second pixel, both ways, is compared. Confetti is larger than that.
  static const _step = 2;

  /// Smaller colour differences don't count as a change.
  static const _smallestChange = 24;

  int _start(int x, int y) => (y * width + x) * 4;

  bool _isSameAt(ScreenPicture other, int x, int y) =>
      !_differ(_rgba, _start(x, y), other._rgba, _start(x, y));

  static bool _differ(Uint8List a, int aStart, Uint8List b, int bStart) {
    for (var channel = 0; channel < 3; channel++) {
      if ((a[aStart + channel] - b[bStart + channel]).abs() >=
          _smallestChange) {
        return true;
      }
    }
    return false;
  }

  /// The places where this picture differs from [other], sampled, leaving out
  /// those inside [except].
  List<Offset> changesFrom(
    ScreenPicture other, {
    List<Rect> except = const [],
  }) {
    final changes = <Offset>[];
    for (var y = 0; y < height; y += _step) {
      for (var x = 0; x < width; x += _step) {
        if (_isSameAt(other, x, y)) continue;
        final place = Offset(x.toDouble(), y.toDouble());
        if (except.any((rect) => rect.contains(place))) continue;
        changes.add(place);
      }
    }
    return changes;
  }

  bool isSameAs(ScreenPicture other) => changesFrom(other).isEmpty;

  /// The smallest box around every pixel inside [area] that isn't the colour
  /// of the screen's top left corner, the background. Null if there's none.
  Rect? drawnBoxIn(Rect area) {
    double? left, top, right, bottom;
    final firstRow = math.max(0, area.top.ceil());
    final endRow = math.min(height, area.bottom.floor());
    final firstColumn = math.max(0, area.left.ceil());
    final endColumn = math.min(width, area.right.floor());
    for (var y = firstRow; y < endRow; y++) {
      for (var x = firstColumn; x < endColumn; x++) {
        if (!_differ(_rgba, _start(x, y), _rgba, _start(0, 0))) continue;
        left = left == null || x < left ? x.toDouble() : left;
        right = right == null || x + 1 > right ? x + 1.0 : right;
        top ??= y.toDouble();
        bottom = y + 1.0;
      }
    }
    if (left == null) return null;
    return Rect.fromLTRB(left, top!, right!, bottom!);
  }
}

/// A picture of what the screen shows now.
Future<ScreenPicture> pictureOfScreen(WidgetTester tester) async {
  final picture = await tester.runAsync(() async {
    final image = await captureImage(tester.element(find.byType(MaterialApp)));
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return ScreenPicture(
        image.width,
        image.height,
        bytes!.buffer.asUint8List(),
      );
    } finally {
      image.dispose();
    }
  });
  return picture!;
}

/// One look at the screen while watching: when, how wide each watched thing
/// is drawn (null when not shown), and a picture of the screen, if one was
/// taken then.
class Look {
  Look(this.at, this.widths, this.picture);

  final Duration at;
  final Map<String, double?> widths;
  final ScreenPicture? picture;

  @override
  String toString() => '${seconds(at)}: $widths';
}

String seconds(Duration time) =>
    '${(time.inMilliseconds / 1000).toStringAsFixed(3)} s';

/// Watches the screen opened at time zero, one frame at a time, until [until]
/// has passed since then. [items] are measured at every frame. A picture is
/// taken every [pictureEvery], or never if it's null.
Future<List<Look>> watchScreen(
  WidgetTester tester, {
  required Duration until,
  Map<String, Finder> items = const {},
  Duration? pictureEvery = frame,
}) async {
  final looks = <Look>[];
  var at = Duration.zero;
  Duration? lastPicture;
  while (true) {
    final isPictureDue =
        pictureEvery != null &&
        (lastPicture == null || at - lastPicture >= pictureEvery);
    if (isPictureDue) lastPicture = at;
    looks.add(
      Look(at, {
        for (final MapEntry(:key, :value) in items.entries)
          key: shownRect(value)?.width,
      }, isPictureDue ? await pictureOfScreen(tester) : null),
    );
    if (at >= until) return looks;
    await tester.pump(frame);
    at += frame;
  }
}

/// From [from] for [howLong], one look every [step]: Then the screen stays
/// exactly as [still] shows it at every look.
Future<void> expectStaysAs(
  WidgetTester tester,
  ScreenPicture still, {
  required Duration from,
  required Duration howLong,
  Duration step = const Duration(milliseconds: 250),
  required String reason,
}) async {
  for (var waited = Duration.zero; waited < howLong; waited += step) {
    await tester.pump(step);
    final changes = (await pictureOfScreen(tester)).changesFrom(still);
    expect(
      changes,
      isEmpty,
      reason:
          '$reason: at ${seconds(from + waited + step)}, ${changes.length} '
          'sampled pixels changed, the first at ${changes.firstOrNull}',
    );
  }
}

/// Then: nothing is waiting to be drawn, so no movement is still going on.
void expectNothingScheduled(WidgetTester tester, String reason) {
  expect(tester.binding.hasScheduledFrame, isFalse, reason: reason);
}
