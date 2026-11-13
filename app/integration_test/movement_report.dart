import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// Part of the real app the tests drive (camera_start_app.dart), for the tests
// of ticket #32 on the Mac. A screenshot of the emulator takes about 2
// seconds, too slow to watch a movement of about 2 seconds, so the app says
// itself whether anything on screen is moving: whether an animation will draw
// another frame. That's also what Flutter Driver waits on before it taps.
//
// "back" does what the phone's back button does inside the app, at once. A
// back press through adb takes long enough for a short movement to be over.

void reportMovement() {
  developer.registerExtension('ext.lotteryscan.movement', _obey);
}

bool get _isMoving => SchedulerBinding.instance.transientCallbackCount > 0;

Future<developer.ServiceExtensionResponse> _obey(
  String method,
  Map<String, String> order,
) async {
  final wasMoving = _isMoving;
  if (order['do'] == 'back') {
    await WidgetsBinding.instance.handlePopRoute();
  }
  return developer.ServiceExtensionResponse.result(
    jsonEncode({'isMoving': wasMoving}),
  );
}
