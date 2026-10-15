// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_address.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeliveryAddressAdapter extends TypeAdapter<DeliveryAddress> {
  @override
  final int typeId = 2;

  @override
  DeliveryAddress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeliveryAddress(
      phoneNumber: fields[0] as String,
      address: fields[1] as String,
      district: fields[2] as String,
      commune: fields[3] as String?,
      instructions: fields[4] as String?,
      firstName: fields[5] as String?,
      lastName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeliveryAddress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.phoneNumber)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.district)
      ..writeByte(3)
      ..write(obj.commune)
      ..writeByte(4)
      ..write(obj.instructions)
      ..writeByte(5)
      ..write(obj.firstName)
      ..writeByte(6)
      ..write(obj.lastName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAddressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
