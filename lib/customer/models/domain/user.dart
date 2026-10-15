import 'package:dineroo_mobile/customer/models/domain/organization.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/common/helpers/user_role_helper.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;
  final bool isTemporaryPin;
  final String? courierStatus;
  final Organization? organization;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    required this.isTemporaryPin,
    this.courierStatus,
    this.organization,
  });

  UserRole get userRoleEnum => parseUserRole(role);

  bool get isRejectedCourier => courierStatus?.toUpperCase() == 'REJECTED';

  bool get isMissingCourierFile =>
      courierStatus?.toUpperCase() == 'ID_FILE_MISSING';

  factory User.fromToken(Map<String, dynamic> decodedToken) {
    String? role;

    final userServiceRoles =
        decodedToken['resource_access']?['user-service-client']?['roles']
            as List<dynamic>?;
    if (userServiceRoles != null && userServiceRoles.isNotEmpty) {
      role = userServiceRoles.first.toString().toUpperCase();
    }

    if (role == null) {
      final dinerooRoles =
          decodedToken['resource_access']?['dineroo-app']?['roles']
              as List<dynamic>?;
      if (dinerooRoles != null && dinerooRoles.isNotEmpty) {
        role = dinerooRoles.first.toString().toUpperCase();
      }
    }

    if (role == null) {
      final realmRoles = decodedToken['realm_access']?['roles']
          as List<dynamic>?;
      if (realmRoles != null && realmRoles.isNotEmpty) {
        final filtered = realmRoles
            .where((r) => !r.toString().toUpperCase().startsWith('OFFLINE_'));
        if (filtered.isNotEmpty) {
          role = filtered.first.toString().toUpperCase();
        }
      }
    }

    final canonicalRole = canonicalizeRole(role);

    final organization = Organization.fromToken(decodedToken);

    return User(
      id: (decodedToken['sub'] ?? '') as String,
      firstName: (decodedToken['given_name'] ?? '') as String,
      lastName: (decodedToken['family_name'] ?? '') as String,
      phoneNumber: (decodedToken['preferred_username'] ?? '') as String,
      role: canonicalRole,
      isTemporaryPin: false,
      courierStatus: decodedToken['courierStatus']?.toString(),
      organization: organization,
    );
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? role,
    bool? isTemporaryPin,
    String? courierStatus,
    Organization? organization,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isTemporaryPin: isTemporaryPin ?? this.isTemporaryPin,
      courierStatus: courierStatus ?? this.courierStatus,
      organization: organization ?? this.organization,
    );
  }
}
