import 'dart:io';

import 'package:flutter/material.dart';

import 'answer_screens.dart';
import 'cant_read_screen.dart';
import 'shared/results_feed.dart';
import 'shared/ticket_answer.dart';
import 'shared/ticket_fields.dart';
import 'shared/ticket_reader.dart';

const _spinnerBlue = Color(0xFF1A5FA6);

/// Sketch 3: shows while the ticket is read and the feed is fetched, then
/// replaces itself with the answer screen, or with 4d when a field is missing,
/// the read fails or the ticket's province isn't listed on its date. The
/// phone's back closes it, which shows the home screen.
class ReadingScreen extends StatefulWidget {
  /// Reads the three fields from the kept [photo], then checks the ticket.
  const ReadingScreen.read({required File this.photo, super.key})
    : fields = null;

  /// Checks the ticket with these [fields] again, with no new photo ("Thử
  /// lại" on "couldn't load").
  const ReadingScreen.check({required TicketFields this.fields, super.key})
    : photo = null;

  final File? photo;
  final TicketFields? fields;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    var fields = widget.fields;
    if (fields == null) {
      try {
        fields = readTicketFields(await readTicketText(widget.photo!));
      } on Object {
        fields = null;
      }
      if (!_isCurrent) return;
      if (fields == null) return _replaceWith(const CantReadScreen());
    }
    final TicketAnswer? answer;
    try {
      answer = answerFor(fields, await fetchResults());
    } on Object {
      if (!_isCurrent) return;
      return _replaceWith(CouldNotLoadScreen(fields: fields));
    }
    if (!_isCurrent) return;
    if (answer == null) return _replaceWith(const CantReadScreen());
    _replaceWith(answerScreenFor(answer, fields));
  }

  // The person may have left. After back, this screen stays mounted while it
  // closes, but it is no longer the current route, and replacing "the top
  // screen" would replace the home screen instead.
  bool get _isCurrent => mounted && ModalRoute.of(context)?.isCurrent == true;

  Future<void> _replaceWith(Widget screen) =>
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: ExcludeSemantics(
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: _spinnerBlue,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Đang đọc vé…',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Chỉ mất vài giây',
                style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
