import 'package:flutter/material.dart';

class AppAddressRow extends StatelessWidget {
  final String address;

  const AppAddressRow({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Color(0xFF32343E)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              color: Color(0xFF32343E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
