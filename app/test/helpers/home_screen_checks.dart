import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Shared by the widget tests and the integration tests for ticket #4, so the
// two never drift apart on what the home screen must show.

const homeTitle = 'Dò vé số';
const homeSubtitle = 'Chụp vé để biết trúng hay không';
const scanButtonLabel = 'Quét vé';

/// The three texts from sketch 1 are on screen, spelled with every accent.
void expectHomeScreenTexts() {
  expect(find.text(homeTitle), findsOneWidget, reason: 'title "$homeTitle"');
  expect(
    find.text(homeSubtitle),
    findsOneWidget,
    reason: 'line "$homeSubtitle"',
  );
  expect(
    find.text(scanButtonLabel),
    findsOneWidget,
    reason: 'button label "$scanButtonLabel"',
  );
}

/// Every text on screen fits: no line dropped, no word wider than its box,
/// nothing past the edge of the screen.
void expectNoTextCutOff(WidgetTester tester) {
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final paragraphs = find
      .byType(RichText)
      .evaluate()
      .map((element) => element.renderObject! as RenderParagraph);

  for (final paragraph in paragraphs) {
    final text = paragraph.text.toPlainText();
    final box = paragraph.size;
    const slack = 0.5;

    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '"$text" has more lines than it is allowed to show',
    );
    expect(
      paragraph.getMinIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(box.width + slack),
      reason: 'a word of "$text" is wider than its box',
    );
    if (!paragraph.softWrap) {
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(box.width + slack),
        reason: '"$text" is on one line and wider than its box',
      );
    }
    expect(
      paragraph.getMaxIntrinsicHeight(box.width),
      lessThanOrEqualTo(box.height + slack),
      reason: '"$text" needs more height than its box has',
    );

    final rect = paragraph.localToGlobal(Offset.zero) & box;
    expect(
      rect.left >= -slack &&
          rect.top >= -slack &&
          rect.right <= screen.width + slack &&
          rect.bottom <= screen.height + slack,
      isTrue,
      reason: '"$text" at $rect goes past the screen edge $screen',
    );
  }
}

/// What is on screen right now, to compare before and after a tap.
List<String> visibleTexts() => find
    .byType(RichText)
    .evaluate()
    .map(
      (element) =>
          (element.renderObject! as RenderParagraph).text.toPlainText(),
    )
    .toList();

/// Still on the home screen: same texts, no new page, popup or error.
void expectStillOnHomeScreen(WidgetTester tester, List<String> textsBefore) {
  expectHomeScreenTexts();
  expect(visibleTexts(), textsBefore, reason: 'the screen changed');
  expect(
    Navigator.of(tester.element(find.text(homeTitle))).canPop(),
    isFalse,
    reason: 'a new page was opened on top of the home screen',
  );
  expect(find.byType(SnackBar), findsNothing, reason: 'a message appeared');
  expect(find.byType(Dialog), findsNothing, reason: 'a popup appeared');
  expect(find.byType(BottomSheet), findsNothing, reason: 'a sheet appeared');
  expect(tester.takeException(), isNull, reason: 'the app threw an error');
}
