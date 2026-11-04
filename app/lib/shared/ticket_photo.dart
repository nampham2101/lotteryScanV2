import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

const _ticketPhotoName = 'ticket_photo.jpg';

/// Keeps the camera's photo inside the app, in the app's own private folder.
/// The photo always gets the same name, so a new photo replaces the old one
/// and only one is ever kept.
Future<File> keepTicketPhoto(XFile photo) async {
  final folder = await getApplicationDocumentsDirectory();
  final kept = await File(photo.path).copy('${folder.path}/$_ticketPhotoName');
  // The camera leaves its own copy in the cache folder: remove it so the
  // only photo left is the kept one.
  await File(photo.path).delete();
  return kept;
}

/// Removes a photo file, for a photo the person chose to leave without.
Future<void> deleteTicketPhotoFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
