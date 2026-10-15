import 'package:dineroo_mobile/shared/services/user/user_call_service.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';

class AppContactSupportButton extends StatefulWidget {
  final String phoneNumber;
  final double size;
  final double padding;

  const AppContactSupportButton({
    super.key,
    required this.phoneNumber,
    this.size = 60,
    this.padding = 10,
  });

  @override
  State<AppContactSupportButton> createState() => _SupportButtonState();
}

class _SupportButtonState extends State<AppContactSupportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showConfirmAndCall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AppDialog(
          title: "Contacter le support!",
          message: "Vous êtes sur le point d'appeler le support.",
          confirmText: "Appeler",
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      await UserCallService.makeCall(context, widget.phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: InkWell(
        onTap: _showConfirmAndCall,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: EdgeInsets.all(widget.padding),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/support.png",
            width: widget.size,
            height: widget.size,
          ),
        ),
      ),
    );
  }
}
