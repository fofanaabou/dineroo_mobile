import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder:
            (context, url) => SizedBox(
              width: width,
              height: height,
              child: const Center(child: AppLoader(size: 20)),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: width,
              height: height,
              color: backgroundColor ?? Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
      ),
    );
  }
}
