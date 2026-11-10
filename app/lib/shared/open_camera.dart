import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera_screen.dart';
import 'ticket_camera.dart';

/// Why the camera did not start. The home screen shows it to the person.
enum CameraStartProblem {
  /// Camera access is refused: the home screen shows a pop-up.
  refused,

  /// The camera failed to start for another reason: the home screen shows a
  /// short note.
  failed,
}

/// Set when the camera did not start. The home screen listens, shows the
/// problem and clears it.
final cameraStartProblem = ValueNotifier<CameraStartProblem?>(null);

bool _isOpening = false;

/// Starts the camera and opens the camera screen on top of the current one, or
/// in its place when [replaceScreen] is true (screen 4d).
///
/// If the camera won't start, the current screen stays when it is the home
/// screen. Any other screen is closed so the home screen shows. Either way
/// the home screen then shows the problem through [cameraStartProblem].
Future<void> openTicketCamera(
  BuildContext context, {
  bool replaceScreen = false,
}) async {
  if (_isOpening) return;
  _isOpening = true;
  try {
    CameraController? started;
    CameraStartProblem? problem;
    try {
      started = await startTicketCamera();
      if (started == null) problem = CameraStartProblem.failed;
    } on CameraAccessRefusedException {
      problem = CameraStartProblem.refused;
    }
    // The screen is gone, so there is no one to open the camera for or to tell.
    // A screen that is closing is still mounted but no longer current, and
    // replacing or closing "the top screen" would hit the home screen.
    if (!context.mounted ||
        (replaceScreen && ModalRoute.of(context)?.isCurrent != true)) {
      await started?.dispose();
      return;
    }
    if (problem != null) {
      // Any screen but the home screen closes, so the home screen shows.
      if (replaceScreen) Navigator.of(context).pop();
      cameraStartProblem.value = problem;
      return;
    }
    final controller = started!;
    final route = MaterialPageRoute<void>(
      builder: (_) => CameraScreen(controller: controller),
    );
    final navigator = Navigator.of(context);
    // Not awaited: this runs until the camera screen closes, and a second
    // tap must work once the person is back.
    unawaited(
      replaceScreen ? navigator.pushReplacement(route) : navigator.push(route),
    );
  } finally {
    _isOpening = false;
  }
}
