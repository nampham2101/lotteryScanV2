import 'package:flutter_driver/flutter_driver.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'helpers/answer_screens.dart';
import 'helpers/camera_start.dart';
import 'helpers/driven_app.dart';
import 'helpers/photo_screen.dart';
import 'helpers/results.dart';
import 'helpers/ticket_fields.dart';
import 'helpers/ticket_text.dart';

// Integration tests for ticket #31, on the Pixel_10 emulator. They run on the
// Mac and talk to the real app started from camera_start_app.dart: the tests
// decide what ML Kit's text is and what the results site answers (see
// ticket_text_app.dart and results_site.dart), and can make the camera refuse
// or fail when it next starts. Run them from app/:
//
//   export ANDROID_SERIAL=emulator-5554
//   fvm flutter drive -d "$ANDROID_SERIAL" \
//     --driver=integration_test/answer_screens_driver.dart \
//     --target=integration_test/camera_start_app.dart
//
// Each test starts from the home screen, with the camera able to start, so
// they can run one at a time. Don't touch the emulator during a run. The "no
// internet" test puts the emulator in airplane mode and takes it out again
// when it ends. With ANSWER_SCREENSHOTS set to a folder, the tests also save
// the screenshots the manual steps look at (docs/tests/31.md).
//
// "The saved feed" is helpers/saved_feed.dart, saved on 11 November 2026. Its
// draw days run from 06/11/2026 to 10/11/2026. Bạc Liêu 10/11 has ĐB 267832
// and `7: 8078: 82` (Tám 82). Hồ Chí Minh 09/11 has Sáu 0433 and Tám 43. Cà Mau
// is on 09/11 but not on 10/11.

const _lostText =
    'XỔ SỐ KIẾN THIẾT\nBẠC LIÊU\nLOẠI VÉ 10.000Đ\n10-11-2026\n111111';
final _lostAnswer = lostScreen(
  ticketCard(number: '111111', province: 'Bạc Liêu', date: '10/11/2026'),
);

const _oneTam = (name: 'Giải Tám', amount: '100.000đ');
const _wonText =
    'XỔ SỐ KIẾN THIẾT\nBẠC LIÊU\nLOẠI VÉ 10.000Đ\n10-11-2026\n123482';
final _wonAnswer = wonScreen([
  _oneTam,
], ticketCard(number: '123482', province: 'Bạc Liêu', date: '10/11/2026'));

const _tooOldText =
    'XỔ SỐ KIẾN THIẾT\nAN GIANG\nLOẠI VÉ 10.000Đ\n05-11-2026\n123456';

/// A ticket dated [daysFromToday] days from the phone's today, from a
/// province drawn that weekday, and the 4c it gets from the saved feed, whose
/// newest day is long past.
Future<({String text, AnswerScreen answer})> _notDrawnTicket({
  int daysFromToday = 0,
}) async {
  final today = await phone.today();
  expect(
    today.isAfter(DateTime.utc(2026, 11, 10)),
    isTrue,
    reason: 'SETUP: the phone\'s date, $today, is not after the saved feed',
  );
  final day = today.add(Duration(days: daysFromToday));
  final province = provinceDrawnOn(day);
  final date = ticketDate(day);
  final card = ticketCard(
    number: '123456',
    province: province.shown,
    date: cardDate(date),
  );
  return (
    text: ticketText(number: '123456', province: province.read, date: date),
    answer: notDrawnScreen(
      province.shown,
      card,
      date: daysFromToday == 0 ? null : cardDate(date),
    ),
  );
}

/// When a ticket with ML Kit text [text] is scanned and its answer is ready.
/// Returns the photo kept.
Future<img.Image> _whenScanned(String text) async =>
    keptPhotoSince(await whenTicketScanned(text));

/// Given: [expected] shows for the ticket with ML Kit text [text]. Returns
/// the photo kept.
Future<img.Image> _givenShows(String text, AnswerScreen expected) async {
  final photo = await _whenScanned(text);
  await expectAnswerScreen(expected);
  return photo;
}

Future<void> _given4aShows() => _givenShows(_wonText, _wonAnswer);

Future<void> _given4bShows() => _givenShows(_lostText, _lostAnswer);

Future<void> _given4cShows() async {
  final ticket = await _notDrawnTicket();
  await _givenShows(ticket.text, ticket.answer);
}

Future<void> _givenTooOldShows() => _givenShows(_tooOldText, tooOldScreen);

Future<void> _givenCouldNotLoadShows() async {
  await givenSiteServesNotAFeed();
  await _givenShows(_lostText, couldNotLoadScreen);
}

/// The feed requests the app has made since the test began.
Future<List<Request>> _feedRequests() async =>
    (await requestsSoFar()).where((request) => request.isFeed).toList();

void main() {
  setUpAll(() async {
    driver = await FlutterDriver.connect();
  });

  tearDownAll(() async {
    await driver.close();
  });

  setUp(() async {
    await letCameraStart();
    await holdReads();
    await resetSite();
  });

  group('Reading', () {
    test('Given the camera screen, when the shutter is tapped and the photo is '
        'kept, then sketch 3 shows "Đang đọc vé…" and "Chỉ mất vài giây", '
        'with no photo and no "Số vé / Tỉnh / Ngày" lines, and stays while '
        'the ticket is read', () async {
      await givenSiteNeverAnswers();
      await givenCameraScreenOpen();

      final tappedAt = await tapShutter();

      await expectReadingScreenOpensWithoutHome();
      final photo = await keptPhotoSince(tappedAt);
      await expectNoPhotoAnywhere(photo);
      await saveScreenshotIfAsked('3-reading');
      await expectReadAsked(0);
      await expectReadingScreenStays();
      expect(
        (await readerReport()).reads.single.isFinished,
        isFalse,
        reason: 'SETUP: the read finished by itself',
      );
    }, timeout: testTimeout);

    test('Given sketch 3 shows and the ticket has been read, when the feed is '
        'still loading, then sketch 3 stays, with no "Số vé / Tỉnh / Ngày" '
        'lines, until the answer screen opens', () async {
      await givenSiteNeverAnswers();
      await whenTicketScanned(_lostText);
      final request = await expectFeedFetched();

      await expectReadingStaysWhileHeld(request);
      await givenSiteServesSavedFeed();

      await expectOnlyReadingUntil(_lostAnswer);
      await expectNoAppErrors();
    }, timeout: testTimeout);
  });

  group('Answers', () {
    test('Given a ticket that wins one prize (123482 · Bạc Liêu · '
        '10-11-2026, Giải Tám), when the answer is ready, then 4a shows '
        '"Chúc mừng!", "Bạn trúng Giải Tám", "100.000đ" in large type, the card '
        '"Vé 123482 · Bạc Liêu · 10/11/2026" and "Quét vé khác", and nothing '
        'moves', () async {
      final photo = await _whenScanned(_wonText);

      await expectAnswerScreen(_wonAnswer, photo: photo);
      await expectAmountsInLargeType([_oneTam]);
      await expectNothingMoves();
      await saveScreenshotIfAsked('4a-one-prize');
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket that wins several prizes (110433 · TP. Hồ Chí Minh · '
        '09-11-2026, Giải Sáu and Giải Tám), when the answer is ready, then 4a '
        'shows one block per prize, "Bạn trúng <giải>" with its amount in '
        'large type, from the highest prize down, with no total', () async {
      const prizes = [
        (name: 'Giải Sáu', amount: '400.000đ'),
        (name: 'Giải Tám', amount: '100.000đ'),
      ];

      final photo = await _whenScanned(
        ticketText(
          number: '110433',
          province: 'TP. HỒ CHÍ MINH',
          date: '09-11-2026',
        ),
      );

      await expectAnswerScreen(
        wonScreen(
          prizes,
          ticketCard(
            number: '110433',
            province: 'TP. Hồ Chí Minh',
            date: '09/11/2026',
          ),
        ),
        photo: photo,
      );
      await expectAmountsInLargeType(prizes);
      await saveScreenshotIfAsked('4a-two-prizes');
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket that wins more prizes than fit (123456 · Bạc Liêu · '
        '10-11-2026 against a feed where it wins Giải Nhất to Giải Tám), when '
        'the answer is ready, then the screen scrolls to show every block, '
        'from the highest prize down, with no total, and "Quét vé '
        'khác"', () async {
      const prizes = [
        (name: 'Giải Nhất', amount: '30.000.000đ'),
        (name: 'Giải Nhì', amount: '15.000.000đ'),
        (name: 'Giải Ba', amount: '10.000.000đ'),
        (name: 'Giải Tư', amount: '3.000.000đ'),
        (name: 'Giải Năm', amount: '1.000.000đ'),
        (name: 'Giải Sáu', amount: '400.000đ'),
        (name: 'Giải Bảy', amount: '200.000đ'),
        (name: 'Giải Tám', amount: '100.000đ'),
      ];
      await givenSiteServes(feedWithEightPrizes);

      await _whenScanned(
        ticketText(number: '123456', province: 'BẠC LIÊU', date: '10-11-2026'),
      );

      await saveScreenshotIfAsked('4a-eight-prizes-top');
      await expectEverythingSeenByScrolling(
        wonScreen(
          prizes,
          ticketCard(
            number: '123456',
            province: 'Bạc Liêu',
            date: '10/11/2026',
          ),
        ),
      );
      await saveScreenshotIfAsked('4a-eight-prizes-end');
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket that wins nothing (111111 · Bạc Liêu · 10-11-2026), '
        'when the answer is ready, then 4b shows "Chưa trúng lần này", "Chúc '
        'bạn may mắn lần sau!", the ticket card and "Quét vé khác", and '
        'nothing moves', () async {
      final photo = await _whenScanned(_lostText);

      await expectAnswerScreen(_lostAnswer, photo: photo);
      await expectNothingMoves();
      await saveScreenshotIfAsked('4b');
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket dated today that isn\'t drawn yet, when the answer is '
        'ready, then 4c shows "Chưa có kết quả", "Xổ số <tỉnh> mở thưởng lúc '
        '16:15. Quay lại sau nhé.", the ticket card and "Quét vé khác", with '
        '<tỉnh> as read from the ticket', () async {
      final ticket = await _notDrawnTicket();

      final photo = await _whenScanned(ticket.text);

      await expectAnswerScreen(ticket.answer, photo: photo);
      await saveScreenshotIfAsked('4c-today');
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket dated a later day that isn\'t drawn yet, when the '
        'answer is ready, then 4c shows "…mở thưởng lúc 16:15 ngày '
        '<DD/MM/YYYY>. Quay lại sau nhé."', () async {
      final ticket = await _notDrawnTicket(daysFromToday: 2);

      final photo = await _whenScanned(ticket.text);

      await expectAnswerScreen(ticket.answer, photo: photo);
      await saveScreenshotIfAsked('4c-later-day');
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    test('Given a ticket older than the feed\'s oldest draw day (An Giang · '
        '05-11-2026), when the answer is ready, then the "too old" screen '
        'shows "Vé quá cũ", "Chỉ dò được vé trong 5 kỳ quay gần nhất." and '
        '"Quét vé khác"', () async {
      final photo = await _whenScanned(_tooOldText);

      await expectAnswerScreen(tooOldScreen, photo: photo);
      await saveScreenshotIfAsked('too-old');
      await expectFeedFetched();
      await expectNoAppErrors();
    }, timeout: testTimeout);

    group('Couldn\'t load', () {
      test('Given no internet, when the feed is fetched, then the "couldn\'t '
          'load" screen shows "Không tải được kết quả", "Kiểm tra kết nối mạng '
          'rồi thử lại sau." and "Thử lại"', () async {
        await givenNoInternet();

        final photo = await _whenScanned(_lostText);

        await expectAnswerScreen(couldNotLoadScreen, photo: photo);
        await saveScreenshotIfAsked('couldnt-load');
        await expectNoAppErrors();
      }, timeout: testTimeout);

      test('Given no answer within 10 seconds, when the feed is fetched, then '
          'the "couldn\'t load" screen shows', () async {
        await givenSiteNeverAnswers();
        final tappedAt = await whenTicketScanned(_lostText);
        final request = await expectFeedFetched();

        await expectCouldNotLoadAboutTenSecondsAfter(request);

        await expectAnswerScreen(
          couldNotLoadScreen,
          photo: await keptPhotoSince(tappedAt),
        );
        await expectNoAppErrors();
      }, timeout: testTimeout);

      test('Given a feed the app can\'t understand, when the feed is fetched, '
          'then the "couldn\'t load" screen shows', () async {
        await givenSiteServesNotAFeed();

        final photo = await _whenScanned(_lostText);

        await expectAnswerScreen(couldNotLoadScreen, photo: photo);
        await expectFeedFetched();
        await expectNoAppErrors();
      }, timeout: testTimeout);
    });

    group('4d', () {
      test('Given a failed read, when the answer is ready, then 4d shows, '
          'unchanged from #24', () async {
        final photo = await givenReadingShows();

        await failRead(0);

        await expect4dShows(photo);
        await expectNoAppErrors();
      }, timeout: testTimeout);

      test('Given a missing field (no date), when the answer is ready, then 4d '
          'shows, unchanged from #24', () async {
        final photo = await givenReadingShows();

        await finishRead(0, 'XỔ SỐ KIẾN THIẾT\nBẠC LIÊU\n111111');

        await expect4dShows(photo);
        await expectNoAppErrors();
      }, timeout: testTimeout);

      test('Given a province not drawn on the ticket\'s date (Cà Mau · '
          '10-11-2026), when the answer is ready, then 4d shows, unchanged '
          'from #24', () async {
        final photo = await givenReadingShows();

        await finishRead(
          0,
          ticketText(number: '123456', province: 'CÀ MAU', date: '10-11-2026'),
        );

        await expect4dShows(photo);
        await expectFeedFetched();
        await expectNoAppErrors();
      }, timeout: testTimeout);
    });
  });

  group('Buttons and back', () {
    final screens = <String, Future<void> Function()>{
      '4a': _given4aShows,
      '4b': _given4bShows,
      '4c': _given4cShows,
      '"too old"': _givenTooOldShows,
    };

    for (final MapEntry(key: name, value: givenShows) in screens.entries) {
      test('Given $name, when "Quét vé khác" is tapped, then the camera '
          'opens', () async {
        await givenShows();

        await tapButton(scanAnotherLabel);

        await expectCameraScreenOpensAndStays();
        await expectNoAppErrors();
      }, timeout: testTimeout);
    }

    test('Given "couldn\'t load", when "Thử lại" is tapped, then sketch 3 '
        'shows while the feed is fetched again for the same ticket, with no '
        'new photo, then the matching answer screen shows', () async {
      await _givenCouldNotLoadShows();
      final photosBefore = await phone.photosInsideApp();
      final fetchesBefore = (await _feedRequests()).length;
      await givenSiteNeverAnswers();

      await tapTryAgain();

      await expectReadingScreenOpensWithoutHome();
      var requests = <Request>[];
      await waitUntil(() async {
        requests = await _feedRequests();
        return requests.length > fetchesBefore;
      });
      expect(
        requests.length,
        greaterThan(fetchesBefore),
        reason: 'the feed was not fetched again',
      );
      await expectReadingStaysWhileHeld(requests.last);
      await givenSiteServesSavedFeed();
      await expectOnlyReadingUntil(_lostAnswer);
      expect(
        (await readerReport()).reads,
        hasLength(1),
        reason: 'the photo was read again',
      );
      expect(
        await phone.photosInsideApp(),
        photosBefore,
        reason: 'a new photo was taken',
      );
      expect(
        await phone.isAppUsingCamera(),
        isFalse,
        reason: 'the camera was opened',
      );
      await expectNoAppErrors();
    }, timeout: testTimeout);

    final screensWithBack = <String, Future<void> Function()>{
      ...screens,
      '"couldn\'t load"': _givenCouldNotLoadShows,
    };

    for (final MapEntry(key: name, value: givenShows)
        in screensWithBack.entries) {
      test('Given $name, when the phone\'s back button is pressed, then home '
          'shows', () async {
        await givenShows();

        await phone.pressBackButton();

        await expectHomeScreenShowsAndStays();
        await expectNoAppErrors();
      }, timeout: testTimeout);
    }

    test('Given "Quét vé khác" is tapped (on 4b), when camera access is '
        'refused, then home shows with the "Cần dùng camera" pop-up', () async {
      await _given4bShows();
      await givenCameraAccessRefused();

      await tapButton(scanAnotherLabel);

      await expectHomeWithRefusedPopUp();
    }, timeout: testTimeout);

    test('Given "Quét vé khác" is tapped (on "too old"), when the camera fails '
        'for any other reason, then home shows with the fading note "Lỗi '
        'camera, thử lại"', () async {
      await _givenTooOldShows();
      await givenCameraFailsToStart();

      await tapButton(scanAnotherLabel);

      await expectHomeWithFadingNote(isHomeTheWholeTime: false);
    }, timeout: testTimeout);
  });
}
