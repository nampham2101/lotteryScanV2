import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'shared/ticket_photo.dart';

const _screenBackground = Color(0xFF222222);
const _frameInset = 24.0;
const _shutterSize = 88.0;

/// Sketch 2: the live camera picture inside a dashed frame, with a round
/// shutter button. Closes by itself after the photo is kept, so the home
/// screen shows again.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // No audio: the app only needs pictures, and asking for the
      // microphone too would add a second question.
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException {
      // Refused or broken camera: a later ticket decides what to tell the
      // person. For now, go back to the home screen.
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || _isTakingPhoto) return;
    _isTakingPhoto = true;
    final photo = await controller.takePicture();
    await keepTicketPhoto(photo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Đặt vé vào khung',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(_frameInset),
                child: _CameraFrame(controller: _controller),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _ShutterButton(onPressed: _takePhoto),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed frame, with the live picture filling it.
class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    return CustomPaint(
      foregroundPainter: _DashedFramePainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: controller == null
            ? const SizedBox.expand()
            : SizedBox.expand(
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
