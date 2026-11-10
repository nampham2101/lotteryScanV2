import 'dart:async';

import 'package:flutter/material.dart';

const _noteShownFor = Duration(seconds: 3);
const _noteFade = Duration(milliseconds: 600);

/// A short grey note with white words, such as the one after a failed crop.
/// It fades in, stays a few seconds, then fades out and leaves the tree.
/// A new note gets a new key, so it starts over.
class FadingNote extends StatefulWidget {
  const FadingNote({required this.text, super.key});

  final String text;

  @override
  State<FadingNote> createState() => _FadingNoteState();
}

class _FadingNoteState extends State<FadingNote> {
  bool _isVisible = false;
  bool _isGone = false;
  Timer? _fadeOutTimer;

  @override
  void initState() {
    super.initState();
    // One frame later, so the fade in has something to start from.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isVisible = true);
      _fadeOutTimer = Timer(_noteShownFor, () {
        if (mounted) setState(() => _isVisible = false);
      });
    });
  }

  @override
  void dispose() {
    _fadeOutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGone) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: _isVisible ? 1 : 0,
      duration: _noteFade,
      onEnd: () {
        if (!_isVisible) setState(() => _isGone = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF444444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
