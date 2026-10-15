import 'package:flutter/material.dart';

class ManagerHomeEmptyState extends StatelessWidget {
  const ManagerHomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1E9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 45,
                    child: Container(
                      width: 112,
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFF5A14),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 54,
                    child: Container(
                      width: 126,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE2D3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF5A14),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 42,
                    top: 36,
                    child: Icon(
                      Icons.near_me_outlined,
                      color: Color(0xFFFF5A14),
                      size: 30,
                    ),
                  ),
                  const Positioned(
                    left: 52,
                    bottom: 62,
                    child: Icon(
                      Icons.door_front_door_outlined,
                      color: Color(0xFFFF5A14),
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune commande pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1C2331),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les nouvelles commandes apparaîtront ici dès qu’elles seront passées.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
