import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/restaurant.dart';
import 'restaurant_card.dart';

class RestaurantList extends StatelessWidget {
  final List<Restaurant> restaurants;

  const RestaurantList({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: restaurants.length,
      itemBuilder:
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RestaurantCard(restaurant: restaurants[index]),
          ),
    );
  }
}
