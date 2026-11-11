import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

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
        'scanned, then the screen shows "Chúc mừng! Bạn trúng" and "Giải Đặc '
        'biệt: 2.000.000.000đ"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '267832', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '267832',
          province: 'Bạc Liêu',
          date: '10-11-2026',
        ),
        answer: [wonTitle, 'Giải Đặc biệt: 2.000.000.000đ'],
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed holds Hồ Chí Minh 09/11/2026 (ĐB 921440 · Tám 43), '
        'when ticket 921443 · Hồ Chí Minh · 09-11-2026 is scanned, then the '
        'screen shows both "Giải khuyến khích: 6.000.000đ" and "Giải Tám: '
        '100.000đ"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(
          number: '921443',
          province: 'TP. HỒ CHÍ MINH',
          date: '09-11-2026',
        ),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '921443',
          province: 'TP. Hồ Chí Minh',
          date: '09-11-2026',
        ),
        answer: [wonTitle],
        inAnyOrder: {'Giải khuyến khích: 6.000.000đ', 'Giải Tám: 100.000đ'},
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed above, when ticket 123482 · Bạc Liêu · 10-11-2026 is '
        'scanned, then the screen shows "Giải Tám: 100.000đ", read from '
        '"7: 8078: 82"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123482', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '123482',
          province: 'Bạc Liêu',
          date: '10-11-2026',
        ),
        answer: [wonTitle, 'Giải Tám: 100.000đ'],
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Lost', () {
    test('Given the feed above, when ticket 111111 · Bạc Liêu · 10-11-2026 is '
        'scanned, then the screen shows "Chưa trúng lần này"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '111111', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '111111',
          province: 'Bạc Liêu',
          date: '10-11-2026',
        ),
        answer: [lostText],
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Outside the feed\'s days', () {
    test('Given the feed above, when a ticket dated after the newest draw day '
        'in the feed is scanned (Cần Thơ · 11-11-2026), then the screen shows '
        '"Chưa có kết quả"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123456', province: 'CẦN THƠ', date: '11-11-2026'),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '123456',
          province: 'Cần Thơ',
          date: '11-11-2026',
        ),
        answer: [noResultsYetText],
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed above, when a ticket dated before the oldest draw day '
        'in the feed is scanned (An Giang · 05-11-2026), then the screen shows '
        '"Vé quá cũ, không dò được"', () async {
      await givenSiteServesSavedFeed();

      final tappedAt = await whenTicketScanned(
        ticketText(number: '123456', province: 'AN GIANG', date: '05-11-2026'),
      );

      await expectAnswerShows(
        tappedAt,
        fields: fieldLines(
          number: '123456',
          province: 'An Giang',
          date: '05-11-2026',
        ),
        answer: [tooOldText],
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

  group('Results can\'t be loaded', () {
    final fields = fieldLines(
      number: '267832',
      province: 'Bạc Liêu',
      date: '10-11-2026',
    );
    final text = ticketText(
      number: '267832',
      province: 'BẠC LIÊU',
      date: '10-11-2026',
    );

    test('Given the phone has no internet, when a ticket is scanned, then the '
        'screen shows "Không tải được kết quả, thử lại sau"', () async {
      await givenNoInternet();

      final tappedAt = await whenTicketScanned(text);

      await expectAnswerShows(
        tappedAt,
        fields: fields,
        answer: [couldNotLoadText],
      );
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the site doesn\'t answer within 10 seconds, when a ticket is '
        'scanned, then the screen shows "Không tải được kết quả, thử lại '
        'sau"', () async {
      await givenSiteNeverAnswers();

      final tappedAt = await whenTicketScanned(text);
      final request = await expectFeedFetched();

      await expectCouldNotLoadAboutTenSecondsAfter(request);
      await expectAnswerShows(
        tappedAt,
        fields: fields,
        answer: [couldNotLoadText],
      );
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given the feed can\'t be understood, when a ticket is scanned, then '
        'the screen shows "Không tải được kết quả, thử lại sau"', () async {
      await givenSiteServesNotAFeed();

      final tappedAt = await whenTicketScanned(text);

      await expectAnswerShows(
        tappedAt,
        fields: fields,
        answer: [couldNotLoadText],
      );
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Loading', () {
    test(
      'Given the fields have been read, when the feed is still loading, '
      'then "Đang đọc vé..." stays on screen until the answer shows',
      () async {
        await givenSiteNeverAnswers();
        final tappedAt = await whenTicketScanned(
          ticketText(
            number: '111111',
            province: 'BẠC LIÊU',
            date: '10-11-2026',
          ),
        );
        final request = await expectFeedFetched();

        await expectStillLoadingWhileHeld(request);
        await givenSiteServesSavedFeed();

        await expectAnswerShows(
          tappedAt,
          fields: fieldLines(
            number: '111111',
            province: 'Bạc Liêu',
            date: '10-11-2026',
          ),
          answer: [lostText],
        );
        await expectNoAppErrors();
      },
      timeout: testTimeout,
    );
  });
}
