import 'dart:math' as math;

import 'package:flutter/material.dart';

// The movement of ticket #32: 4a's pop-ins and confetti, 4b's wink. It plays
// once, when the screen opens, and draws on top of the screen's layout without
// changing it, so nothing shifts and the buttons keep working while it plays.

/// How long one thing takes to pop in.
const _popTime = Duration(milliseconds: 450);

/// How long after the one before each thing starts to pop in.
const _popGap = Duration(milliseconds: 200);

/// How long the confetti falls.
const _confettiTime = Duration(milliseconds: 2000);

/// 4a's movement: [popCount] things pop in one after another, and confetti
/// bursts from the icon with the first. [controller] counts milliseconds, so
/// each piece can start at its own time.
class CelebrationClock {
  CelebrationClock(TickerProvider vsync, {required int popCount})
    : controller = AnimationController(
        vsync: vsync,
        upperBound: _total(popCount).inMilliseconds.toDouble(),
        duration: _total(popCount),
      );

  final AnimationController controller;

  static Duration _total(int popCount) {
    final lastPopEnds = _popGap * (popCount - 1) + _popTime;
    return lastPopEnds > _confettiTime ? lastPopEnds : _confettiTime;
  }

  void play() => controller.forward(from: 0);

  void dispose() => controller.dispose();
}

/// Grows [child] from small with a slight bounce, as the [place]th thing to
/// pop in (the first is 0). Layout isn't affected, only the drawing.
class PopIn extends StatelessWidget {
  const PopIn({
    required this.clock,
    required this.place,
    required this.child,
    super.key,
  });

  final CelebrationClock clock;
  final int place;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final startsAt = (_popGap * place).inMilliseconds;
    return AnimatedBuilder(
      animation: clock.controller,
      child: child,
      builder: (context, child) {
        final progress =
            ((clock.controller.value - startsAt) / _popTime.inMilliseconds)
                .clamp(0.0, 1.0);
        return Transform.scale(
          scale: Curves.easeOutBack.transform(progress),
          child: child,
        );
      },
    );
  }
}

/// The confetti, burst from the middle of its box and falling down the screen.
/// It overflows its box on every side, so put it where it can draw over the
/// whole screen, and not where it takes touches.
class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({required this.clock, super.key});

  final CelebrationClock clock;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ConfettiPainter(clock.controller)),
    );
  }
}

class _Piece {
  _Piece(math.Random random)
    : angle = random.nextDouble() * 2 * math.pi,
      speed = 120 + random.nextDouble() * 260,
      size = 6 + random.nextDouble() * 5,
      spin = random.nextDouble() * 6,
      color = _colors[random.nextInt(_colors.length)];

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;
}

const _colors = [
  Color(0xFFE53935),
  Color(0xFFFFB300),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
  Color(0xFF00ACC1),
];

const _pieceCount = 44;
const _gravity = 520.0;
const _drag = 1.6;

/// The share of the fall after which the pieces fade out.
const _fadeFrom = 0.7;

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.controller) : super(repaint: controller);

  final AnimationController controller;

  // The same pieces on every run, so the movement is the same every time.
  static final _pieces = _makePieces();

  static List<_Piece> _makePieces() {
    final random = math.Random(32);
    return [for (var i = 0; i < _pieceCount; i++) _Piece(random)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = controller.value / 1000;
    final share = seconds / (_confettiTime.inMilliseconds / 1000);
    if (share >= 1) return;
    final opacity = share < _fadeFrom
        ? 1.0
        : 1 - (share - _fadeFrom) / (1 - _fadeFrom);
    for (final piece in _pieces) {
      final across = math.cos(piece.angle) * piece.speed;
      final up = math.sin(piece.angle) * piece.speed - 120;
      final x = across * (1 - math.exp(-_drag * seconds)) / _drag;
      final y = up * seconds + 0.5 * _gravity * seconds * seconds;
      canvas.save();
      canvas.translate(size.width / 2 + x, size.height / 2 + y);
      canvas.rotate(piece.spin * seconds);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size * 0.55,
        ),
        Paint()..color = piece.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

/// 4b's smiley: about half a second after it appears, it grows slightly,
/// winks once and goes back to its size. [icon] is drawn as it was before.
class WinkingSmiley extends StatefulWidget {
  const WinkingSmiley({
    required this.icon,
    required this.size,
    required this.color,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  State<WinkingSmiley> createState() => _WinkingSmileyState();
}

const _winkStartsAt = 500;
const _winkTotal = 1500;

class _WinkingSmileyState extends State<WinkingSmiley>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    upperBound: (_winkStartsAt + _winkTotal).toDouble(),
    duration: const Duration(milliseconds: _winkStartsAt + _winkTotal),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 0 to 1 over the winking part, after the half second of waiting.
  double get _progress =>
      ((_controller.value - _winkStartsAt) / _winkTotal).clamp(0.0, 1.0);

  // Grows over the first 20%, stays grown, then goes back over the last 20%.
  double get _scale {
    final p = _progress;
    final grown = p < 0.2 ? p / 0.2 : (p > 0.8 ? (1 - p) / 0.2 : 1.0);
    return 1 + 0.2 * Curves.easeInOut.transform(grown);
  }

  bool get _isEyeClosed => _progress > 0.3 && _progress < 0.65;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: _scale,
        child: CustomPaint(
          foregroundPainter: _isEyeClosed
              ? _ClosedEyePainter(widget.color)
              : null,
          child: Icon(widget.icon, size: widget.size, color: widget.color),
        ),
      ),
    );
  }
}

/// Covers the smiley's right eye and draws it closed. The numbers are the
/// eye's place in the icon's 24 by 24 drawing.
class _ClosedEyePainter extends CustomPainter {
  _ClosedEyePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    canvas.drawCircle(
      Offset(15.5, 9.5) * unit,
      2.2 * unit,
      Paint()..color = Colors.white,
    );
    final eye = Path()
      ..moveTo(13.8 * unit, 10.2 * unit)
      ..quadraticBezierTo(15.5 * unit, 8.2 * unit, 17.2 * unit, 10.2 * unit);
    canvas.drawPath(
      eye,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * unit
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ClosedEyePainter old) => old.color != color;
}
