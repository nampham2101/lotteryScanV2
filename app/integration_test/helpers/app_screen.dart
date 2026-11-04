// What the app's screen shows, as told by camera_app.dart. Only the tests on
// the Mac use this, so it must not import Flutter.

/// One thing on screen: a text, or something that can be tapped, or both.
/// Places are in phone pixels.
class ScreenItem {
  ScreenItem.fromJson(Map<String, dynamic> json)
    : label = json['label'] as String,
      canTap = json['canTap'] as bool,
      isImage = json['isImage'] as bool,
      left = (json['left'] as num).toDouble(),
      top = (json['top'] as num).toDouble(),
      right = (json['right'] as num).toDouble(),
      bottom = (json['bottom'] as num).toDouble();

  final String label;
  final bool canTap;

  /// A picture with a description for screen readers. That description is
  /// never drawn, so it isn't text on screen.
  final bool isImage;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  @override
  String toString() =>
      '"$label" at ($left, $top)-($right, $bottom)'
      '${canTap ? ', can be tapped' : ''}';
}

class AppScreen {
  AppScreen.fromJson(Map<String, dynamic> json)
    : width = (json['width'] as num).toDouble(),
      height = (json['height'] as num).toDouble(),
      barsTop = (json['barsTop'] as num).toDouble(),
      barsBottom = (json['barsBottom'] as num).toDouble(),
      touches = json['touches'] as int,
      twoFingerTouches = json['twoFingerTouches'] as int,
      items = [
        for (final item in json['items'] as List<dynamic>)
          ScreenItem.fromJson(item as Map<String, dynamic>),
      ];

  final double width;
  final double height;

  /// How much of the top and the bottom the phone's own bars cover.
  final double barsTop;
  final double barsBottom;

  /// Fingers that have reached the app since it started, and how many of them
  /// landed while another finger was down.
  final int touches;
  final int twoFingerTouches;
  final List<ScreenItem> items;

  List<ScreenItem> get tappable => items.where((item) => item.canTap).toList();

  /// What can be tapped, without the dimmed area around a pop-up, which covers
  /// the whole screen and isn't a button.
  List<ScreenItem> get buttons => tappable
      .where((item) => item.width < width || item.height < height)
      .toList();

  /// Words drawn on screen.
  List<ScreenItem> get texts =>
      items.where((item) => item.label.isNotEmpty && !item.isImage).toList();

  bool shows(String text) => items.any((item) => item.label.contains(text));

  /// Whether [text] is on screen on its own, with nothing added to it. Texts
  /// that sit together can reach the tests as one item, one text on each line.
  bool showsExactly(String text) =>
      items.any((item) => item.label.split('\n').contains(text));

  ScreenItem itemWith(String text) =>
      items.firstWhere((item) => item.label.contains(text));
}
