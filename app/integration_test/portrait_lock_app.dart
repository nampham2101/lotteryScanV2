import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:lotteryscan/main.dart' as app;

// The real app for ticket #5's tests, started the way the phone starts it.
// The tests in portrait_lock_driver.dart run on the Mac and turn the emulator,
// so they ask the app what its screen shows through this answer.

void main() {
  enableFlutterDriverExtension(handler: (_) async => jsonEncode(_screenNow()));
  app.main();
}

/// The size the app is drawn at, in phone pixels, and every text with where
/// it sits, so a test can tell a tall screen from a wide one and spot any
/// change.
Map<String, Object> _screenNow() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return {
    'width': view.physicalSize.width,
    'height': view.physicalSize.height,
    'texts': _textsOnScreen(),
  };
}

List<String> _textsOnScreen() {
  final texts = <String>[];
  void visit(Element element) {
    final paragraph = element.renderObject;
    if (element.widget is RichText &&
        paragraph is RenderParagraph &&
        paragraph.hasSize) {
      final rect = paragraph.localToGlobal(Offset.zero) & paragraph.size;
      texts.add('"${paragraph.text.toPlainText()}" at $rect');
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return texts;
}
