import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_screen.dart';
import 'shared/ticket_camera.dart';

const _titleColor = Color(0xFF222222);
const _hintColor = Color(0xFF555555);
const _alertRed = Color(0xFFB3261E);
const _buttonBlue = Color(0xFF1A5FA6);

/// Sketch 4d: the ticket could not be read. "Thử lại" and the phone's back
/// both replace this screen with the camera screen, so back from there shows
/// the home screen.
class CantReadScreen extends StatefulWidget {
  const CantReadScreen({super.key});

  @override
  State<CantReadScreen> createState() => _CantReadScreenState();
}

class _CantReadScreenState extends State<CantReadScreen> {
  bool _isOpening = false;

  Future<void> _openCamera() async {
    if (_isOpening) return;
    _isOpening = true;
    final CameraController? started;
    try {
      started = await startTicketCamera();
    } on CameraAccessRefusedException {
      _isOpening = false;
      return;
    }
    if (started == null) {
      _isOpening = false;
      return;
    }
    final controller = started;
    if (!mounted) {
      await controller.dispose();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CameraScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openCamera();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.error_outline,
                      size: 56,
                      color: _alertRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không đọc được vé',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chụp lại ở nơi đủ sáng, giữ vé phẳng và rõ nét.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: _hintColor),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _openCamera,
                    style: FilledButton.styleFrom(
                      backgroundColor: _buttonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
