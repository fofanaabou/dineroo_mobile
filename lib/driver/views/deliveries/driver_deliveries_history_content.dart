part of 'driver_deliveries_history_view.dart';

class _DriverDeliveriesHistoryContent extends StatelessWidget {
  const _DriverDeliveriesHistoryContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverOrderHistoryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: AppLoader());
        }

        if (viewModel.hasError) {
          return AppErrorRetry(onPressed: viewModel.fetchOrders);
        }

        return Column(
          children: [
            if (viewModel.hasPartialError)
              _DriverDeliveriesPartialErrorBanner(
                failedOrdersCount: viewModel.failedOrdersCount,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.fetchOrders,
                child: OrderList(
                  future: Future.value(viewModel.orders),
                  onRetry: viewModel.fetchOrders,
                  emptyMessage: 'Aucune livraison à afficher',
                  hidePrice: true,
                  footerBuilder: (order) {
                    final item = viewModel.itemForOrder(order);
                    if (item == null) return const SizedBox.shrink();
                    return DriverDeliveryHistoryFooter(item: item);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DriverDeliveriesPartialErrorBanner extends StatelessWidget {
  final int failedOrdersCount;

  const _DriverDeliveriesPartialErrorBanner({required this.failedOrdersCount});

  @override
  Widget build(BuildContext context) {
    final message =
        failedOrdersCount > 1
            ? '$failedOrdersCount livraisons n’ont pas pu être chargées.'
            : 'Une livraison n’a pas pu être chargée.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD7B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF7300), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$message Les autres restent affichées.',
              style: const TextStyle(
                color: Color(0xFF7A3B00),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
