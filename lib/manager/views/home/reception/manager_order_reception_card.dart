import 'package:flutter/material.dart';
import 'manager_order_reception_card_content.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';

class ManagerOrderReceptionCard extends StatefulWidget {
  final Order order;
  final VoidCallback onAnimationComplete;
  final VoidCallback? onMounted;
  final bool enabled;

  const ManagerOrderReceptionCard({
    super.key,
    required this.order,
    required this.onAnimationComplete,
    this.onMounted,
    this.enabled = false,
  });

  @override
  State<ManagerOrderReceptionCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<ManagerOrderReceptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(_controller);
    _offset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(_controller);

    if (widget.enabled && widget.onMounted != null) {
      widget.onMounted!();
    }
  }

  void _handleAction() async {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);
    await _controller.forward();
    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: ManagerOrderReceptionCardContent(
          order: widget.order,
          enabled: widget.enabled,
          onAccept: _handleAction,
          onReject: _handleAction,
        ),
      ),
    );
  }
}
