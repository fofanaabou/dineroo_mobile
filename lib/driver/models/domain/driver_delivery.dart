import 'package:dineroo_mobile/driver/enums/delivery_status.dart';
import 'dart:convert';

class DriverDelivery {
  final String id;
  final String orderId;
  final String? driverId;
  final DeliveryStatus status;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> deliveryAddress;
  final double? deliveryFee;
  final double? estimatedDeliveryDistance;
  final DateTime? driverAssignedAt;
  final DateTime? pickedUpAt;
  final DateTime? createdAt;
  final String? pickupOtpCode;

  DriverDelivery({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.deliveryFee,
    this.estimatedDeliveryDistance,
    this.driverAssignedAt,
    this.pickedUpAt,
    this.createdAt,
    this.pickupOtpCode,
  });

  factory DriverDelivery.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    Map<String, dynamic> parseAddress(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return <String, dynamic>{};
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) {
            return decoded.map(
              (key, mapValue) => MapEntry(key.toString(), mapValue),
            );
          }
        } catch (_) {
          return <String, dynamic>{'address': trimmed};
        }
      }
      return <String, dynamic>{};
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return DriverDelivery(
      id: (json['id'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      driverId: json['driverId']?.toString(),
      status: DeliveryStatus.fromApi(json['status']?.toString()),
      pickupAddress: parseAddress(json['pickupAddress']),
      deliveryAddress: parseAddress(json['deliveryAddress']),
      deliveryFee: parseDouble(json['fee']),
      estimatedDeliveryDistance: parseDouble(json['distanceKm']),
      driverAssignedAt: parseDate(json['driverAssignedAt']),
      pickedUpAt: parseDate(json['pickedUpAt']),
      createdAt: parseDate(json['createdAt']),
      pickupOtpCode: json['pickupOtpCode']?.toString(),
    );
  }

  String get pickupAddressLabel {
    final address = pickupAddress['address']?.toString().trim() ?? '';
    final district = pickupAddress['district']?.toString().trim() ?? '';
    final commune = pickupAddress['commune']?.toString().trim() ?? '';

    final parts = [
      address,
      district,
      commune,
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return '';
  }

  String get deliveryAddressLabel {
    final address = deliveryAddress['address']?.toString().trim() ?? '';
    final district = deliveryAddress['district']?.toString().trim() ?? '';
    final commune = deliveryAddress['commune']?.toString().trim() ?? '';

    final parts = [
      address,
      district,
      commune,
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return '';
  }
}
