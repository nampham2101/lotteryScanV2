import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotteryscan/answer_screens.dart';
import 'package:lotteryscan/cant_read_screen.dart';
import 'package:lotteryscan/shared/prize_check.dart';
import 'package:lotteryscan/shared/result_layout.dart';
import 'package:lotteryscan/shared/ticket_answer.dart';
import 'package:lotteryscan/shared/ticket_fields.dart';

import 'helpers/movement_checks.dart';
import 'helpers/screen_watch.dart';

// Widget tests for ticket #32: the movement on 4a and 4b, and none on the
// other answer screens. Each screen is opened on its own, as the app opens it,
// and watched frame by frame with the test's clock, so the timings are exact.
// "Quét vé khác" and back while the movement plays are tested on the
// emulator, in integration_test/answer_movement_driver.dart, and the look of
// the confetti and the wink are manual steps (docs/tests/32.md).

const _wonTitle = 'Chúc mừng!';
const _lostTitle = 'Chưa trúng lần này';

const _onePrizeTicket = TicketFields(
  number: '123482',
  province: 'Bạc Liêu',
  date: '10-11-2026',
);
const _twoPrizeTicket = TicketFields(
  number: '117988',
  province: 'Bình Dương',
  date: '06-11-2026',
);
const _lostTicket = TicketFields(
  number: '111111',
  province: 'Bạc Liêu',
  date: '10-11-2026',
);

final _icon = find.byIcon(Icons.celebration);
const _iconName = 'the party-popper icon';
const _titleName = '"$_wonTitle"';

/// Long enough for every movement to be over.
const _watchTime = Duration(seconds: 6);

/// "While the screen stays open": how long it's watched once still.
const _stillWatch = Duration(seconds: 60);

/// 4a for [prizes], watched from when it opens until well after its movement
/// is over: [_iconName], [_titleName] and each amount measured at every frame.
Future<List<Look>> _watch4a(
  WidgetTester tester,
  TicketFields ticket,
  List<Prize> prizes,
) async {
  await openScreen(tester, answerScreenFor(Won(prizes), ticket));
  return watchScreen(
    tester,
    until: _watchTime,
    items: {
      _iconName: _icon,
      _titleName: find.text(_wonTitle),
      for (final prize in prizes)
        _amountName(prize): find.text(formatMoney(prize.amount)),
    },
  );
}

String _amountName(Prize prize) => '"${formatMoney(prize.amount)}"';

/// The pop-ins of the icon, the title and each amount, in that order.
List<PopIn> _popInsOf(List<Look> looks, List<Prize> prizes) => [
  popInOf(_iconName, looks),
  popInOf(_titleName, looks),
  for (final prize in prizes) popInOf(_amountName(prize), looks),
];

void _expectConfettiOnce(List<Look> looks, List<PopIn> popIns) {
  expectConfettiOnce(
    looks,
    popIns,
    icon: shownRect(_icon)!,
    things: thingsOnScreen(_icon, find.byType(TicketCard)),
  );
}

void main() {
  group('4a, one prize', () {
    const prizes = [Prize('Giải Tám', 100000)];

    testWidgets('Given a ticket that wins one prize, when 4a opens, then the '
        'party-popper icon, "Chúc mừng!" and the amount pop in one after '
        'another, each growing from small with a slight bounce', (
      tester,
    ) async {
      final looks = await _watch4a(tester, _onePrizeTicket, prizes);

      final popIns = _popInsOf(looks, prizes);
      popIns.forEach(expectPopsInWithBounce);
      expectOneAfterAnother(popIns);
    });

    testWidgets('Given a ticket that wins one prize, when 4a opens, then as '
        'they pop in, confetti bursts from the icon and falls down the screen '
        'for about 2 seconds, then the screen stays still', (tester) async {
      final looks = await _watch4a(tester, _onePrizeTicket, prizes);

      _expectConfettiOnce(looks, _popInsOf(looks, prizes));
      expectNothingScheduled(
        tester,
        'the screen was still moving at ${seconds(_watchTime)}',
      );
    });
  });

  group('4a, several prizes', () {
    const prizes = [Prize('Giải Sáu', 400000), Prize('Giải Tám', 100000)];

    testWidgets('Given a ticket that wins several prizes, when 4a opens, then '
        'the icon and "Chúc mừng!" pop in, then each prize\'s amount pops in '
        'one after another, and the confetti plays once as above', (
      tester,
    ) async {
      final looks = await _watch4a(tester, _twoPrizeTicket, prizes);

      final popIns = _popInsOf(looks, prizes);
      popIns.forEach(expectPopsInWithBounce);
      expectOneAfterAnother(popIns);
      _expectConfettiOnce(looks, popIns);
      expectNothingScheduled(
        tester,
        'the screen was still moving at ${seconds(_watchTime)}',
      );
    });
  });

  group('4a, played once', () {
    testWidgets('Given 4a is open, when the movement has finished, then it '
        'doesn\'t play again while the screen stays open', (tester) async {
      final looks = await _watch4a(tester, _onePrizeTicket, const [
        Prize('Giải Tám', 100000),
      ]);
      // Without a movement there's nothing to finish, so this test would
      // pass on a still 4a. It counts only with the other 4a tests passing.
      final popIns = _popInsOf(looks, const [Prize('Giải Tám', 100000)]);
      popIns.forEach(expectPopsInWithBounce);

      await expectStaysAs(
        tester,
        looks.last.picture!,
        from: _watchTime,
        howLong: _stillWatch,
        reason: 'the movement played again',
      );
      expectNothingScheduled(tester, 'the movement is playing again');
    });
  });

  group('4b', () {
    testWidgets('Given a ticket that wins nothing, when 4b opens, then about '
        'half a second later the smiley grows slightly, then the screen stays '
        'still, exactly as it was before it moved', (tester) async {
      await openScreen(tester, answerScreenFor(const Lost(), _lostTicket));
      final title = shownRect(find.text(_lostTitle));
      expect(title, isNotNull, reason: 'SETUP: "$_lostTitle" is not shown');

      final looks = await watchScreen(tester, until: _watchTime);

      final endedAt = expectSmileyGrowsSlightly(looks, title!);
      await expectStaysAs(
        tester,
        looks.first.picture!,
        from: _watchTime,
        howLong: _stillWatch,
        reason:
            'the screen did not stay still after the movement ended at '
            '${seconds(endedAt)}',
      );
      expectNothingScheduled(tester, 'the movement is playing again');
    });
  });

  group('Nothing moves on the other answer screens', () {
    final screens = <String, Widget>{
      '4c': answerScreenFor(
        const NotDrawnYet(drawDay: '13/11/2026', isToday: true),
        const TicketFields(
          number: '123456',
          province: 'Bến Tre',
          date: '13-11-2026',
        ),
      ),
      '"too old"': answerScreenFor(
        const TooOld(),
        const TicketFields(
          number: '123456',
          province: 'An Giang',
          date: '05-11-2026',
        ),
      ),
      '"couldn\'t load"': const CouldNotLoadScreen(fields: _lostTicket),
      '4d': const CantReadScreen(),
    };

    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('Given $name, when the screen opens, then nothing '
          'moves', (tester) async {
        await openScreen(tester, screen);
        final opened = await pictureOfScreen(tester);

        await expectStaysAs(
          tester,
          opened,
          from: Duration.zero,
          howLong: const Duration(seconds: 3),
          step: frame * 3,
          reason: 'something on $name moved',
        );
        await expectStaysAs(
          tester,
          opened,
          from: const Duration(seconds: 3),
          howLong: const Duration(seconds: 7),
          reason: 'something on $name moved',
        );
        expectNothingScheduled(tester, 'something on $name is still moving');
      });
    }
  });
}
