import 'dart:io';

// The Pixel_10 emulator, driven from the Mac with adb, for ticket #5's tests.
// Turning it sets its accelerometer, which is what a real turn changes, so
// Android decides by itself whether the screen turns.

const appPackage = 'com.nampham.lotteryscan';

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
}
