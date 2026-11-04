import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Temporary screen with no sketch: only the newest photo, fitted whole on a
/// black background. No text, no buttons and no zooming. The phone's back
/// closes it, which shows the home screen.
class PhotoScreen extends StatelessWidget {
  const PhotoScreen({required this.photoBytes, super.key});

  final Uint8List photoBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        // Bytes, not the file's name: the photo is always kept under the same
        // name, so an image cached by name would show the old one.
        child: Image.memory(
          photoBytes,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
