import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_watch.dart';

// The checks of ticket #32's widget tests, from what screen_watch.dart sees:
// what "pop in", "a slight bounce", "confetti" and "grows slightly" mean in
// numbers. The numbers and why they were chosen are in docs/tests/32.md.

/// "Growing from small": when first shown, at most this share of its size.
const _smallStart = 0.6;

/// Within this share of its size counts as having reached it.
const _reached = 0.02;

/// "A slight bounce": once it has reached its size, it goes past it, or falls
/// back from it, by at least this share...
const _bounceAtLeast = 0.02;

/// ...and "slight": it's never drawn larger than this many times its size...
const _slightestLargest = 1.5;

/// ...nor, once it has reached its size, smaller than this share of it.
const _slightestSmallest = 0.6;

/// "One after another": each starts at least this long after the one before.
const _popGap = Duration(milliseconds: 50);

/// How one thing on screen came into view.
class PopIn {
  PopIn._(this.name, this.firstShown, this.sizes);

  final String name;

  /// When it was first shown.
  final Duration firstShown;

  /// From then on, at each frame, its width as a share of its width once the
  /// movement is over. 0 when it isn't shown.
  final List<({Duration at, double size})> sizes;

  double get startSize => sizes.first.size;

  @override
  String toString() =>
      '$name, first shown at ${seconds(firstShown)}: ${[for (final size in sizes) '${seconds(size.at)} ${size.size.toStringAsFixed(2)}'].join(', ')}';
}

/// How [name] came into view in [looks], which must go on until the
/// movement is over.
PopIn popInOf(String name, List<Look> looks) {
  final finalWidth = looks.last.widths[name];
  expect(
    finalWidth,
    isNotNull,
    reason: '$name is not shown at ${seconds(looks.last.at)}',
  );
  final firstShown = looks.indexWhere((look) => look.widths[name] != null);
  return PopIn._(name, looks[firstShown].at, [
    for (final look in looks.skip(firstShown))
      (at: look.at, size: (look.widths[name] ?? 0) / finalWidth!),
  ]);
}

/// Then: [popIn] grew from small, with a slight bounce, to its size.
void expectPopsInWithBounce(PopIn popIn) {
  expect(
    popIn.startSize,
    lessThanOrEqualTo(_smallStart),
    reason:
        '${popIn.name} did not grow from small: when first shown, at '
        '${seconds(popIn.firstShown)}, it was already '
        '${(popIn.startSize * 100).round()}% of its size. $popIn',
  );
  final largest = popIn.sizes.map((size) => size.size).reduce(math.max);
  expect(
    largest,
    lessThanOrEqualTo(_slightestLargest),
    reason: '${popIn.name} bounced more than slightly. $popIn',
  );
  final reachedAt = popIn.sizes.indexWhere((size) => size.size >= 1 - _reached);
  final afterReached = popIn.sizes.skip(reachedAt).map((size) => size.size);
  expect(
    afterReached.any((size) => (size - 1).abs() >= _bounceAtLeast),
    isTrue,
    reason:
        '${popIn.name} grew to its size without a bounce: once there, it '
        'never went past it or fell back from it. $popIn',
  );
  expect(
    afterReached.reduce(math.min),
    greaterThanOrEqualTo(_slightestSmallest),
    reason: '${popIn.name} bounced more than slightly. $popIn',
  );
}

/// Then: [popIns] started one after another, in the order given.
void expectOneAfterAnother(List<PopIn> popIns) {
  for (var i = 1; i < popIns.length; i++) {
    expect(
      popIns[i].firstShown - popIns[i - 1].firstShown,
      greaterThanOrEqualTo(_popGap),
      reason:
          '${popIns[i].name} did not pop in after ${popIns[i - 1].name}: '
          'first shown at ${seconds(popIns[i].firstShown)} and '
          '${seconds(popIns[i - 1].firstShown)}',
    );
  }
}

/// The share a bounce may grow something by, on each side, plus a margin.
const _bounceRoom = (_slightestLargest - 1) / 2;
const _margin = 4.0;

/// Where the screen's own things are drawn once still: every text, the icon,
/// the ticket card and the button, as large as a slight bounce could draw
/// them. Confetti is what moves outside them.
List<Rect> thingsOnScreen(Finder icon, Finder card) => [
  for (final rect in [
    ...shownRects(find.byType(Text)),
    ...shownRects(icon),
    ...shownRects(card),
    ...shownRects(find.byWidgetPredicate((w) => w is ButtonStyleButton)),
  ])
    Rect.fromLTRB(
      rect.left - rect.width * _bounceRoom - _margin,
      rect.top - rect.height * _bounceRoom - _margin,
      rect.right + rect.width * _bounceRoom + _margin,
      rect.bottom + rect.height * _bounceRoom + _margin,
    ),
];

/// Fewer changed pixels than this outside the screen's things isn't confetti.
const _confettiAtLeast = 4;

/// "Bursts from the icon": the first confetti seen is centred within this
/// distance of the icon's centre.
const _nearIcon = 160.0;

/// "As they pop in": the confetti is first seen no later than this after the
/// last thing to pop in was first shown.
const _burstLatest = Duration(milliseconds: 500);

/// "Falls down the screen": it's seen in the bottom quarter of the screen.
const _bottomQuarter = 0.75;

/// "For about 2 seconds": from first seen to last seen.
const _shortestConfetti = Duration(milliseconds: 1300);
const _longestConfetti = Duration(seconds: 3);

/// "Plays once": the confetti is never gone for longer than this before it's
/// over.
const _longestGap = Duration(milliseconds: 500);

/// "Then the screen stays still": nothing changes later than this after the
/// last confetti.
const _stillAfterConfetti = Duration(milliseconds: 500);

/// Then: as [popIns] pop in, confetti bursts from [icon], falls down the
/// screen for about 2 seconds, once, and then the screen stays still. [looks]
/// must go on until well after the movement is over; the last one is the
/// still screen.
void expectConfettiOnce(
  List<Look> looks,
  List<PopIn> popIns, {
  required Rect icon,
  required List<Rect> things,
}) {
  final still = looks.last.picture!;
  final pictured = looks.where((look) => look.picture != null).toList();
  final confetti = [
    for (final look in pictured)
      if (look.picture!.changesFrom(still, except: things) case final changes
          when changes.length >= _confettiAtLeast)
        (at: look.at, changes: changes),
  ];
  expect(
    confetti,
    isNotEmpty,
    reason:
        'no confetti: nothing moved outside the icon, the words, the card and '
        'the button',
  );
  final first = confetti.first;
  final lastPopIn = popIns
      .map((popIn) => popIn.firstShown)
      .reduce((a, b) => a > b ? a : b);
  expect(
    first.at,
    lessThanOrEqualTo(lastPopIn + _burstLatest),
    reason:
        'the confetti did not burst as they popped in: first seen at '
        '${seconds(first.at)}, and the last one popped in at '
        '${seconds(lastPopIn)}',
  );
  final centre = _centreOf(first.changes);
  expect(
    (centre - icon.center).distance,
    lessThanOrEqualTo(_nearIcon),
    reason:
        'the confetti did not burst from the icon: first seen at '
        '${seconds(first.at)} around $centre, and the icon is at '
        '${icon.center}',
  );
  final bottomQuarter = still.height * _bottomQuarter;
  expect(
    confetti.any(
      (look) => look.changes.any((place) => place.dy >= bottomQuarter),
    ),
    isTrue,
    reason:
        'the confetti did not fall down the screen: it never reached the '
        'bottom quarter, below ${bottomQuarter.round()}',
  );
  final last = confetti.last;
  expect(
    last.at - first.at,
    allOf(
      greaterThanOrEqualTo(_shortestConfetti),
      lessThanOrEqualTo(_longestConfetti),
    ),
    reason:
        'the confetti did not fall for about 2 seconds: seen from '
        '${seconds(first.at)} to ${seconds(last.at)}',
  );
  for (var i = 1; i < confetti.length; i++) {
    expect(
      confetti[i].at - confetti[i - 1].at,
      lessThanOrEqualTo(_longestGap),
      reason:
          'the confetti did not play once: gone from '
          '${seconds(confetti[i - 1].at)} to ${seconds(confetti[i].at)}, '
          'then back',
    );
  }
  for (final look in pictured.where(
    (look) => look.at > last.at + _stillAfterConfetti,
  )) {
    final changes = look.picture!.changesFrom(still);
    expect(
      changes,
      isEmpty,
      reason:
          'the screen did not stay still after the confetti, last seen at '
          '${seconds(last.at)}: at ${seconds(look.at)}, ${changes.length} '
          'sampled pixels still changed, the first at ${changes.first}',
    );
  }
}

Offset _centreOf(List<Offset> places) {
  final sum = places.fold(Offset.zero, (sum, place) => sum + place);
  return sum / places.length.toDouble();
}

/// "About half a second later": the smiley starts to move this long after
/// the screen opens, at the soonest and at the latest.
const _soonestWink = Duration(milliseconds: 250);
const _latestWink = Duration(seconds: 1);

/// "Grows slightly": it's drawn at least this many times its width...
const _leastGrowth = 1.05;

/// ...and at most this many.
const _mostGrowth = 1.5;

/// The movement is over this long after the screen opens, at the latest.
const _winkOverBy = Duration(seconds: 3);

/// Then: about half a second after the screen opened, the smiley above
/// [title], and nothing else, grew slightly, and by the end of [looks] the
/// screen is exactly as it was when it opened. Returns when the movement
/// ended.
Duration expectSmileyGrowsSlightly(List<Look> looks, Rect title) {
  final opened = looks.first.picture!;
  final smileyArea = Rect.fromLTRB(0, 0, opened.width.toDouble(), title.top);
  final stillSmiley = opened.drawnBoxIn(smileyArea);
  expect(stillSmiley, isNotNull, reason: 'no smiley above the title');
  final moving = [
    for (final look in looks)
      if (look.picture!.changesFrom(opened) case final changes
          when changes.isNotEmpty)
        (at: look.at, changes: changes, picture: look.picture!),
  ];
  expect(
    moving,
    isNotEmpty,
    reason: 'nothing moved in ${seconds(looks.last.at)}',
  );
  expect(
    moving.first.at,
    allOf(greaterThanOrEqualTo(_soonestWink), lessThanOrEqualTo(_latestWink)),
    reason:
        'the movement did not start about half a second after the screen '
        'opened, but at ${seconds(moving.first.at)}',
  );
  for (final look in moving) {
    final below = look.changes.where((place) => place.dy >= title.top);
    expect(
      below,
      isEmpty,
      reason:
          'something other than the smiley moved: at ${seconds(look.at)}, '
          'at ${below.firstOrNull}, at or below the title (${title.top})',
    );
  }
  final widest = moving
      .map((look) => look.picture.drawnBoxIn(smileyArea)?.width ?? 0)
      .reduce(math.max);
  expect(
    widest / stillSmiley!.width,
    allOf(greaterThanOrEqualTo(_leastGrowth), lessThanOrEqualTo(_mostGrowth)),
    reason:
        'the smiley did not grow slightly: ${stillSmiley.width} wide when '
        'still, and at most $widest while moving',
  );
  expect(
    moving.last.at,
    lessThanOrEqualTo(_winkOverBy),
    reason:
        'the movement was not over by ${seconds(_winkOverBy)}: it still '
        'changed at ${seconds(moving.last.at)}',
  );
  return moving.last.at;
}
