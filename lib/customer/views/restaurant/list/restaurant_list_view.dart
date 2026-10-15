import 'dart:async';
import 'package:dineroo_mobile/customer/views/restaurant/list/recent_searches_section.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_scaffold.dart';
import 'package:dineroo_mobile/customer/views/orders/active_order_banner.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_paginated_list.dart';
import 'package:dineroo_mobile/customer/views/restaurant/list/restaurant_card.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_search_bar.dart';
import 'package:dineroo_mobile/shared/view_models/location/location_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/common/widgets/app_empty_state.dart';
import '../../../../shared/common/widgets/app_error_retry.dart';
import '../../../../shared/common/widgets/app_loader.dart';
import '../../../services/restaurant/restaurant_list_service.dart';
import '../../../services/restaurant/restaurant_service.dart';
import '../../../repositories/restaurant_repository.dart';
import '../../../view_models/restaurant/restaurant_list_view_model.dart';
import '../../../view_models/order/order_list_view_model.dart';

class RestaurantListView extends StatefulWidget {
  const RestaurantListView({super.key});

  @override
  State<RestaurantListView> createState() => _RestaurantListViewState();
}

class _RestaurantListViewState extends State<RestaurantListView> {
  final searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(RestaurantListViewModel vm, String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      vm.searchRestaurants(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final locationVM = context.read<LocationViewModel>();
        return RestaurantListViewModel(
          RestaurantRepository(
            service: RestaurantService(),
            listService: RestaurantListService(),
          ),
          locationVM,
        )..fetchRestaurants(refresh: true);
      },
      child: Consumer<RestaurantListViewModel>(
        builder: (context, vm, _) {
          return AppScaffold(
            title: 'Restaurants à proximité',
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AppSearchBar(
                    controller: searchController,
                    hintText: 'Rechercher sur Dineroo',
                    onChanged: (query) => _onSearchChanged(vm, query),
                    onSubmitted: (query) => vm.searchRestaurants(query),
                    onClear: () {
                      searchController.clear();
                      vm.resetSearch();
                    },
                  ),
                ),

                RecentSearchesSection(
                  recentSearches: vm.recentSearches,
                  activeSearch: vm.currentSearch,
                  onClearAll: vm.clearRecentSearches,
                  onSearchSelected: (term) {
                    searchController.text = term;
                    vm.searchRestaurants(term);
                  },
                ),

                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (vm.isLoading && vm.restaurants.isEmpty) {
                        return const Center(child: AppLoader());
                      }

                      if (vm.error != null && vm.restaurants.isEmpty) {
                        return AppErrorRetry(
                          onPressed: () => vm.fetchRestaurants(refresh: true),
                        );
                      }

                      if (vm.restaurants.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.restaurant_menu,
                          message: 'Aucun restaurant trouvé',
                        );
                      }

                      final orderViewModel =
                          context.watch<OrderListViewModel>();
                      final hasActiveOrder = orderViewModel.hasActiveOrder;

                      return Column(
                        children: [
                          if (hasActiveOrder)
                            const ActiveOrderBanner(),
                          Expanded(
                            child: AppPaginatedList<Restaurant>(
                              items: vm.restaurants,
                              itemBuilder: (r) => RestaurantCard(restaurant: r),
                              onRefresh:
                                  () => vm.fetchRestaurants(refresh: true),
                              onLoadMore: vm.loadMore,
                              canLoadMore: vm.canLoadMore,
                              isLoading: vm.isLoading,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
