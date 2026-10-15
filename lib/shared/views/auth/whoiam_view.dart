import 'package:dineroo_mobile/shared/common/colors.dart';
import 'package:dineroo_mobile/shared/common/helpers/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_button.dart';
import 'login_view.dart';

class WhoiamView extends StatelessWidget {
  const WhoiamView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;
    final isSmallScreen = screenHeight < 600 || screenWidth < 350;

    final titleFont = isSmallScreen ? 44.0 : 60.0;
    final questionFont = isSmallScreen ? 22.0 : 30.0;
    final buttonHeight = isSmallScreen ? 52.0 : 60.0;
    final bottomPadding = isSmallScreen ? 12.0 : 24.0;

    final estimatedContentHeight =
        titleFont +
        36 +
        questionFont +
        30 +
        buttonHeight * 2 +
        30 +
        bottomPadding +
        100;

    final needsScroll = estimatedContentHeight > screenHeight;

    Widget buildContent() => Column(
      children: [
        const Spacer(),
        Center(
          child: Column(
            children: [
              Text(
                'Dineroo',
                style: TextStyle(
                  fontFamily: 'Lobster',
                  fontSize: titleFont,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Qui êtes-vous ?',
                style: TextStyle(
                  fontSize: questionFont,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: buttonHeight,
                  child: AppButton(
                    text: 'JE SUIS UN CLIENT',
                    onPressed:
                        () => navigateTo(
                          context,
                          const LoginView(selectedRole: UserRole.customer),
                        ),
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    fontWeight: FontWeight.w800,
                    isSmall: isSmallScreen,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: buttonHeight,
                  child: AppButton(
                    text: 'JE SUIS UN LIVREUR',
                    onPressed:
                        () => navigateTo(
                          context,
                          const LoginView(selectedRole: UserRole.driver),
                        ),
                    fontWeight: FontWeight.w800,
                    isSmall: isSmallScreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: GestureDetector(
            onTap:
                () => navigateTo(
                  context,
                  const LoginView(selectedRole: UserRole.restaurantManager),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ESPACE RESTAURANT',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      letterSpacing: .5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child:
            needsScroll
                ? SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenHeight),
                    child: IntrinsicHeight(child: buildContent()),
                  ),
                )
                : buildContent(),
      ),
    );
  }
}
