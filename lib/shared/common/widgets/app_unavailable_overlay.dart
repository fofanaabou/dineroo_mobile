import 'package:flutter/material.dart';

class AppUnavailableOverlay extends StatelessWidget {
  final String label;
  final double? fontSize;
  final Alignment badgeAlignment;
  final EdgeInsetsGeometry badgeMargin;
  final EdgeInsetsGeometry badgePadding;
  final bool showBadge;

  const AppUnavailableOverlay({
    super.key,
    this.label = 'INDISPONIBLE',
    this.fontSize,
    this.badgeAlignment = Alignment.topRight,
    this.badgeMargin = const EdgeInsets.only(top: 10, right: 10),
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha(80),
        child: showBadge
            ? Align(
                alignment: badgeAlignment,
                child: Container(
                  margin: badgeMargin,
                  padding: badgePadding,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A7A), Color(0xFFFF4D4D)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize ?? 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
