import 'package:dineroo_mobile/shared/common/widgets/app_cart_icon.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBack;
  final bool centerTitle;
  final List<Widget> extraActions;
  final bool showCartIcon;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onPressed;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.centerTitle = true,
    this.extraActions = const [],
    this.showCartIcon = true,
    this.bottom,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            showBack
                ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: AppBackButton(onPressed: onPressed),
                )
                : null,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF181C2E), fontSize: 18),
        ),
        surfaceTintColor: Colors.white,
        actions: [...extraActions, if (showCartIcon) const AppCartIcon()],
        bottom: bottom,
      ),
      body: body,
    );
  }
}
