import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'shared/ticket_reader.dart';

const _readingLabel = 'Đang đọc vé...';
const _couldNotReadLabel = 'Không đọc được vé';
const _textStyle = TextStyle(fontSize: 16, color: Colors.white);

/// Temporary screen with no sketch: the newest photo on top, whole, and what
/// ML Kit reads from it below. The phone's back closes it, which shows the
/// home screen.
class PhotoScreen extends StatefulWidget {
  const PhotoScreen({required this.photoBytes, required this.photo, super.key});

  final Uint8List photoBytes;

  /// The kept photo file, which ML Kit reads.
  final File photo;

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  // Null while reading. Empty when nothing was read or the read failed.
  String? _text;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    String text;
    try {
      text = await readTicketText(widget.photo);
    } on Object {
      text = '';
    }
    // The person may have left, or taken a new photo with its own screen.
    if (!mounted) return;
    setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox.expand(
                // Bytes, not the file's name: the photo is always kept under
                // the same name, so an image cached by name would show the old
                // one.
                child: Image.memory(
                  widget.photoBytes,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox.expand(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    text == null
                        ? _readingLabel
                        : text.isEmpty
                        ? _couldNotReadLabel
                        : text,
                    style: _textStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
