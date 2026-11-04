import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

const _ticketPhotoName = 'ticket_photo.jpg';
const _stagedName = 'ticket_photo_staged.jpg';

/// Moves the camera's photo into the app's own private folder, under a
/// temporary name, so the photo already kept stays untouched until the app
/// decides to keep this one.
Future<File> stageTicketPhoto(XFile photo) async {
  final folder = await getApplicationDocumentsDirectory();
  final staged = await File(photo.path).copy('${folder.path}/$_stagedName');
  // The camera leaves its own copy in the cache folder: remove it so no
  // second photo is left behind.
  await File(photo.path).delete();
  return staged;
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
