import 'package:flutter/material.dart';
import 'app_loader.dart';

enum IconPosition { start, end }

class AppButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final IconPosition iconPosition;
  final bool outlined;
  final bool isLoading;
  final bool isDisabled;
  final Widget? customChild;
  final double borderRadius;
  final double horizontalTextPadding;
  final Color backgroundColor;
  final Color textColor;
  final FontWeight fontWeight;
  final bool isSmall;

  const AppButton({
    super.key,
    this.text,
    this.onPressed,
    this.icon,
    this.iconPosition = IconPosition.end,
    this.outlined = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.customChild,
    this.borderRadius = 12,
    this.horizontalTextPadding = 6.0,
    this.backgroundColor = Colors.deepOrange,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.bold,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null && customChild == null) {
      throw ArgumentError('AppButton requires either a text or a customChild');
    }

    final bool disabled = isDisabled || isLoading;
    Color disabledBgColor = backgroundColor.withValues(alpha: 0.5);
    Color disabledTextColor = textColor.withValues(alpha: 0.7);

    final Widget buttonChild =
        isLoading
            ? AppLoader(
              size: isSmall ? 14 : 20,
              color:
                  outlined
                      ? (disabled ? Colors.grey : backgroundColor)
                      : textColor,
            )
            : customChild ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null && iconPosition == IconPosition.start) ...[
                      icon!,
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalTextPadding,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text!,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 16,
                              fontWeight: fontWeight,
                              color:
                                  outlined
                                      ? (disabled
                                          ? Colors.grey
                                          : backgroundColor)
                                      : (disabled
                                          ? disabledTextColor
                                          : textColor),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (icon != null && iconPosition == IconPosition.end) ...[
                      const SizedBox(width: 6),
                      icon!,
                    ],
                  ],
                );

    final baseStyle = ButtonStyle(
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(vertical: isSmall ? 10 : 16),
      ),
    );

    final buttonStyle =
        outlined
            ? baseStyle.copyWith(
              side: WidgetStateProperty.all(
                BorderSide(color: disabled ? Colors.grey : backgroundColor),
              ),
              foregroundColor: WidgetStateProperty.all(
                disabled ? Colors.grey : backgroundColor,
              ),
            )
            : baseStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(
                disabled ? disabledBgColor : backgroundColor,
              ),
            );

    return SizedBox(
      width: double.infinity,
      child:
          outlined
              ? OutlinedButton(
                onPressed: disabled ? null : onPressed,
                style: buttonStyle,
                child: buttonChild,
              )
              : ElevatedButton(
                onPressed: disabled ? null : onPressed,
                style: buttonStyle,
                child: buttonChild,
              ),
    );
  }
}
