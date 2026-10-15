import 'package:dineroo_mobile/shared/common/layout/window_size.dart';
import 'package:flutter/widgets.dart';

abstract final class ContentWidth {
  static const double roleSelection = 420;
  static const double authCard = 480;
}

/// Centers [child] with a maximum width on medium and expanded windows. On compact windows it
/// returns [child] untouched so phones keep their current layout.
class AdaptiveContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const AdaptiveContent({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (context.windowSize == WindowSize.compact) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
