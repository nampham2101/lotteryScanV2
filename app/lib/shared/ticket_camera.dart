import 'package:camera/camera.dart';

/// Starts the back camera. This is where Android asks for camera access the
/// first time. Returns null when access is refused or the camera can't start,
/// so the caller can stay where it is.
Future<CameraController?> startTicketCamera() async {
  CameraController? controller;
  try {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    // No audio: the app only takes pictures, and asking for the microphone
    // too would add a second question.
    controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    return controller;
  } on CameraException {
    await controller?.dispose();
    return null;
  }
}
