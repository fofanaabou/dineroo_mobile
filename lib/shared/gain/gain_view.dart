import 'package:dineroo_mobile/shared/common/widgets/app_dialog.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/gain/gain_content.dart';
import 'package:dineroo_mobile/shared/gain/earnings_service.dart';
import 'package:dineroo_mobile/shared/gain/earnings_summary.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GainView extends StatefulWidget {
  const GainView({super.key});

  @override
  State<GainView> createState() => _GainViewState();
}

class _GainViewState extends State<GainView> {
  final EarningsService _earningsService = EarningsService();
  EarningsSummary _summary = EarningsSummary.empty();
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEarnings());
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final currentUser = context.read<CurrentUserViewModel>().currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = Exception('Utilisateur introuvable');
      });
      return;
    }

    try {
      final restaurantId = currentUser.organization?.id ?? '';
      final summary = switch (currentUser.userRoleEnum) {
        UserRole.restaurantManager when restaurantId.isNotEmpty =>
          await _earningsService.fetchRestaurantEarnings(restaurantId),
        UserRole.driver => await _earningsService.fetchDriverEarnings(
          currentUser.id,
        ),
        _ => EarningsSummary.empty(),
      };

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  void _showWithdrawDialog(BuildContext context) {
    final availableAmount = formatPrice(
      _summary.availableAmount,
      currency: _summary.currency,
    );

    showDialog(
      context: context,
      builder:
          (_) => AppDialog(
            title: 'Retrait de vos gains',
            message:
                'Montant disponible : $availableAmount\n\nLes retraits sont traités par le support Dineroo. Contactez-nous pour recevoir votre paiement.',
            confirmText: 'OK',
            onConfirm: () {
              Navigator.of(context).pop();
            },
            showCancel: false,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: GainContent(
          summary: _summary,
          isLoading: _isLoading,
          hasError: _error != null,
          onRefresh: _loadEarnings,
          onRetry: _loadEarnings,
          onWithdraw: () => _showWithdrawDialog(context),
        ),
      ),
    );
  }
}
