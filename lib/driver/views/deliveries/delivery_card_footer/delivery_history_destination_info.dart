part of 'driver_delivery_history_footer.dart';

class _DeliveryHistoryDestinationInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int? maxLines;

  const _DeliveryHistoryDestinationInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trimmedValue,
                maxLines: maxLines,
                overflow:
                    maxLines == null
                        ? TextOverflow.clip
                        : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
