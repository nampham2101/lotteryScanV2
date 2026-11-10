import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'cant_read_screen.dart';
import 'shared/ticket_fields.dart';
import 'shared/ticket_reader.dart';

const _readingLabel = 'Đang đọc vé...';
const _textStyle = TextStyle(fontSize: 16, color: Colors.white);

/// Temporary screen with no sketch: the newest photo on top, whole, and below
/// it the ticket's number, province and date, read from ML Kit's text.
/// When a field is missing or the read fails, it is replaced by screen 4d. The
/// phone's back closes it, which shows the home screen.
class PhotoScreen extends StatefulWidget {
  const PhotoScreen({required this.photoBytes, required this.photo, super.key});

  final Uint8List photoBytes;

  /// The kept photo file, which ML Kit reads.
  final File photo;

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  // Null while reading.
  TicketFields? _fields;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    TicketFields? fields;
    try {
      fields = readTicketFields(await readTicketText(widget.photo));
    } on Object {
      fields = null;
    }
    // The person may have left, or taken a new photo with its own screen.
    if (!mounted) return;
    if (fields == null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CantReadScreen()),
      );
      return;
    }
    setState(() => _fields = fields);
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
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
                    fields == null
                        ? _readingLabel
                        : 'Số vé: ${fields.number}\n'
                              'Tỉnh: ${fields.province}\n'
                              'Ngày: ${fields.date}',
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
