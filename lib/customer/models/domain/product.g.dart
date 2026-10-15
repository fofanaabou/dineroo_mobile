// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      name: fields[1] as String,
      price: (fields[2] as num).toDouble(),
      imageUrl: fields[3] as String,
      category: fields[4] as String,
      restaurantId: fields[5] as String,
      restaurantName: fields[6] as String,
      available: fields[7] as bool,
      canBeSoldAlone: (fields[8] as bool?) ?? true,
      description: (fields[9] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.restaurantId)
      ..writeByte(6)
      ..write(obj.restaurantName)
      ..writeByte(7)
      ..write(obj.available)
      ..writeByte(8)
      ..write(obj.canBeSoldAlone)
      ..writeByte(9)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
