import 'package:flutter/material.dart';

import 'shared/fading_note.dart';
import 'shared/open_camera.dart';

const _scanButtonBlue = Color(0xFF1A5FA6);
const _scanButtonSize = 230.0;

// The note sits in the bottom quarter, as it does on the camera screen.
const _noteBottom = 0.25;

/// Sketch 1: the title, the line under it and the round "Quét vé" button. When
/// the camera won't start, it shows the pop-up "Cần dùng camera" if access was
/// refused, or the note "Lỗi camera, thử lại" for any other reason, whether
/// "Quét vé" or screen 4d tried to open the camera.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Counts the notes shown. Each one starts from the beginning.
  int _noteCount = 0;

  @override
  void initState() {
    super.initState();
    cameraStartProblem.addListener(_showProblem);
  }

  @override
  void dispose() {
    cameraStartProblem.removeListener(_showProblem);
    super.dispose();
  }

  void _showProblem() {
    final problem = cameraStartProblem.value;
    if (problem == null) return;
    cameraStartProblem.value = null;
    switch (problem) {
      case CameraStartProblem.refused:
        _showRefusedPopUp();
      case CameraStartProblem.failed:
        setState(() => _noteCount++);
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, screen) => SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                const Column(
                  children: [
                    Spacer(flex: 5),
                    _HomeHeading(),
                    Spacer(flex: 4),
                    ScanButton(),
                    Spacer(flex: 6),
                  ],
                ),
                if (_noteCount > 0)
                  Positioned(
                    bottom: screen.maxHeight * _noteBottom,
                    left: 24,
                    right: 24,
                    child: FadingNote(
                      key: ValueKey(_noteCount),
                      text: 'Lỗi camera, thử lại',
                    ),
                  ),
              ],
            ),
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
/// opens the camera screen once access is allowed. If the camera won't start,
/// the home screen says why (see [HomeScreen]).
class ScanButton extends StatefulWidget {
  const ScanButton({super.key});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => openTicketCamera(context),
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
