import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class AppNetworkStatusBanner extends StatefulWidget {
  final Widget child;
  final Connectivity? connectivity;

  const AppNetworkStatusBanner({
    super.key,
    required this.child,
    this.connectivity,
  });

  @override
  State<AppNetworkStatusBanner> createState() => _AppNetworkStatusBannerState();
}

class _AppNetworkStatusBannerState extends State<AppNetworkStatusBanner> {
  static const _onlineMessageDuration = Duration(seconds: 3);

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _hideOnlineMessageTimer;

  bool _isOffline = false;
  bool _wasOffline = false;
  bool _showOnlineMessage = false;

  @override
  void initState() {
    super.initState();
    _connectivity = widget.connectivity ?? Connectivity();
    _checkInitialConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideOnlineMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (!mounted) return;
    final isOffline = _isOfflineResult(results);
    setState(() {
      _isOffline = isOffline;
      _wasOffline = isOffline;
    });
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final isOffline = _isOfflineResult(results);
    if (isOffline == _isOffline) return;

    _hideOnlineMessageTimer?.cancel();
    setState(() {
      _isOffline = isOffline;
      _showOnlineMessage = !isOffline && _wasOffline;
      _wasOffline = isOffline;
    });

    if (_showOnlineMessage) {
      _hideOnlineMessageTimer = Timer(_onlineMessageDuration, () {
        if (mounted) setState(() => _showOnlineMessage = false);
      });
    }
  }

  bool _isOfflineResult(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowBanner = _isOffline || _showOnlineMessage;

    return Stack(
      children: [
        widget.child,
        if (shouldShowBanner)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: _ConnectivityBanner(
                message: _isOffline
                    ? 'Connexion Internet perdue'
                    : 'Connexion rétablie',
                icon: _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                backgroundColor: _isOffline
                    ? const Color(0xFFD00000)
                    : const Color(0xFF1DB954),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;

  const _ConnectivityBanner({
    required this.message,
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
