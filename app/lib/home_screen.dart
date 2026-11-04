import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_screen.dart';
import 'shared/ticket_camera.dart';

const _scanButtonBlue = Color(0xFF1A5FA6);
const _scanButtonSize = 230.0;

/// Sketch 1: the title, the line under it and the round "Quét vé" button.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 5),
              const _HomeHeading(),
              const Spacer(flex: 4),
              const ScanButton(),
              const Spacer(flex: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Dò vé số',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Chụp vé để biết trúng hay không',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }
}

/// The large round blue button. It asks for camera access when needed and
/// opens the camera screen once access is allowed. If access is refused, it
/// shows a pop-up that says where to allow the camera.
class ScanButton extends StatefulWidget {
  const ScanButton({super.key});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  bool _isOpening = false;

  Future<void> _openCamera() async {
    if (_isOpening) return;
    _isOpening = true;
    final CameraController? started;
    try {
      started = await startTicketCamera();
    } on CameraAccessRefusedException {
      _isOpening = false;
      if (mounted) await _showRefusedPopUp();
      return;
    }
    _isOpening = false;
    if (started == null) return;
    final controller = started;
    if (!mounted) {
      await controller.dispose();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraScreen(controller: controller),
      ),
    );
  }

  Future<void> _showRefusedPopUp() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cần dùng camera'),
        content: const Text(
          'Ứng dụng cần camera để chụp vé. Bạn hãy cho phép dùng camera '
          'trong phần Cài đặt của điện thoại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _openCamera,
      style: FilledButton.styleFrom(
        backgroundColor: _scanButtonBlue,
        foregroundColor: Colors.white,
        fixedSize: const Size.square(_scanButtonSize),
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_camera_outlined, size: 56),
          SizedBox(height: 8),
          Text(
            'Quét vé',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
