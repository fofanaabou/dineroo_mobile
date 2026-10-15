class ChoiceItem {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String productDescription;
  final bool productConfigurable;
  final double additionalPrice;
  final bool available;
  final int displayOrder;

  const ChoiceItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl = '',
    this.productDescription = '',
    this.productConfigurable = false,
    this.additionalPrice = 0.0,
    this.available = true,
    this.displayOrder = 0,
  });
}

class ChoiceGroup {
  final String id;
  final String name;
  final bool required;
  final int minSelections;
  final int maxSelections;
  final int displayOrder;
  final List<ChoiceItem> items;

  const ChoiceGroup({
    required this.id,
    required this.name,
    this.required = false,
    this.minSelections = 1,
    this.maxSelections = 1,
    this.displayOrder = 0,
    required this.items,
  });
}
