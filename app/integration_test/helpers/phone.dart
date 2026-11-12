import 'dart:io';

// The Pixel_10 emulator, driven from the Mac with adb, for the tests of tickets
// #5, #8, #9 and #10. Turning it sets its accelerometer, which is what a real
// turn changes, so Android decides by itself whether the screen turns.

const appPackage = 'com.nampham.lotteryscan';

const _cameraPermission = 'android.permission.CAMERA';
const _allowInSettingsButton = 'allow_foreground_only_radio_button';

// The emulator's touch screen reads every place on this scale, not in pixels.
const _touchScale = 32767;
const _endOfTouch = 'EV_SYN:0:0';

/// Flutter ignores a second tap that lands under 40 ms after the first, and
/// treats a gap over 300 ms as two separate taps.
const _doubleTapGap = Duration(milliseconds: 80);

/// What Android remembers about this app and the camera.
enum CameraAccess { neverAsked, allowed, refused }

/// A photo inside the app's private folders.
typedef KeptPhoto = ({String path, int modifiedAt, int bytes});

/// Android's question to the person, with the buttons that allow and refuse.
typedef PermissionQuestion = ({
  String message,
  int allowX,
  int allowY,
  int refuseX,
  int refuseY,
});

/// What the phone's screen shows, pixel by pixel.
class ScreenPixels {
  ScreenPixels(this._bytes)
    : width = _readHeader(_bytes, 0),
      height = _readHeader(_bytes, 4);

  static const _headerBytes = 16;
  static const _bytesPerPixel = 4;

  final List<int> _bytes;
  final int width;
  final int height;

  static int _readHeader(List<int> bytes, int offset) =>
      bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;

  int _pixelStart(int x, int y) =>
      _headerBytes + (y * width + x) * _bytesPerPixel;

  /// From 0 (black) to 255 (white).
  int brightness(int x, int y) {
    final start = _pixelStart(x, y);
    return (_bytes[start] + _bytes[start + 1] + _bytes[start + 2]) ~/ 3;
  }

  /// How many sampled pixels differ from [other]. The top and bottom tenths
  /// are left out: the clock in the status bar changes by itself.
  int changedPixels(ScreenPixels other) {
    const step = 10;
    const smallestChange = 12;
    var changed = 0;
    for (var y = height ~/ 10; y < height * 9 ~/ 10; y += step) {
      for (var x = 0; x < width; x += step) {
        final difference = brightness(x, y) - other.brightness(x, y);
        if (difference.abs() >= smallestChange) changed++;
      }
    }
    return changed;
  }
}

/// How the phone is held. `acceleration` is what the accelerometer reads
/// (x:y:z in m/s²): gravity pulls along the phone's long side when upright,
/// and along its short side when sideways.
enum Hold {
  upright('upright', 0, 9.81),
  sidewaysLeft('sideways to the left', 9.81, 0),
  sidewaysRight('sideways to the right', -9.81, 0);

  const Hold(this.label, this.x, this.y);

  final String label;
  final double x;
  final double y;

  String get acceleration => '$x:$y:0';
}

class Phone {
  Phone._(this._adb, this._serial);

  /// The emulator in `ANDROID_SERIAL`, or `emulator-5554` (Pixel_10).
  factory Phone.fromEnvironment() {
    final env = Platform.environment;
    final sdk = env['ANDROID_HOME'] ?? env['ANDROID_SDK_ROOT'];
    final sdkAdb = sdk == null ? null : '$sdk/platform-tools/adb';
    final adb = sdkAdb != null && File(sdkAdb).existsSync() ? sdkAdb : 'adb';
    return Phone._(adb, env['ANDROID_SERIAL'] ?? 'emulator-5554');
  }

  final String _adb;
  final String _serial;

  /// How many quarter turns the emulator's camera is from where it started.
  var _quarterTurns = 0;

  Future<String> _run(List<String> args) async {
    final result = await Process.run(_adb, ['-s', _serial, ...args]);
    if (result.exitCode != 0) {
      throw StateError(
        'adb ${args.join(' ')} failed (${result.exitCode}): '
        '${result.stderr}${result.stdout}',
      );
    }
    return result.stdout as String;
  }

  Future<String> _shell(String command) => _run(['shell', command]);

  /// Turns the emulator's camera a quarter turn, so it sees another view of its
  /// room. Sensors alone don't move that picture. An app locked upright stays
  /// upright. Android needs a moment to catch up with the new picture.
  Future<void> turnCamera() async {
    await _run(['emu', 'rotate']);
    _quarterTurns = (_quarterTurns + 1) % 4;
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  /// Undoes [turnCamera], so the next test finds the room upright again.
  Future<void> turnCameraBack() async {
    while (_quarterTurns != 0) {
      await turnCamera();
    }
  }

  /// Turns the phone, then waits long enough for Android to turn the screen
  /// if it is going to.
  Future<void> hold(Hold hold) async {
    final answer = await _run([
      'emu',
      'sensor',
      'set',
      'acceleration',
      hold.acceleration,
    ]);
    if (!answer.contains('OK')) {
      throw StateError('the emulator did not take the turn: $answer');
    }
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  /// What the accelerometer reads now, as [x, y].
  Future<List<double>> accelerometer() async {
    final answer = await _run(['emu', 'sensor', 'get', 'acceleration']);
    final match = RegExp(r'acceleration = (\S+):(\S+):').firstMatch(answer);
    if (match == null) {
      throw StateError('cannot read the accelerometer: $answer');
    }
    return [double.parse(match[1]!), double.parse(match[2]!)];
  }

  Future<bool> isAutoRotateOn() async =>
      (await _shell('settings get system accelerometer_rotation')).trim() ==
      '1';

  Future<void> setAutoRotate({required bool isOn}) =>
      _shell('settings put system accelerometer_rotation ${isOn ? 1 : 0}');

  /// How far the screen is turned from upright, in degrees: 0, 90, 180, 270.
  Future<int> screenRotation() async {
    final dump = await _shell('dumpsys window displays');
    final match = RegExp(
      r'^\s*mRotation=(\d)\s',
      multiLine: true,
    ).firstMatch(dump);
    if (match == null) throw StateError('cannot read the screen rotation');
    return int.parse(match[1]!) * 90;
  }

  /// The window in front, e.g. `com.nampham.lotteryscan/...MainActivity`.
  Future<String> windowInFront() async {
    final dump = await _shell('dumpsys window displays');
    final match = RegExp(r'mCurrentFocus=(.*)').firstMatch(dump);
    return match?[1]?.trim() ?? 'nothing';
  }

  Future<bool> isAppInFront() async =>
      (await windowInFront()).contains('$appPackage/');

  /// The phone's clock, in seconds, to ask what happened after this moment.
  Future<double> clock() async => double.parse((await _shell('date +%s.%N')));

  /// Today's date on the phone's own calendar, in its own time zone, at
  /// midnight UTC so that days add up without time-zone surprises.
  Future<DateTime> today() async {
    final parts = (await _shell('date +%Y-%m-%d')).trim().split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Turns airplane mode on or off, which cuts or brings back the phone's
  /// internet. The tests keep talking to the phone over adb either way.
  Future<void> setAirplaneMode({required bool isOn}) =>
      _shell('cmd connectivity airplane-mode ${isOn ? 'enable' : 'disable'}');

  /// Whether Android has a network to send the app's requests through.
  Future<bool> hasNetwork() async {
    final dump = await _shell('dumpsys connectivity');
    final active = RegExp(r'Active default network: (\S+)').firstMatch(dump);
    return active != null && active[1] != 'none';
  }

  /// When the screen turned since [since]: Android logs a configuration
  /// change with the orientation flag each time the screen turns.
  Future<List<double>> screenTurnsSince(double since) async {
    const orientationFlag = 0x80;
    final log = await _run(['logcat', '-b', 'events', '-d', '-v', 'epoch']);
    final change = RegExp(r'^\s*(\d+\.\d+).*configuration_changed: (\d+)');
    return [
      for (final line in log.split('\n'))
        if (change.firstMatch(line) case final match?)
          if (double.parse(match[1]!) >= since &&
              int.parse(match[2]!) & orientationFlag != 0)
            double.parse(match[1]!),
    ];
  }

  /// Closes the app completely, as if swiped away and stopped.
  Future<void> closeApp() async {
    await _shell('am force-stop $appPackage');
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<bool> isAppRunning() async {
    final result = await Process.run(_adb, [
      '-s',
      _serial,
      'shell',
      'pidof $appPackage',
    ]);
    return (result.stdout as String).trim().isNotEmpty;
  }

  /// Opens the app the way tapping its icon does: the launcher's intent.
  /// Then waits for it to settle, so a late turn is caught too.
  Future<void> openApp() async {
    final activity = (await _shell(
      'cmd package resolve-activity --brief '
      '-c android.intent.category.LAUNCHER $appPackage',
    )).trim().split('\n').last.trim();
    await _shell(
      'am start -W -a android.intent.action.MAIN '
      '-c android.intent.category.LAUNCHER -n $activity',
    );
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  /// A finger tap at [x], [y], in phone pixels.
  Future<void> tap(int x, int y) => _shell('input tap $x $y');

  Future<void> pressBackButton() => _shell('input keyevent KEYCODE_BACK');

  /// The back gesture: a finger swiping in from the left edge of the screen.
  Future<void> swipeBack({
    required int screenWidth,
    required int screenHeight,
  }) => _shell(
    'input swipe 0 ${screenHeight ~/ 2} '
    '${screenWidth * 6 ~/ 10} ${screenHeight ~/ 2} 300',
  );

  /// One finger swiping up the screen at [x], in phone pixels. A longer
  /// [milliseconds] is a slower swipe, which glides on less after the finger
  /// lifts.
  Future<void> swipeUp({
    required int x,
    required int fromY,
    required int toY,
    int milliseconds = 300,
  }) => _shell('input swipe $x $fromY $x $toY $milliseconds');

  /// Real fingers on the emulator's touch screen, through the same path a
  /// person's fingers take. `adb shell input` can't do this: it has one finger.
  Future<void> _touch(List<String> events) =>
      _run(['emu', 'event', 'send', ...events, _endOfTouch]);

  int _touchPlace(num place, num screenSize) =>
      place * _touchScale ~/ screenSize;

  List<String> _fingerAt(
    int finger, {
    required int x,
    required int y,
    required int screenWidth,
    required int screenHeight,
  }) => [
    'EV_ABS:ABS_MT_SLOT:$finger',
    'EV_ABS:ABS_MT_POSITION_X:${_touchPlace(x, screenWidth)}',
    'EV_ABS:ABS_MT_POSITION_Y:${_touchPlace(y, screenHeight)}',
  ];

  List<String> _fingerDown(int finger) => [
    'EV_ABS:ABS_MT_SLOT:$finger',
    'EV_ABS:ABS_MT_TRACKING_ID:${finger + 1}',
    'EV_ABS:ABS_MT_PRESSURE:100',
  ];

  List<String> _fingerUp(int finger) => [
    'EV_ABS:ABS_MT_SLOT:$finger',
    'EV_ABS:ABS_MT_TRACKING_ID:-1',
  ];

  /// Two fingers in the middle of the screen that slide apart, or together if
  /// [isSpreading] is false. [whileHeld] runs before the fingers lift, for
  /// looking at the screen in the middle of the pinch.
  Future<void> pinch({
    required int screenWidth,
    required int screenHeight,
    required bool isSpreading,
    required Future<void> Function() whileHeld,
  }) async {
    const steps = 12;
    final middleY = screenHeight ~/ 2;
    final near = screenHeight ~/ 12;
    final far = screenHeight ~/ 3;
    final x = screenWidth ~/ 2;

    Future<void> placeFingers(int distance, {bool isLanding = false}) =>
        _touch([
          if (isLanding) ..._fingerDown(0),
          ..._fingerAt(
            0,
            x: x,
            y: middleY - distance,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
          if (isLanding) ..._fingerDown(1),
          ..._fingerAt(
            1,
            x: x,
            y: middleY + distance,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        ]);

    final start = isSpreading ? near : far;
    final end = isSpreading ? far : near;
    await placeFingers(start, isLanding: true);
    for (var step = 1; step <= steps; step++) {
      await placeFingers(start + (end - start) * step ~/ steps);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    try {
      await whileHeld();
    } finally {
      // A finger left down would spoil every test after this one.
      await _touch([..._fingerUp(0), ..._fingerUp(1)]);
    }
  }

  /// Two quick taps with one finger, at [x], [y], in phone pixels.
  Future<void> doubleTap({
    required int x,
    required int y,
    required int screenWidth,
    required int screenHeight,
  }) async {
    for (var tap = 0; tap < 2; tap++) {
      await _touch([
        ..._fingerDown(0),
        ..._fingerAt(
          0,
          x: x,
          y: y,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ]);
      await _touch(_fingerUp(0));
      if (tap == 0) await Future<void>.delayed(_doubleTapGap);
    }
  }

  /// Whether the phone uses gestures, not buttons, to go back.
  Future<bool> usesBackGesture() async {
    const gestureNavigation = '2';
    return (await _shell('settings get secure navigation_mode')).trim() ==
        gestureNavigation;
  }

  Future<CameraAccess> cameraAccess() async {
    final dump = await _shell('dumpsys package $appPackage');
    final match = RegExp('$_cameraPermission: granted=(\\w+), flags=\\[(.*)\\]')
        .firstMatch(dump);
    if (match == null) return CameraAccess.neverAsked;
    if (match[1] == 'true') return CameraAccess.allowed;
    final flags = match[2]!;
    final hasPersonAnswered =
        flags.contains('USER_SET') || flags.contains('USER_FIXED');
    return hasPersonAnswered ? CameraAccess.refused : CameraAccess.neverAsked;
  }

  /// Whether Android will never ask again: only the phone's Settings can
  /// change the answer now.
  Future<bool> isCameraRefusedForGood() async {
    final dump = await _shell('dumpsys package $appPackage');
    final match = RegExp('$_cameraPermission: granted=false, flags=\\[(.*)\\]')
        .firstMatch(dump);
    return match != null && match[1]!.contains('USER_FIXED');
  }

  /// Allows the camera the way a person does in the phone's Settings: App
  /// info, Permissions, Camera, then "Allow only while using the app". Then
  /// goes back to the app with the back button. Reads the English Settings.
  Future<void> allowCameraInSettings() async {
    await _shell(
      'am start -a android.settings.APPLICATION_DETAILS_SETTINGS '
      '-d package:$appPackage',
    );
    await _tapOnScreen('text="Permissions"');
    await _tapOnScreen('text="Camera"');
    await _tapOnScreen('resource-id="[^"]*:id/$_allowInSettingsButton"');
    await Future<void>.delayed(const Duration(seconds: 1));
    for (var tries = 0; tries < 5 && !await isAppInFront(); tries++) {
      await pressBackButton();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
  }

  /// Waits for what [attribute] describes to be on screen, then taps it.
  Future<void> _tapOnScreen(String attribute) async {
    final item = RegExp('<node [^>]*$attribute[^>]*>');
    for (var tries = 0; tries < 20; tries++) {
      final window = await _run([
        'exec-out',
        'uiautomator',
        'dump',
        '/dev/tty',
      ]);
      if (item.firstMatch(window)?[0] case final found?) {
        final (x, y) = _middleOf(found);
        await tap(x, y);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('not on screen: $attribute. In: ${await windowInFront()}');
  }

  /// Allows the camera in Android's settings, so no question is needed.
  /// Android says nothing if the app doesn't request the camera at all, so
  /// check [cameraAccess] afterwards.
  Future<void> allowCameraAccess() =>
      _shell('pm grant $appPackage $_cameraPermission');

  Future<bool> isAndroidAskingForPermission() async =>
      (await windowInFront()).contains('GrantPermissionsActivity');

  /// Android's question on screen now, or null if there is none.
  Future<PermissionQuestion?> permissionQuestion() async {
    final window = await _run(['exec-out', 'uiautomator', 'dump', '/dev/tty']);
    final message = _screenItem(window, 'permission_message');
    final allowButton = _screenItem(
      window,
      'permission_allow_foreground_only_button',
    );
    // The second time Android asks, its refuse button is a different one.
    final refuseButton =
        _screenItem(window, 'permission_deny_button') ??
        _screenItem(window, 'permission_deny_and_dont_ask_again_button');
    if (message == null || allowButton == null || refuseButton == null) {
      return null;
    }

    final text = RegExp(r' text="([^"]*)"').firstMatch(message)![1]!;
    final (allowX, allowY) = _middleOf(allowButton);
    final (refuseX, refuseY) = _middleOf(refuseButton);
    return (
      message: text,
      allowX: allowX,
      allowY: allowY,
      refuseX: refuseX,
      refuseY: refuseY,
    );
  }

  /// The middle of one thing on screen in a uiautomator dump.
  (int, int) _middleOf(String item) {
    final bounds = RegExp(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
        .firstMatch(item)!;
    final [left, top, right, bottom] = [
      for (final group in [1, 2, 3, 4]) int.parse(bounds[group]!),
    ];
    return ((left + right) ~/ 2, (top + bottom) ~/ 2);
  }

  /// The description of one thing on screen in a uiautomator dump.
  String? _screenItem(String window, String id) =>
      RegExp('<node [^>]*resource-id="[^"]*:id/$id"[^>]*>')
          .firstMatch(window)?[0];

  /// Every photo in the app's private folders, whatever its name or folder.
  /// Files are recognised by their content, not by their name. `code_cache`
  /// holds the app's own code, never a photo.
  Future<List<KeptPhoto>> photosInsideApp() async {
    final lines = await _shell(
      'run-as $appPackage sh -c \''
      'find . -type f ! -path "./code_cache/*" | while read -r f; do '
      'case "\$(file -b "\$f")" in '
      '*JPEG*|*PNG*|*WebP*|*HEIF*|*HEIC*) stat -c "%Y %s %n" "\$f";; '
      'esac; done\'',
    );
    return [
      for (final line in lines.trim().split('\n'))
        if (RegExp(r'^(\d+) (\d+) (.+)$').firstMatch(line.trim())
            case final match?)
          (
            path: match[3]!,
            modifiedAt: int.parse(match[1]!),
            bytes: int.parse(match[2]!),
          ),
    ]..sort((a, b) => a.path.compareTo(b.path));
  }

  /// The contents of a file inside the app, by the path [photosInsideApp] gave.
  Future<List<int>> fileInsideApp(String path) async {
    final result = await Process.run(_adb, [
      '-s',
      _serial,
      'exec-out',
      'run-as',
      appPackage,
      'cat',
      path,
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError('cannot read $path: ${result.stderr}');
    }
    return result.stdout as List<int>;
  }

  /// Everything the phone's gallery can show: what Android has listed in its
  /// picture index, and any picture file in shared storage it hasn't listed
  /// yet. `Android/` holds apps' own folders, which the gallery doesn't show.
  Future<List<String>> galleryPhotos() async {
    final listed = await _shell(
      'content query --uri content://media/external/images/media '
      '--projection _id:_display_name:_data',
    );
    final files = await _shell(
      "find /sdcard/ -type f -not -path '/sdcard/Android/*' \\( "
      "-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o "
      "-iname '*.webp' -o -iname '*.heic' \\)",
    );
    return [
      for (final line in '$listed\n$files'.split('\n'))
        if (line.trim().isNotEmpty && line.trim() != 'No result found.')
          line.trim(),
    ]..sort();
  }

  /// Whether Android reports this app as the one using a camera right now.
  Future<bool> isAppUsingCamera() async =>
      (await _shell('dumpsys media.camera'))
          .contains('Client Package Name: $appPackage');

  Future<ScreenPixels> screenshot() async {
    final result = await Process.run(_adb, [
      '-s',
      _serial,
      'exec-out',
      'screencap',
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError('screencap failed: ${result.stderr}');
    }
    return ScreenPixels(result.stdout as List<int>);
  }

  /// Saves what the screen shows now as a PNG file at [path], on the Mac.
  Future<void> saveScreenshot(String path) async {
    final result = await Process.run(_adb, [
      '-s',
      _serial,
      'exec-out',
      'screencap',
      '-p',
    ], stdoutEncoding: null);
    if (result.exitCode != 0) {
      throw StateError('screencap failed: ${result.stderr}');
    }
    await File(path).writeAsBytes(result.stdout as List<int>);
  }
}
