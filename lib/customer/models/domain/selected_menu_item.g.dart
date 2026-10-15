// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_menu_item.dart';

class SelectedMenuItemAdapter extends TypeAdapter<SelectedMenuItem> {
  @override
  final int typeId = 3;

  @override
  SelectedMenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelectedMenuItem(
      groupId: fields[0] as String,
      groupName: fields[1] as String,
      menuItemId: fields[2] as String,
      productId: fields[3] as String,
      productName: fields[4] as String,
      additionalPrice: (fields[5] as num?)?.toDouble() ?? 0.0,
      productChoicesJson: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SelectedMenuItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.groupId)
      ..writeByte(1)
      ..write(obj.groupName)
      ..writeByte(2)
      ..write(obj.menuItemId)
      ..writeByte(3)
      ..write(obj.productId)
      ..writeByte(4)
      ..write(obj.productName)
      ..writeByte(5)
      ..write(obj.additionalPrice)
      ..writeByte(6)
      ..write(obj.productChoicesJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedMenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
