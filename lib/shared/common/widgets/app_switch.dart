import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onDisabledTap;
  final Color activeColor;
  final Color activeTrackColor;
  final Color inactiveThumbColor;
  final Color inactiveTrackColor;
  final Color loaderColor;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
    this.isDisabled = false,
    this.onDisabledTap,
    this.activeColor = Colors.white,
    this.activeTrackColor = Colors.green,
    this.inactiveThumbColor = Colors.grey,
    this.inactiveTrackColor = const Color(0xFFE0E0E0),
    this.loaderColor = Colors.deepOrange,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 52,
        height: 32,
        child: Center(child: AppLoader(size: 28, color: loaderColor)),
      );
    }

    if (isDisabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDisabledTap,
        child: IgnorePointer(
          child: Switch(
            value: value,
            onChanged: null,
            activeThumbColor: inactiveThumbColor,
            activeTrackColor: inactiveTrackColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          ),
        ),
      );
    }

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );
  }
}
