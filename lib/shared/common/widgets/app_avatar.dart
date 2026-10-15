import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.showBorder = false,
    this.borderColor = const Color(0xFFE5E7EB),
    this.borderWidth = 1.0,
  });

  Widget _defaultAvatar() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFFBE9E9),
      child: const Icon(Icons.person, color: Colors.deepOrange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _defaultAvatar();
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              alignment: Alignment.center,
              child: AppLoader(size: (size * 0.45).clamp(12, 18).toDouble()),
            ),
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => _defaultAvatar(),
            ),
            if (showBorder)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: borderWidth),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
