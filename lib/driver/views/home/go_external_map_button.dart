import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GoExternalMapButton extends StatelessWidget {
  final String label;
  final String query;
  final double? latitude;
  final double? longitude;

  const GoExternalMapButton({
    super.key,
    required this.label,
    required this.query,
    this.latitude,
    this.longitude,
  });

  bool get _hasCoordinates => latitude != null && longitude != null;

  Future<void> _openExternalNavigation() async {
    final encodedQuery = Uri.encodeComponent(query.trim());
    final latLng = _hasCoordinates ? '$latitude,$longitude' : null;

    final googleAndroidUri = Uri.parse(
      _hasCoordinates
          ? 'google.navigation:q=$latLng&mode=d'
          : 'google.navigation:q=$encodedQuery&mode=d',
    );

    final googleIOSUri = Uri.parse(
      _hasCoordinates
          ? 'comgooglemaps://?daddr=$latLng&directionsmode=driving'
          : 'comgooglemaps://?daddr=$encodedQuery&directionsmode=driving',
    );

    final appleUri = Uri.parse(
      _hasCoordinates
          ? 'http://maps.apple.com/?daddr=$latLng&dirflg=d'
          : 'http://maps.apple.com/?daddr=$encodedQuery&dirflg=d',
    );

    final googleWebUri = Uri.parse(
      _hasCoordinates
          ? 'https://www.google.com/maps/dir/?api=1&destination=$latLng&travelmode=driving'
          : 'https://www.google.com/maps/dir/?api=1&destination=$encodedQuery&travelmode=driving',
    );

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(googleAndroidUri)) {
          await launchUrl(
            googleAndroidUri,
            mode: LaunchMode.externalApplication,
          );
          return;
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(googleIOSUri)) {
          await launchUrl(googleIOSUri, mode: LaunchMode.externalApplication);
          return;
        }

        if (await canLaunchUrl(appleUri)) {
          await launchUrl(appleUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      await launchUrl(googleWebUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(googleWebUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openExternalNavigation,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'GO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
