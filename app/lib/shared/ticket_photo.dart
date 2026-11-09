import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'square_crop.dart';

const _ticketPhotoName = 'ticket_photo.jpg';
const _stagedName = 'ticket_photo_staged.jpg';
const _writingName = 'ticket_photo_writing.tmp';

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
    final square = await compute(cropToMiddleSquare, bytes);
    return await _saveWhole(square, folder);
  } finally {
    await deleteTicketPhotoFile(photo.path);
  }
}

/// Writes under a working name and renames only when the write is whole, so a
/// failed save (storage full, say) leaves no half photo behind.
Future<File> _saveWhole(Uint8List square, Directory folder) async {
  final writing = File('${folder.path}/$_writingName');
  try {
    await writing.writeAsBytes(square, flush: true);
    return await writing.rename('${folder.path}/$_stagedName');
  } on Object {
    await deleteTicketPhotoFile(writing.path);
    rethrow;
  }
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
