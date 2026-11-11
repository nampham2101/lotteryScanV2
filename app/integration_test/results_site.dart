import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'helpers/saved_feed.dart';

// A stand-in for the results site, inside the test app, since ticket #28.
// ticket_text_app.dart turns it on, so every test started from it, or from an
// app built on it, gets the same answers from the "site" whatever the time and
// whatever the real site shows. The tests decide what it answers:
//
// - serve: the site answers at once. Unless a test says otherwise, it answers
//   with the saved copy of the feed in helpers/saved_feed.dart, so tests that
//   aren't about the results always get the same answer.
// - hold: the site takes the request and doesn't answer until a test says so.
// - real: the request goes out to the real internet. The "no internet" test
//   uses this with the phone in airplane mode, so the app meets a real missing
//   connection.
//
// Every connection the app's HTTP client opens is handed to a small web server
// inside the test app, whatever address the app asked for, so no test reaches
// the real site by accident. This works for any way of fetching that goes
// through Dart's own HttpClient (dart:io), as the `http` and `dio` add-ons do
// by default. The one limit: the app must fetch that way. A test that expects a
// fetch and finds none here fails and says so, so a fetch that went around it
// can't pass by reaching the real site.

enum _Mode { serve, hold, real }

const _feedType = 'text/xml;charset=UTF-8';

var _mode = _Mode.serve;
var _body = savedFeed;
var _contentType = _feedType;

/// Each address the app asked for since the test began, and when.
final _asked = <(String, DateTime)>[];

/// Requests the site has taken and not answered.
final _held = <HttpRequest>[];

/// Started the first time the app connects.
final Future<HttpServer> _site = _startSite();

/// Hands the app's connections to the stand-in, and takes the tests' orders
/// through a service extension. Call it after the app has started, so nothing
/// the start does can replace it.
void standInForResultsSite() {
  HttpOverrides.global = _ToTheTestSite();
  developer.registerExtension('ext.lotteryscan.feed', _obey);
}

class _ToTheTestSite extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..connectionFactory = _connect;
}

/// Where a connection goes. A plain connection to the test site is used as it
/// is, even for an https address, because it comes from here.
Future<ConnectionTask<Socket>> _connect(
  Uri address,
  String? proxyHost,
  int? proxyPort,
) async {
  _asked.add((address.toString(), DateTime.now()));
  if (_mode == _Mode.real) {
    return address.isScheme('https')
        ? SecureSocket.startConnect(address.host, address.port)
        : Socket.startConnect(address.host, address.port);
  }
  final site = await _site;
  return Socket.startConnect(InternetAddress.loopbackIPv4, site.port);
}

Future<HttpServer> _startSite() async {
  final site = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  site.listen(_answer);
  return site;
}

void _answer(HttpRequest request) {
  if (_mode == _Mode.serve) {
    _serve(request);
  } else {
    _held.add(request);
  }
}

void _serve(HttpRequest request) {
  request.response
    // A new connection for every request, so each one is counted above.
    ..persistentConnection = false
    ..statusCode = HttpStatus.ok
    ..headers.set(HttpHeaders.contentTypeHeader, _contentType)
    ..add(utf8.encode(_body));
  unawaited(request.response.close());
}

Future<void> _dropHeld() async {
  for (final request in _held) {
    final socket = await request.response.detachSocket(writeHeaders: false);
    socket.destroy();
  }
  _held.clear();
}

void _serveHeld() {
  for (final request in _held) {
    _serve(request);
  }
  _held.clear();
}

Future<developer.ServiceExtensionResponse> _obey(
  String method,
  Map<String, String> order,
) async {
  switch (order['do']) {
    case 'start':
      await _dropHeld();
      _asked.clear();
      _mode = _Mode.serve;
      _body = savedFeed;
      _contentType = _feedType;
    case 'serve':
      _mode = _Mode.serve;
      _body = order['body'] ?? savedFeed;
      _contentType = order['contentType'] ?? _feedType;
      _serveHeld();
    case 'hold':
      _mode = _Mode.hold;
    case 'real':
      _mode = _Mode.real;
  }
  final now = DateTime.now();
  return developer.ServiceExtensionResponse.result(
    jsonEncode({
      'asked': [
        for (final (address, at) in _asked)
          {'address': address, 'msAgo': now.difference(at).inMilliseconds},
      ],
      'held': _held.length,
    }),
  );
}
