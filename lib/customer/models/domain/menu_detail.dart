import 'product.dart';
import 'choice_group.dart';

class MenuDetail {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final List<Product> products;
  final List<ChoiceGroup> choiceGroups;

  const MenuDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.products = const [],
    this.choiceGroups = const [],
  });
}
