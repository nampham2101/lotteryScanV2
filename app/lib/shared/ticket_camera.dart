import 'package:camera/camera.dart';

/// Thrown when the person has refused camera access, once or for good.
class CameraAccessRefusedException implements Exception {
  const CameraAccessRefusedException();
}

// Error codes of the camera plugin for a refusal. The second one is what
// Android gives when it won't ask again.
const _refusedCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
};

/// Starts the back camera. This is where Android asks for camera access the
/// first time. Returns null when the camera can't start, and throws
/// [CameraAccessRefusedException] when access is refused, so the caller can
/// tell the person.
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
  } on CameraException catch (error) {
    await controller?.dispose();
    if (_refusedCodes.contains(error.code)) {
      throw const CameraAccessRefusedException();
    }
    return null;
  }
}
