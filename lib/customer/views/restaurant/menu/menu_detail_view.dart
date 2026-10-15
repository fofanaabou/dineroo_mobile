import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_error_retry.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_back_button.dart';
import 'package:dineroo_mobile/customer/services/restaurant/menu_service.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/menu_detail_view_model.dart';
import 'package:dineroo_mobile/customer/repositories/menu_repository.dart';
import 'package:dineroo_mobile/customer/views/restaurant/menu/menu_detail_body.dart';
import 'package:dineroo_mobile/shared/views/base_main_wrapper.dart';
import 'package:dineroo_mobile/shared/enums/main_view_tabs.dart';

class MenuDetailView extends StatelessWidget {
  final Restaurant restaurant;
  final String menuId;

  const MenuDetailView({
    super.key,
    required this.restaurant,
    required this.menuId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = MenuDetailViewModel(MenuRepository(MenuService()));
        viewModel.fetchWithRestaurant(restaurant, menuId);
        return viewModel;
      },
      child: Consumer<MenuDetailViewModel>(
        builder: (context, viewModel, _) {
          Widget content;

          if (viewModel.isLoading) {
            content = const Scaffold(body: Center(child: AppLoader()));
          } else if (viewModel.error != null) {
            content = Stack(
              children: [
                AppErrorRetry(
                  onPressed:
                      () => viewModel.fetchWithRestaurant(restaurant, menuId),
                ),
                const Positioned(top: 50, left: 16, child: AppBackButton()),
              ],
            );
          } else {
            content = MenuDetailBody(
              menuDetail: viewModel.menuDetail!,
              restaurant: viewModel.restaurant!,
              onRefresh: () => viewModel.fetchWithRestaurant(restaurant, menuId),
            );
          }

          return BaseMainWrapper(
            role: UserRole.customer,
            selectedIndex: CustomerMainViewTab.home.index,
            child: content,
          );
        },
      ),
    );
  }
}
