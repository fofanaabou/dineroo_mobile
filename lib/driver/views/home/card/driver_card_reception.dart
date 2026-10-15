import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_close_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_progress_button.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:dineroo_mobile/shared/views/orders/order_card_container.dart';

typedef DriverCardReceptionSoundAction = void Function();

class DriverCardReception extends StatefulWidget {
  final num price;
  final String? restaurantDistanceLabel;
  final String? startAddress;
  final String? endAddress;
  final VoidCallback onAccept;
  final VoidCallback onClose;
  final DriverCardReceptionSoundAction? playSoundLoop;
  final DriverCardReceptionSoundAction? stopSound;
  final Duration? countdownDuration;

  const DriverCardReception({
    super.key,
    required this.price,
    this.restaurantDistanceLabel,
    this.startAddress,
    this.endAddress,
    required this.onAccept,
    required this.onClose,
    this.playSoundLoop,
    this.stopSound,
    this.countdownDuration,
  });

  @override
  State<DriverCardReception> createState() => _DriverDialogReceptionState();
}

class _DriverDialogReceptionState extends State<DriverCardReception>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _countdownSeconds = 20;

  late final AnimationController _controller;
  final _soundService = NotificationSoundService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration:
          widget.countdownDuration ??
          const Duration(seconds: _countdownSeconds),
    );
    _playSoundLoop();
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _stopSound();
        Navigator.of(context).pop();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _stopSound();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      _playSoundLoop();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopSound();
    }
  }

  void _playSoundLoop() => (widget.playSoundLoop ?? _soundService.playLoop)();
  void _stopSound() => (widget.stopSound ?? _soundService.stop)();

  int get _remainingSeconds {
    final remaining = (_countdownSeconds * (1 - _controller.value)).ceil();
    return remaining.clamp(0, _countdownSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return OrderCardContainer(
      child: PopScope(
        canPop: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant de la course',
                  style: TextStyle(fontSize: 14, color: Color(0xFF32343E)),
                ),
                AppCloseButton(
                  onPressed: () {
                    _stopSound();
                    Navigator.of(context).pop();
                    widget.onClose();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatPrice(widget.price),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A0338),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.restaurantDistanceLabel != null)
              Text(
                widget.restaurantDistanceLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF32343E),
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            if (widget.startAddress != null || widget.endAddress != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF32343E),
                        size: 18,
                      ),
                      Container(
                        width: 2,
                        height: 26,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFF32343E),
                      ),
                      const Icon(
                        Icons.place_outlined,
                        color: Color(0xFF32343E),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.startAddress != null)
                          Text(
                            widget.startAddress!,
                            style: const TextStyle(
                              color: Color(0xFF32343E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 18),
                        if (widget.endAddress != null)
                          Text(
                            widget.endAddress!,
                            style: const TextStyle(
                              color: Color(0xFF32343E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return AppProgressButton(
                  progress: _controller.value,
                  remainingSeconds: _remainingSeconds,
                  onPressed: () {
                    _stopSound();
                    Navigator.of(context).pop();
                    widget.onAccept();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
