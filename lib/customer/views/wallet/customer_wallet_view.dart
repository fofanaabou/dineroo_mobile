import 'package:dineroo_mobile/customer/models/domain/wallet.dart';
import 'package:dineroo_mobile/customer/models/domain/wallet_transaction.dart';
import 'package:dineroo_mobile/customer/view_models/wallet/wallet_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/utils/date_utils.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerWalletView extends StatefulWidget {
  const CustomerWalletView({super.key});

  @override
  State<CustomerWalletView> createState() => _CustomerWalletViewState();
}

class _CustomerWalletViewState extends State<CustomerWalletView> {
  String? _customerId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final customerId = context.watch<CurrentUserViewModel>().currentUser?.id;
    if (_customerId == customerId) return;

    _customerId = customerId;
    if (customerId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _customerId != customerId) return;
      _loadWallet(customerId);
    });
  }

  Future<void> _loadWallet([String? requestedCustomerId]) async {
    final customerId =
        requestedCustomerId ??
        context.read<CurrentUserViewModel>().currentUser?.id;
    if (customerId == null) {
      return;
    }

    _customerId = customerId;

    try {
      await context.read<WalletViewModel>().getWallet(customerId);
    } catch (_) {
      // WalletViewModel owns and exposes the error state for the view.
    }
  }

  Future<void> _refresh() async {
    await _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(title: const Text('Mon Wallet')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final customerId = _customerId;
    final wallet = walletVM.wallet?.customerId == customerId
        ? walletVM.wallet
        : null;
    final hasError = customerId == null || walletVM.error != null;

    if (walletVM.isLoading && wallet == null) {
      return const Center(child: AppLoader());
    }

    if (hasError && wallet == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
          AppErrorRetry(
            message: 'Impossible de charger votre Wallet.',
            onPressed: () {
              _refresh();
            },
          ),
        ],
      );
    }

    if (wallet == null) {
      return const Center(child: AppLoader());
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _WalletBalanceCard(wallet: wallet),
        const SizedBox(height: 24),
        Text(
          'Historique',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (wallet.transactions.isEmpty)
          const _WalletEmptyHistory()
        else
          ...wallet.transactions.map(
            (transaction) => _WalletTransactionTile(
              transaction: transaction,
              currency: wallet.currency,
            ),
          ),
      ],
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final Wallet wallet;

  const _WalletBalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A35D6), Color(0xFF2D1B74)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A35D6).withAlpha(51),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(31),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Solde Wallet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            formatPrice(wallet.balance, currency: wallet.currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Utilisable au paiement de vos commandes.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  final WalletTransaction transaction;
  final String currency;

  const _WalletTransactionTile({
    required this.transaction,
    required this.currency,
  });

  bool get _isCredit => transaction.type.toUpperCase() == 'CREDIT';

  @override
  Widget build(BuildContext context) {
    final amountColor = _isCredit
        ? const Color(0xFF148A4A)
        : const Color(0xFFD33A2C);
    final iconColor = _isCredit
        ? const Color(0xFFE7F6ED)
        : const Color(0xFFFCEAE8);
    final icon = _isCredit ? Icons.add_rounded : Icons.remove_rounded;
    final sign = _isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: amountColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$sign${formatPrice(transaction.amount, currency: currency)}',
                      style: TextStyle(
                        color: amountColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.createdAt == null
                      ? 'Date indisponible'
                      : formatDateTime(transaction.createdAt!),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletEmptyHistory extends StatelessWidget {
  const _WalletEmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.black38, size: 34),
          SizedBox(height: 10),
          Text(
            'Aucune transaction pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
