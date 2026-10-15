import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/restaurant_opening_hours_body.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RestaurantOpeningHoursView extends StatelessWidget {
  final String restaurantId;

  const RestaurantOpeningHoursView({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ManagerRestaurantViewModel(
          ManagerRestaurantRepository(service: ManagerRestaurantService()),
        );
        vm.loadRestaurantState(restaurantId);
        return vm;
      },
      child: Consumer<ManagerRestaurantViewModel>(
        builder: (context, vm, _) {
          return AppScaffold(
            title: 'Changer les horaires',
            showBack: true,
            showCartIcon: false,
            body:
                vm.isLoading
                    ? const Center(child: AppLoader())
                    : RestaurantOpeningHoursBody(restaurantId: restaurantId),
          );
        },
      ),
    );
  }
}
