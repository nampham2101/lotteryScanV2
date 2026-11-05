import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Has ML Kit read the photo at [photo]. Returns ML Kit's `text` exactly as it
/// gives it, or an empty string when it found none. A failed read throws.
Future<String> readTicketText(File photo) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(
      InputImage.fromFilePath(photo.path),
    );
    return result.text;
  } finally {
    await recognizer.close();
  }
}
