import 'package:dineroo_mobile/manager/views/manager_suspension_notice.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/models/domain/suspension.dart';
import 'package:dineroo_mobile/shared/services/user/user_call_service.dart';
import 'package:flutter/material.dart';

class ManagerSuspensionBanner extends StatelessWidget {
  static const Color _background = Color(0xFFB3261E);
  static const Color _accent = Color(0xFFFFDAD6);

  final Suspension suspension;
  final VoidCallback? onContactSupport;

  const ManagerSuspensionBanner({
    super.key,
    required this.suspension,
    this.onContactSupport,
  });

  void _contactSupport(BuildContext context) {
    final override = onContactSupport;
    if (override != null) {
      override();
      return;
    }
    UserCallService.makeCall(context, Constants.supportPhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _contactSupport(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ManagerSuspensionNotice.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                suspension.reason.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.support_agent, color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ManagerSuspensionNotice.supportPrompt,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
