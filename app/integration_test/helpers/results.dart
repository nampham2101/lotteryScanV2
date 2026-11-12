import 'package:test/test.dart';

import 'answers.dart';
import 'driven_app.dart';
import 'photo_screen.dart';
import 'saved_feed.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

export 'answers.dart';

// Shared by the tests for tickets #28 and #31, which run on the Mac: how they
// give orders to the results site's stand-in in results_site.dart, and the
// feeds it can answer with. What the answer screens must show is in
// answer_screens.dart.

/// The feed the ticket names.
final feedAddress = Uri.parse('https://xskt.com.vn/rss-feed/mien-nam-xsmn.rss');

/// A page that answers in place of the feed but isn't one: what a site under
/// maintenance sends.
const notAFeed =
    '<!DOCTYPE html><html><head><title>Bảo trì</title></head><body>'
    '<p>Trang đang bảo trì, vui lòng quay lại sau.</p></body></html>';

/// How long the app waits for the site before giving up, as the ticket says,
/// and how far off the tests let it be. Watching takes a moment between
/// looks, so the upper end leaves room for that.
const _earliestGiveUp = Duration(seconds: 9);
const _latestGiveUp = Duration(milliseconds: 12500);

/// How long the tests watch sketch 3 while the feed loads, and the longest
/// they let a request wait, so the app's own 10 seconds never run out while
/// they watch.
const _loadingWatch = Duration(seconds: 3);
const _longestHold = Duration(seconds: 8);

const _watchStep = Duration(milliseconds: 200);

/// One time the app opened a connection to fetch something.
class Request {
  Request.fromJson(Map<String, dynamic> json)
    : address = Uri.parse(json['address'] as String),
      askedAt = DateTime.now().subtract(
        Duration(milliseconds: json['msAgo'] as int),
      );

  final Uri address;

  /// By the Mac's clock. The time the order took to come back makes this a
  /// little early, never late.
  final DateTime askedAt;

  bool get isFeed =>
      address.scheme == feedAddress.scheme &&
      address.host == feedAddress.host &&
      address.path == feedAddress.path;

  @override
  String toString() => '$address';
}

Future<List<Request>> _orderSite(Map<String, String> order) async {
  final response = await driver.serviceClient.callServiceExtension(
    'ext.lotteryscan.feed',
    isolateId: driver.appIsolate.id,
    args: order,
  );
  return [
    for (final request in response.json!['asked'] as List<dynamic>)
      Request.fromJson(request as Map<String, dynamic>),
  ];
}

Future<List<Request>> requestsSoFar() => _orderSite({'do': 'report'});

/// From now on, the site answers at once with the saved copy of the feed.
/// Requests still held from earlier are dropped and forgotten.
Future<void> resetSite() => _orderSite({'do': 'start'});

/// Given: the site answers with the saved copy of the feed, "the feed above",
/// including any request it's holding.
Future<void> givenSiteServesSavedFeed() => _orderSite({'do': 'serve'});

/// Given: the site answers with [feed], including any request it's holding.
Future<void> givenSiteServes(String feed) =>
    _orderSite({'do': 'serve', 'body': feed});

/// Given: the site answers with a page that isn't the feed.
Future<void> givenSiteServesNotAFeed() => _orderSite({
  'do': 'serve',
  'body': notAFeed,
  'contentType': 'text/html; charset=UTF-8',
});

/// Given: the site takes requests and never answers.
Future<void> givenSiteNeverAnswers() => _orderSite({'do': 'hold'});

/// Given: the app's requests go out to the real internet, so a phone with no
/// internet really fails them.
Future<void> givenRequestsGoToRealInternet() => _orderSite({'do': 'real'});

/// Given: the phone has no internet. Brings it back when the test ends.
Future<void> givenNoInternet() async {
  addTearDown(() async {
    await phone.setAirplaneMode(isOn: false);
    await waitUntil(phone.hasNetwork, timeout: const Duration(seconds: 30));
  });
  await phone.setAirplaneMode(isOn: true);
  expect(
    await waitUntil(() async => !await phone.hasNetwork()),
    isTrue,
    reason: 'SETUP: the phone still has a network in airplane mode',
  );
  await givenRequestsGoToRealInternet();
}

/// What ML Kit reads on a ticket with these fields, as #24's rule finds them.
String ticketText({
  required String number,
  required String province,
  required String date,
}) => 'XỔ SỐ KIẾN THIẾT\n$province\nLOẠI VÉ 10.000Đ\n$date\n$number';

/// When a ticket is scanned: the photo is taken, and ML Kit's read of it
/// finishes with [text] at once, so the three fields are read. Returns when
/// the shutter was tapped, by the phone's clock, to find the photo later. The
/// photo isn't checked here, so the watching that follows starts straight
/// away, even if the app began fetching at the shutter.
Future<double> whenTicketScanned(String text) async {
  await givenCameraScreenOpen();
  final tappedAt = await tapShutter();
  await expectReadAsked(0);
  await finishRead(0, text);
  return tappedAt;
}

/// Then: the app fetched the feed the ticket names, through the site's
/// stand-in. Returns the first time it did.
Future<Request> expectFeedFetched() async {
  var requests = <Request>[];
  await waitUntil(() async {
    requests = await requestsSoFar();
    return requests.any((request) => request.isFeed);
  });
  expect(
    requests.where((request) => request.isFeed),
    isNotEmpty,
    reason:
        'the app did not fetch $feedAddress through Dart\'s HttpClient. It '
        'asked for: $requests',
  );
  return requests.firstWhere((request) => request.isFeed);
}

/// Then: while the site is holding [request], sketch 3 stays on screen, with
/// only its own words: no answer, no field lines and no 4d. Watches for a few
/// seconds, and stops before the request has waited long enough for the app
/// to give up on it.
Future<void> expectReadingStaysWhileHeld(Request request) async {
  final stopAt = DateTime.now().add(_loadingWatch);
  final lastSafeLook = request.askedAt.add(_longestHold);
  var looks = 0;
  do {
    final screen = await appScreen();
    looks++;
    expect(
      isReadingScreen(screen),
      isTrue,
      reason:
          'sketch 3 did not stay while the feed was loading. On screen: '
          '${shownLines(screen)}',
    );
    await Future<void>.delayed(_watchStep);
  } while (DateTime.now().isBefore(stopAt) &&
      DateTime.now().isBefore(lastSafeLook));
  expect(looks, greaterThan(1), reason: 'SETUP: no time left to watch');
}

/// Then: "Không tải được kết quả" shows about 10 seconds after [request], which
/// the site never answered: not before 9 seconds, and by 12.5.
Future<void> expectCouldNotLoadAboutTenSecondsAfter(Request request) async {
  Duration waited() => DateTime.now().difference(request.askedAt);
  while (waited() <= _latestGiveUp) {
    if ((await appScreen()).shows(couldNotLoadTitle)) {
      expect(
        waited(),
        greaterThanOrEqualTo(_earliestGiveUp),
        reason:
            '"$couldNotLoadTitle" showed ${waited().inMilliseconds} ms after '
            'the request, before the site had 10 seconds to answer',
      );
      return;
    }
    await Future<void>.delayed(_watchStep);
  }
  fail(
    '"$couldNotLoadTitle" did not show within ${_latestGiveUp.inMilliseconds} '
    'ms of a request the site never answered. On screen: '
    '${shownLines(await appScreen())}',
  );
}

/// The saved feed with its year changed from 2026 to 2015, everywhere a year
/// is written: each day's link and date, and the feed's own dates. 2015 has
/// the same calendar as 2026, so every weekday stays right. Every ticket in
/// the tests is dated after its newest day, 10/11/2015, so it isn't drawn yet,
/// and 4c shows its ticket card.
final feedFrom2015 = savedFeed
    .replaceAllMapped(
      RegExp(r'(/ngay-\d{1,2}-\d{1,2}-)2026<'),
      (match) => '${match[1]}2015<',
    )
    .replaceAll('/2026</pubDate>', '/2015</pubDate>')
    .replaceAll(' Nov 2026 ', ' Nov 2015 ');

/// The saved feed with Bạc Liêu's numbers on 10/11/2026 changed so that
/// ticket 123456 wins eight prizes, one of each from Giải Nhất to Giải Tám:
/// 23456 is Nhất, Nhì, one of Ba and one of Tư, 3456 is Năm and one of Sáu,
/// and `7: 4568: 56` is Bảy 456 and Tám 56. Đặc biệt stays 267832, so no may
/// mắn or khuyến khích. Nothing else in the feed changes.
final feedWithEightPrizes = savedFeed.replaceFirst(
  RegExp(r'\[Bạc Liêu\][^\[]*'),
  '[Bạc Liêu]     \n'
  'ĐB: 267832\n'
  '1: 23456\n'
  '2: 23456\n'
  '3: 23456 - 17545\n'
  '4: 23456 - 33034 - 16748 - 10888 - 86497 - 16510 - 41069\n'
  '5: 3456\n'
  '6: 3456 - 5373 - 9768\n'
  '7: 4568: 56\n',
);
