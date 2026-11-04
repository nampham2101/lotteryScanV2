import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'shared/ticket_photo.dart';

const _screenBackground = Color(0xFF222222);
const _shutterSize = 88.0;

// Where sketch 2 puts things, as a share of the screen: the hint 7% down, the
// square frame as wide as 89% of the screen with its middle 44% down, the
// shutter's middle 13% up from the bottom. Phones are taller than the sketch,
// so the frame keeps its square shape and its middle, not its height.
const _hintTop = 0.06;
const _frameCenter = 0.44;
const _frameSideInset = 0.055;
const _shutterCenterFromBottom = 0.13;

/// Sketch 2: the live camera picture inside a dashed frame, with a round
/// shutter button. It takes a camera that is already running, so it only opens
/// once access is allowed. Closes by itself after the photo is kept, so the
/// home screen shows again.
class CameraScreen extends StatefulWidget {
  const CameraScreen({required this.controller, super.key});

  final CameraController controller;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isTakingPhoto = false;

  // True once this screen is closing, by the person's back or by itself.
  // Closing twice would take the home screen away too, and a photo finished
  // after the person left must not be kept.
  bool _isLeaving = false;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_isTakingPhoto || _isLeaving) return;
    _isTakingPhoto = true;
    final XFile photo;
    try {
      photo = await widget.controller.takePicture();
    } on CameraException {
      // Leaving closes the camera under a photo that is still being taken.
      if (_isLeaving) return;
      rethrow;
    }
    if (_isLeaving) return deleteTicketPhotoFile(photo.path);
    final kept = await keepTicketPhoto(photo);
    if (_isLeaving) return deleteTicketPhotoFile(kept.path);
    _isLeaving = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _isLeaving = true;
      },
      child: Scaffold(
        backgroundColor: _screenBackground,
        body: LayoutBuilder(
          builder: (context, screen) {
            final frameSide = screen.maxWidth * (1 - 2 * _frameSideInset);
            return Stack(
              children: [
                Positioned(
                  top: screen.maxHeight * _hintTop,
                  left: 0,
                  right: 0,
                  child: const Text(
                    'Đặt vé vào khung',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: screen.maxHeight * _frameCenter - frameSide / 2,
                  left: screen.maxWidth * _frameSideInset,
                  width: frameSide,
                  height: frameSide,
                  child: _CameraFrame(controller: widget.controller),
                ),
                Positioned(
                  bottom:
                      screen.maxHeight * _shutterCenterFromBottom -
                      _shutterSize / 2,
                  left: 0,
                  right: 0,
                  child: Center(child: _ShutterButton(onPressed: _takePhoto)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The dashed frame, with the live picture filling it.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedFramePainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 100,
              // The preview is wider than tall, and the phone is held
              // upright, so the picture's height is the longer side.
              height: 100 * controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  static const _dashLength = 10.0;
  static const _gapLength = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final line in outline.computeMetrics()) {
      for (var at = 0.0; at < line.length; at += _dashLength + _gapLength) {
        canvas.drawPath(line.extractPath(at, at + _dashLength), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedFramePainter oldDelegate) => false;
}

/// The round grey shutter button with a light ring.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Chụp ảnh',
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: _shutterSize,
          height: _shutterSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF8A8A82),
            border: Border.all(color: const Color(0xFFF0EDE6), width: 5),
          ),
        ),
      ),
    );
  }
}
