import 'package:flutter/material.dart';

IconData iconForProductCategory(String category) {
  final normalized = _normalizeCategory(category);

  if (_containsAny(normalized, ['menu', 'formule', 'combo'])) {
    return Icons.menu_book_outlined;
  }
  if (_containsAny(normalized, ['populaire', 'best seller', 'favori'])) {
    return Icons.local_fire_department_outlined;
  }
  if (_containsAny(normalized, ['promo', 'offre', 'reduction', 'deal'])) {
    return Icons.local_offer_outlined;
  }
  if (_containsAny(normalized, ['nouveau', 'nouveaute'])) {
    return Icons.auto_awesome_outlined;
  }
  if (_containsAny(normalized, ['entree', 'appetizer', 'starter', 'tapas'])) {
    return Icons.tapas_outlined;
  }
  if (_containsAny(normalized, ['plat', 'dish', 'repas', 'specialite'])) {
    return Icons.restaurant_outlined;
  }
  if (_containsAny(normalized, [
    'africain',
    'guineen',
    'local',
    'traditionnel',
  ])) {
    return Icons.rice_bowl_outlined;
  }
  if (_containsAny(normalized, ['riz', 'thieb', 'mafe', 'yassa', 'fonio'])) {
    return Icons.rice_bowl_outlined;
  }
  if (_containsAny(normalized, [
    'poulet',
    'viande',
    'boeuf',
    'brochette',
    'grillade',
  ])) {
    return Icons.kebab_dining_outlined;
  }
  if (_containsAny(normalized, ['poisson', 'fruit de mer', 'crevette'])) {
    return Icons.set_meal_outlined;
  }
  if (_containsAny(normalized, ['burger'])) {
    return Icons.lunch_dining_outlined;
  }
  if (_containsAny(normalized, ['pizza'])) {
    return Icons.local_pizza_outlined;
  }
  if (_containsAny(normalized, [
    'taco',
    'tacos',
    'sandwich',
    'shawarma',
    'wrap',
  ])) {
    return Icons.fastfood_outlined;
  }
  if (_containsAny(normalized, ['salade', 'healthy', 'leger'])) {
    return Icons.eco_outlined;
  }
  if (_containsAny(normalized, ['vegetarien', 'vegan', 'vegetal'])) {
    return Icons.spa_outlined;
  }
  if (_containsAny(normalized, [
    'accompagnement',
    'side',
    'frites',
    'alloco',
    'plantain',
  ])) {
    return Icons.ramen_dining_outlined;
  }
  if (_containsAny(normalized, ['sauce', 'supplement', 'extra'])) {
    return Icons.soup_kitchen_outlined;
  }
  if (_containsAny(normalized, [
    'dessert',
    'gateau',
    'glace',
    'crepe',
    'chocolat',
    'fruit',
  ])) {
    return Icons.cake_outlined;
  }
  if (_containsAny(normalized, [
    'boisson',
    'beverage',
    'jus',
    'bissap',
    'gingembre',
    'soda',
  ])) {
    return Icons.local_drink_outlined;
  }
  if (_containsAny(normalized, ['cafe', 'the', 'chaud'])) {
    return Icons.local_cafe_outlined;
  }
  if (_containsAny(normalized, ['eau'])) {
    return Icons.water_drop_outlined;
  }
  if (_containsAny(normalized, ['famille', 'partager', 'duo', 'groupe'])) {
    return Icons.groups_outlined;
  }
  if (_containsAny(normalized, ['enfant', 'kids'])) {
    return Icons.child_care_outlined;
  }

  return Icons.category_outlined;
}

String _normalizeCategory(String category) {
  return category
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ');
}

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}
