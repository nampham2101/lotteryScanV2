import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:lotteryscan/main.dart' as app;

// The real app for the tests of tickets #8 and #9, started the way the phone
// starts it. Those tests (camera_driver.dart, camera_refused_driver.dart and
// camera_refused_once_driver.dart) run on the Mac, so they ask the app what its
// screen shows through this answer.
//
// The answer comes from the accessibility tree, the app's own list of what a
// person can see and tap. A screen hidden behind another one isn't in it, and
// it doesn't depend on how a screen is built, so the tests stay free to accept
// any way of building the camera screen.

SemanticsHandle? _accessibility;

void main() {
  enableFlutterDriverExtension(handler: (_) async => jsonEncode(_screenNow()));
  _accessibility = SemanticsBinding.instance.ensureSemantics();
  app.main();
}

/// The size the app is drawn at, in phone pixels, and every text and tappable
/// thing on screen with where it sits.
Map<String, Object?> _screenNow() {
  assert(_accessibility != null);
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return {
    'width': view.physicalSize.width,
    'height': view.physicalSize.height,
    'items': _itemsOnScreen(),
  };
}

List<Map<String, Object>> _itemsOnScreen() {
  final items = <Map<String, Object>>[];

  void visit(SemanticsNode node, Matrix4 toScreen) {
    if (node.isMergedIntoParent) return;
    final transform = node.transform;
    final nodeToScreen = transform == null
        ? toScreen
        : toScreen.multiplied(transform);
    final data = node.getSemanticsData();
    final canTap = data.hasAction(SemanticsAction.tap);
    if (data.label.isNotEmpty || canTap) {
      final rect = MatrixUtils.transformRect(nodeToScreen, node.rect);
      items.add({
        'label': data.label,
        'canTap': canTap,
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      });
    }
    node.visitChildren((child) {
      visit(child, nodeToScreen);
      return true;
    });
  }

  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner
      ?.semanticsOwner
      ?.rootSemanticsNode;
  if (root != null) visit(root, Matrix4.identity());
  return items;
}
