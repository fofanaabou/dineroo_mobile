import 'package:dineroo_mobile/customer/models/domain/choice_group.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

class RestaurantChoiceItemTile extends StatelessWidget {
  final ChoiceItem item;
  final int index;
  final Widget trailing;
  final List<Widget> metadata;
  final bool showUnavailableLabel;
  final bool dimUnavailable;

  const RestaurantChoiceItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.trailing,
    this.metadata = const [],
    this.showUnavailableLabel = false,
    this.dimUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimUnavailable && !item.available ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: index > 0
              ? Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ChoiceItemImage(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceItemInfo(item: item, metadata: _metadata),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }

  List<Widget> get _metadata {
    final items = <Widget>[];
    if (showUnavailableLabel && !item.available) {
      items.add(
        Text(
          'Indisponible',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }
    items.addAll(metadata);
    return items;
  }
}

class _ChoiceItemInfo extends StatelessWidget {
  final ChoiceItem item;
  final List<Widget> metadata;

  const _ChoiceItemInfo({required this.item, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final hasMetadata = item.additionalPrice > 0 || metadata.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: item.available ? Colors.black87 : Colors.grey,
          ),
        ),
        if (hasMetadata) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (item.additionalPrice > 0)
                Text(
                  '+${formatPrice(item.additionalPrice)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              for (final widget in metadata) ...[
                if (item.additionalPrice > 0 || widget != metadata.first)
                  const SizedBox(width: 8),
                widget,
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ChoiceItemImage extends StatelessWidget {
  final ChoiceItem item;

  const _ChoiceItemImage({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.productImageUrl.trim();

    if (imageUrl.isNotEmpty) {
      return AppNetworkImage(
        imageUrl: imageUrl,
        width: 52,
        height: 52,
        borderRadius: 8,
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant_outlined,
        color: Colors.grey.shade400,
        size: 22,
      ),
    );
  }
}
