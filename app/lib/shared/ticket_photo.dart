import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

const _ticketPhotoName = 'ticket_photo.jpg';
const _stagedName = 'ticket_photo_staged.jpg';

/// Cuts the camera's photo down to what the dashed frame showed, the middle
/// square, and saves it in the app's own private folder under a temporary
/// name, so the photo already kept stays untouched until the app decides to
/// keep this one. The camera's own copy is always removed, also when the cut
/// fails, so no full-size photo is left behind. A failed cut throws.
Future<File> cropAndStageTicketPhoto(XFile photo) async {
  try {
    final folder = await getApplicationDocumentsDirectory();
    final bytes = await File(photo.path).readAsBytes();
    // Decoding a full camera picture is slow, so it runs off the main thread.
    final square = await compute(_cropToMiddleSquare, bytes);
    return await File('${folder.path}/$_stagedName')
        .writeAsBytes(square, flush: true);
  } finally {
    await deleteTicketPhotoFile(photo.path);
  }
}

/// The middle square of the picture, turned upright and saved as a JPEG.
/// Throws when the bytes are not a picture.
Uint8List _cropToMiddleSquare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Not a picture');
  // The camera may note the turn in the file instead of turning the pixels.
  final upright = img.bakeOrientation(decoded);
  final side = math.min(upright.width, upright.height);
  final square = img.copyCrop(
    upright,
    x: (upright.width - side) ~/ 2,
    y: (upright.height - side) ~/ 2,
    width: side,
    height: side,
  );
  return img.encodeJpg(square, quality: 95);
}

/// Makes a staged photo the kept one, replacing the old one in a single step.
/// Always the same name, so only one photo is ever kept. It doesn't wait, so
/// nothing can happen between the caller's last check and the replacement.
/// Returns the kept photo.
File keepStagedTicketPhoto(File staged) {
  return staged.renameSync('${staged.parent.path}/$_ticketPhotoName');
}

/// Removes a photo file, for a photo the person chose to leave without.
Future<void> deleteTicketPhotoFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
