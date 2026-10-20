import 'package:flutter/material.dart';

/// Reports when the attached scroll view approaches its end, so the list can
/// trigger the next page load before the user reaches the bottom.
class PrismScrollTrigger {
  /// Creates a trigger that fires when fewer than [thresholdExtent] logical
  /// pixels remain below the viewport.
  PrismScrollTrigger({this.thresholdExtent = 400});

  /// Distance from the end at which [onNearEnd] fires.
  final double thresholdExtent;

  /// Invoked when the scroll view is near its end. Guard against duplicate
  /// triggers (e.g. a loading flag) in your callback.
  void Function()? onNearEnd;

  ScrollController? _controller;

  /// Attach to the scroll view's controller.
  void attach(ScrollController controller) {
    _controller = controller;
    controller.addListener(check);
  }

  /// Detach from the current controller.
  void detach() {
    _controller?.removeListener(check);
    _controller = null;
  }

  /// Runs the near-end check. Called automatically by the attached
  /// controller's listener; may also be invoked manually after programmatic
  /// scrolls.
  void check() {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) return;
    if (position.maxScrollExtent - position.pixels <= thresholdExtent) {
      onNearEnd?.call();
    }
  }
}
