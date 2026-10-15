import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/common/form_fields/first_name_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/last_name_field.dart';
import 'package:dineroo_mobile/shared/common/form_fields/phone_field.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_avatar.dart';
import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/restaurant_opening_hours_view.dart';
import 'package:dineroo_mobile/shared/views/profile/profile_content_tile.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';

class ProfileContent extends StatelessWidget {
  final User user;
  final File? profileImage;
  final bool isEditing;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final List<Widget> actionTiles;
  final VoidCallback onToggleObscure;

  const ProfileContent({
    super.key,
    required this.user,
    required this.profileImage,
    required this.isEditing,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    this.actionTiles = const [],
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final isDriver = user.userRoleEnum == UserRole.driver;
    final isManager = user.userRoleEnum == UserRole.restaurantManager;

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileAvatar(userId: user.id, initialImage: profileImage),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FirstNameField(
                  controller: firstNameController,
                  enabled: isEditing && !isDriver,
                ),
                const SizedBox(height: 20),
                LastNameField(
                  controller: lastNameController,
                  enabled: isEditing && !isDriver,
                ),
                const SizedBox(height: 20),
                PhoneField(controller: phoneController, enabled: isEditing),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...actionTiles,
                      ProfileContentTile(
                        icon: Icons.lock_outline,
                        label: 'Changer le code PIN',
                        onTap: onToggleObscure,
                      ),

                      if (isManager) ...[
                        const Divider(height: 1, color: Color(0xFFEAEAEA)),
                        ProfileContentTile(
                          icon: Icons.access_time,
                          label: 'Changer les horaires du restaurant',
                          onTap: () {
                            navigateTo(
                              context,
                              RestaurantOpeningHoursView(
                                restaurantId: user.organization?.id ?? '',
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
