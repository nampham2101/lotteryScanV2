import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

import 'helpers/answer_screens.dart';
import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/results.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #28, on the Pixel_10 emulator. They run on the
// Mac and talk to the real app started from ticket_text_app.dart, where the
// tests decide what ML Kit's text is and what the results site answers (see
// results_site.dart). Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/results_driver.dart \
//     --target=integration_test/ticket_text_app.dart
//
// Each test starts from the home screen, so they can run one at a time. Don't
// touch the emulator during a run. The "no internet" test puts the emulator in
// airplane mode and takes it out again when it ends.
//
// "The feed above" is the copy of the real feed in helpers/saved_feed.dart,
// saved on 11 November 2026. Its newest draw day is 10/11/2026, with Bạc Liêu
// (ĐB 267832, "7: 8078: 82"), and its oldest is 06/11/2026. Hồ Chí Minh is on
// 09/11 (ĐB 921440, Tám 43) and again on 07/11 with other numbers. Cà Mau is
// on 09/11 but not on 10/11.
//
// Changed by ticket #31: the answers show on the sketched answer screens, not
// below the three lines on the temporary screen. The tests for "Results can't
// be loaded" and "Loading" moved to answer_screens_driver.dart, where ticket
// #31 names the screen they show.

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(() async {
    await holdReads();
    await resetSite();
  });

  group('Won', () {
    test('Given the feed above, when ticket 267832 · Bạc Liêu · 10-11-2026 is '
        'scanned, then 4a shows "Bạn trúng Giải Đặc biệt" and '
        '"2.000.000.000đ"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '267832', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerScreen(
        wonScreen(
          [(name: 'Giải Đặc biệt', amount: '2.000.000.000đ')],
          ticketCard(
            number: '267832',
            province: 'Bạc Liêu',
            date: '10/11/2026',
          ),
        ),
        photo: await keptPhotoSince(tappedAt),
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    // The criterion gives no order for the two prizes, so either is accepted
    // here. Ticket #31's order is tested in answer_screens_driver.dart.
    test('Given the feed holds Hồ Chí Minh 09/11/2026 (ĐB 921440 · Tám 43), '
        'when ticket 921443 · Hồ Chí Minh · 09-11-2026 is scanned, then 4a '
        'shows both "Bạn trúng Giải khuyến khích" with "6.000.000đ" and "Bạn '
        'trúng Giải Tám" with "100.000đ"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(
          number: '921443',
          province: 'TP. HỒ CHÍ MINH',
          date: '09-11-2026',
        ),
      );

      const khuyenKhich = (name: 'Giải khuyến khích', amount: '6.000.000đ');
      const tam = (name: 'Giải Tám', amount: '100.000đ');
      final card = ticketCard(
        number: '921443',
        province: 'TP. Hồ Chí Minh',
        date: '09/11/2026',
      );
      final eitherOrder = [
        wonScreen([khuyenKhich, tam], card),
        wonScreen([tam, khuyenKhich], card),
      ];
      final isShowing = await waitUntil(() async {
        final screen = await appScreen();
        return eitherOrder.any(
          (won) => showsOnly(screen, won.words, won.button),
        );
      });
      expect(
        isShowing,
        isTrue,
        reason:
            '4a with the two prizes did not show: $eitherOrder. On screen: '
            '${shownLines(await appScreen())}',
      );
      await expectNoPhotoAnywhere(await keptPhotoSince(tappedAt));
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed above, when ticket 123482 · Bạc Liêu · 10-11-2026 is '
        'scanned, then 4a shows "Bạn trúng Giải Tám" and "100.000đ", read from '
        '"7: 8078: 82"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123482', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerScreen(
        wonScreen(
          [(name: 'Giải Tám', amount: '100.000đ')],
          ticketCard(
            number: '123482',
            province: 'Bạc Liêu',
            date: '10/11/2026',
          ),
        ),
        photo: await keptPhotoSince(tappedAt),
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Lost', () {
    test('Given the feed above, when ticket 111111 · Bạc Liêu · 10-11-2026 is '
        'scanned, then 4b shows "Chưa trúng lần này"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '111111', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerScreen(
        lostScreen(
          ticketCard(
            number: '111111',
            province: 'Bạc Liêu',
            date: '10/11/2026',
          ),
        ),
        photo: await keptPhotoSince(tappedAt),
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Outside the feed\'s days', () {
    // 11-11-2026 is neither today nor a later day, so ticket #31 doesn't say
    // what 4c's second line reads for it. Only its title, its card and its
    // button are checked.
    test('Given the feed above, when a ticket dated after the newest draw day '
        'in the feed is scanned (Cần Thơ · 11-11-2026), then 4c shows "Chưa '
        'có kết quả"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123456', province: 'CẦN THƠ', date: '11-11-2026'),
      );

      final card = ticketCard(
        number: '123456',
        province: 'Cần Thơ',
        date: '11/11/2026',
      );
      var words = <String>[];
      final isShowing = await waitUntil(() async {
        final screen = await appScreen();
        words = shownLines(screen);
        final fromTitle = wordsFrom(screen, notDrawnTitle);
        return fromTitle != null &&
            fromTitle.startsWith('$notDrawnTitle ') &&
            fromTitle.endsWith(' $card $scanAnotherLabel') &&
            screen.buttons.length == 1;
      });
      expect(
        isShowing,
        isTrue,
        reason:
            '4c did not show "$notDrawnTitle" at the top, then "$card" and '
            'the one button "$scanAnotherLabel" at the bottom. On screen: '
            '$words',
      );
      await expectNoPhotoAnywhere(await keptPhotoSince(tappedAt));
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed above, when a ticket dated before the oldest draw day '
        'in the feed is scanned (An Giang · 05-11-2026), then the "too old" '
        'screen shows "Vé quá cũ"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123456', province: 'AN GIANG', date: '05-11-2026'),
      );

      await expectAnswerScreen(
        tooOldScreen,
        photo: await keptPhotoSince(tappedAt),
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Province not drawn that day', () {
    test('Given the feed above, when a ticket\'s date is in the feed but its '
        'province isn\'t listed that day (Cà Mau · 10-11-2026), then screen 4d '
        'shows, and "Thử lại" opens the camera as it does now', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123456', province: 'CÀ MAU', date: '10-11-2026'),
      );

      await expect4dShows(await keptPhotoSince(tappedAt));
      await expectFeedFetched();

      await tapTryAgain();

      await expectCameraScreenOpensAndStays();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });
}
