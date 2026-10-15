import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/gain/earnings_summary.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GainContent extends StatelessWidget {
  final EarningsSummary summary;
  final bool isLoading;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onWithdraw;

  const GainContent({
    super.key,
    required this.summary,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
    required this.onRetry,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    final isManager = currentUser?.userRoleEnum == UserRole.restaurantManager;

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: const Color(0xFFFF7300),
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF7300), Color(0xFFFF9A3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: kToolbarHeight,
                            child: Center(
                              child: Text(
                                'Gains',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Montant Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          else
                            Text(
                              formatPrice(
                                summary.availableAmount,
                                currency: summary.currency,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            isManager
                                ? 'Calculé sur les commandes livrées ou terminées.'
                                : 'Calculé sur les courses livrées.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (hasError)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: AppErrorRetry(
                            message:
                                'Impossible de charger vos gains pour le moment.',
                            onPressed: onRetry,
                          ),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GainMetricCard(
                                label:
                                    isManager
                                        ? 'Commandes terminées'
                                        : 'Courses terminées',
                                value:
                                    isLoading
                                        ? '-'
                                        : summary.completedOrdersCount
                                            .toString(),
                                highlight: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _GainMetricCard(
                                label: 'Déjà payé',
                                value:
                                    isLoading
                                        ? '-'
                                        : formatPrice(
                                          summary.paidAmount,
                                          currency: summary.currency,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GainMetricCard(
                                label: 'Total gagné',
                                value:
                                    isLoading
                                        ? '-'
                                        : formatPrice(
                                          summary.totalEarned,
                                          currency: summary.currency,
                                        ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _GainMetricCard(
                                label: 'Devise',
                                value: summary.currency,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE9E9E9)),
                          ),
                          child: const Text(
                            'Les retraits sont gérés par Dineroo. Après paiement, votre solde est mis à jour.',
                            style: TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AppButton(
                          text: 'RETIRER MON ARGENT',
                          onPressed: isLoading ? null : onWithdraw,
                          backgroundColor: const Color(0xFFFF7300),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GainMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _GainMetricCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFFFF7300) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
