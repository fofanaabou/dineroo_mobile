part of 'driver_delivery_history_footer.dart';

class _DriverEarningBanner extends StatelessWidget {
  final String value;

  const _DriverEarningBanner({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFEAD7)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 18,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gain livreur',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
