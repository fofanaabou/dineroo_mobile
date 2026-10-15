import 'package:dineroo_mobile/customer/enums/checkout_payment_method.dart';
import 'package:dineroo_mobile/shared/common/helpers/price_helper.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'package:flutter/material.dart';

class PaymentMethodChoiceSheet extends StatefulWidget {
  final double orderTotal;
  final double walletBalance;
  final String currency;

  const PaymentMethodChoiceSheet({
    super.key,
    required this.orderTotal,
    required this.walletBalance,
    required this.currency,
  });

  static Future<CheckoutPaymentMethod?> open({
    required BuildContext context,
    required double orderTotal,
    required double walletBalance,
    required String currency,
  }) {
    return showModalBottomSheet<CheckoutPaymentMethod>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PaymentMethodChoiceSheet(
        orderTotal: orderTotal,
        walletBalance: walletBalance,
        currency: currency,
      ),
    );
  }

  @override
  State<PaymentMethodChoiceSheet> createState() =>
      _PaymentMethodChoiceSheetState();
}

class _PaymentMethodChoiceSheetState extends State<PaymentMethodChoiceSheet> {
  CheckoutPaymentMethod _selected = CheckoutPaymentMethod.djomy;

  bool get _walletIsActive => widget.walletBalance > 0;
  bool get _walletCanPay => widget.walletBalance >= widget.orderTotal;
  double get _walletApplied => _walletIsActive
      ? widget.walletBalance.clamp(0, widget.orderTotal).toDouble()
      : 0;
  double get _remainingAmount => (widget.orderTotal - _walletApplied)
      .clamp(0, widget.orderTotal)
      .toDouble();
  CheckoutPaymentMethod get _effectiveSelected =>
      _walletIsActive ? _selected : CheckoutPaymentMethod.djomy;

  @override
  void initState() {
    super.initState();
    if (widget.walletBalance > 0) {
      _selected = CheckoutPaymentMethod.wallet;
    }
  }

  String _formatAmount(double value) =>
      formatPrice(value, currency: widget.currency);

  String get _ctaText {
    if (_effectiveSelected == CheckoutPaymentMethod.wallet) {
      if (_walletCanPay) return 'Payer ${_formatAmount(widget.orderTotal)}';
      return 'Payer ${_formatAmount(_remainingAmount)}';
    }
    return 'Payer ${_formatAmount(widget.orderTotal)}';
  }

  Future<void> _confirm() async {
    if (!mounted) return;
    Navigator.of(context).pop(_effectiveSelected);
  }

  @override
  Widget build(BuildContext context) {
    final walletSelected = _effectiveSelected == CheckoutPaymentMethod.wallet;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mode de paiement',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Utilisez votre Wallet ou payez autrement.',
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 18),
          _TotalSummaryCard(total: _formatAmount(widget.orderTotal)),
          const SizedBox(height: 16),
          _PaymentChoiceCard(
            selected: walletSelected,
            enabled: _walletIsActive,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet Dineroo',
            helperText: _walletIsActive ? null : 'Aucun solde disponible',
            details: _walletIsActive
                ? [
                    _PaymentDetail(
                      label: 'Solde Wallet',
                      value: _formatAmount(widget.walletBalance),
                    ),
                    if (!_walletCanPay)
                      _PaymentDetail(
                        label: 'Reste à payer',
                        value: _formatAmount(_remainingAmount),
                      ),
                  ]
                : const [],
            onTap: _walletIsActive
                ? () => setState(() => _selected = CheckoutPaymentMethod.wallet)
                : null,
          ),
          const SizedBox(height: 10),
          _PaymentChoiceCard(
            selected: !walletSelected,
            enabled: true,
            icon: Icons.phone_android_rounded,
            title: 'Mobile Money',
            details: [
              _PaymentDetail(
                label: 'Montant à payer',
                value: _formatAmount(widget.orderTotal),
              ),
            ],
            onTap: () =>
                setState(() => _selected = CheckoutPaymentMethod.djomy),
          ),
          const SizedBox(height: 16),
          AppButton(text: _ctaText, onPressed: _confirm),
        ],
      ),
    );
  }
}

class _TotalSummaryCard extends StatelessWidget {
  final String total;

  const _TotalSummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SummaryLine(label: 'Total commande', value: total, emphasized: true),
        ],
      ),
    );
  }
}

class _PaymentChoiceCard extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String? helperText;
  final List<_PaymentDetail> details;
  final VoidCallback? onTap;

  const _PaymentChoiceCard({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    this.helperText,
    required this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Colors.deepOrange : const Color(0xFFE4E4E7);
    final backgroundColor = enabled
        ? (selected ? const Color(0xFFFFF7F2) : Colors.white)
        : const Color(0xFFF7F7F8);
    final foregroundColor = enabled ? Colors.black87 : Colors.black38;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.deepOrange.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: enabled ? Colors.black87 : Colors.black12,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? Colors.deepOrange : Colors.black26,
                ),
              ],
            ),
            if (helperText != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  helperText!,
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: details
                      .map(
                        (detail) => Padding(
                          padding: EdgeInsets.only(
                            bottom: detail == details.last ? 0 : 8,
                          ),
                          child: _SummaryLine(
                            label: detail.label,
                            value: detail.value,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentDetail {
  final String label;
  final String value;

  const _PaymentDetail({required this.label, required this.value});
}
