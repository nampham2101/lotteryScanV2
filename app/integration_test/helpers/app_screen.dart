// What the app's screen shows, as told by camera_app.dart. Only the tests on
// the Mac use this, so it must not import Flutter.

/// One thing on screen: a text, or something that can be tapped, or both.
/// Places are in phone pixels.
class ScreenItem {
  ScreenItem.fromJson(Map<String, dynamic> json)
    : label = json['label'] as String,
      canTap = json['canTap'] as bool,
      left = (json['left'] as num).toDouble(),
      top = (json['top'] as num).toDouble(),
      right = (json['right'] as num).toDouble(),
      bottom = (json['bottom'] as num).toDouble();

  final String label;
  final bool canTap;
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
      items = [
        for (final item in json['items'] as List<dynamic>)
          ScreenItem.fromJson(item as Map<String, dynamic>),
      ];

  final double width;
  final double height;
  final List<ScreenItem> items;

  List<ScreenItem> get tappable => items.where((item) => item.canTap).toList();

  /// What can be tapped, without the dimmed area around a pop-up, which covers
  /// the whole screen and isn't a button.
  List<ScreenItem> get buttons => tappable
      .where((item) => item.width < width || item.height < height)
      .toList();

  bool shows(String text) => items.any((item) => item.label.contains(text));

  /// Whether [text] is on screen on its own, with nothing added to it. Texts
  /// that sit together can reach the tests as one item, one text on each line.
  bool showsExactly(String text) =>
      items.any((item) => item.label.split('\n').contains(text));

  ScreenItem itemWith(String text) =>
      items.firstWhere((item) => item.label.contains(text));
}
