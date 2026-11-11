import 'package:test/test.dart';

import 'answers.dart';
import 'app_screen.dart';
import 'driven_app.dart';
import 'photo_screen.dart';
import 'ticket_fields.dart';
import 'ticket_text.dart';

export 'answers.dart';

// Shared by the tests for ticket #28, which run on the Mac: how they give
// orders to the results site's stand-in in results_site.dart, and what the
// answer below the three fields must be.

/// The feed the ticket names.
final feedAddress = Uri.parse('https://xskt.com.vn/rss-feed/mien-nam-xsmn.rss');

/// A page that answers in place of the feed but isn't one: what a site under
/// maintenance sends.
const notAFeed =
    '<!DOCTYPE html><html><head><title>Bảo trì</title></head><body>'
    '<p>Trang đang bảo trì, vui lòng quay lại sau.</p></body></html>';

/// Words that only show once the answer is there.
const _answerWords = [...answerFirstLines, 'Giải ', couldNotReadText];

/// How long the app waits for the site before giving up, as the ticket says,
/// and how far off the tests let it be. Watching takes a moment between
/// looks, so the upper end leaves room for that.
const _earliestGiveUp = Duration(seconds: 9);
const _latestGiveUp = Duration(milliseconds: 12500);

/// How long the "still loading" test watches, and the longest it lets a
/// request wait, so the app's own 10 seconds never run out while it watches.
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

bool _isAnswer(
  List<String> shown,
  List<String> fields,
  List<String> answer,
  Set<String> inAnyOrder,
) {
  final firstLines = [...fields, ...answer];
  if (shown.length != firstLines.length + inAnyOrder.length) return false;
  for (var i = 0; i < firstLines.length; i++) {
    if (shown[i] != firstLines[i]) return false;
  }
  final rest = shown.sublist(firstLines.length);
  return rest.toSet().length == rest.length &&
      rest.toSet().containsAll(inAnyOrder);
}

/// Then: the temporary screen shows the photo taken at [tappedAt] with the
/// three [fields] lines below it, then the [answer] lines below them, then the
/// [inAnyOrder] lines in any order, top to bottom, and nothing else written.
Future<void> expectAnswerShows(
  double tappedAt, {
  required List<String> fields,
  required List<String> answer,
  Set<String> inAnyOrder = const {},
}) async {
  var shown = <String>[];
  final isShowing = await waitUntil(() async {
    shown = shownLines(await appScreen());
    return _isAnswer(shown, fields, answer, inAnyOrder);
  });
  expect(
    isShowing,
    isTrue,
    reason:
        'the words on screen, top to bottom, must be $fields, then $answer'
        '${inAnyOrder.isEmpty ? '' : ', then $inAnyOrder in any order'}, '
        'and nothing else. On screen: $shown',
  );
  await expectScreenShows(await keptPhotoSince(tappedAt));
}

bool _showsAnAnswer(AppScreen screen) => _answerWords.any(
  (words) => screen.texts.any((t) => t.label.contains(words)),
);

/// Then: while the site is holding [request], "Đang đọc vé..." stays on screen
/// and no answer shows. Watches for a few seconds, and stops before the
/// request has waited long enough for the app to give up on it.
Future<void> expectStillLoadingWhileHeld(Request request) async {
  final stopAt = DateTime.now().add(_loadingWatch);
  final lastSafeLook = request.askedAt.add(_longestHold);
  var looks = 0;
  do {
    final screen = await appScreen();
    looks++;
    expect(
      shownLines(screen),
      contains(readingText),
      reason:
          '"$readingText" did not stay while the feed was loading. On screen: '
          '${shownLines(screen)}',
    );
    expect(
      _showsAnAnswer(screen),
      isFalse,
      reason:
          'an answer showed while the feed was still loading. On screen: '
          '${shownLines(screen)}',
    );
    await Future<void>.delayed(_watchStep);
  } while (DateTime.now().isBefore(stopAt) &&
      DateTime.now().isBefore(lastSafeLook));
  expect(looks, greaterThan(1), reason: 'SETUP: no time left to watch');
}

/// Then: "Không tải được kết quả, thử lại sau" shows about 10 seconds after
/// [request], which the site never answered: not before 9 seconds, and by 12.5.
Future<void> expectCouldNotLoadAboutTenSecondsAfter(Request request) async {
  Duration waited() => DateTime.now().difference(request.askedAt);
  while (waited() <= _latestGiveUp) {
    if ((await appScreen()).shows(couldNotLoadText)) {
      expect(
        waited(),
        greaterThanOrEqualTo(_earliestGiveUp),
        reason:
            '"$couldNotLoadText" showed ${waited().inMilliseconds} ms after '
            'the request, before the site had 10 seconds to answer',
      );
      return;
    }
    await Future<void>.delayed(_watchStep);
  }
  fail(
    '"$couldNotLoadText" did not show within ${_latestGiveUp.inMilliseconds} '
    'ms of a request the site never answered. On screen: '
    '${shownLines(await appScreen())}',
  );
}
