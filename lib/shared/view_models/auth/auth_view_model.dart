import 'dart:async';

import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/realtime/stomp_realtime_service.dart';
import 'package:dineroo_mobile/shared/services/notification/push_notification_service.dart';
import 'package:dineroo_mobile/shared/services/notification/notification_sound_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/driver/view_models/driver_home_view_model.dart';
import 'package:dineroo_mobile/shared/enums/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dineroo_mobile/shared/repositories/auth_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/location_helper.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CancelToken? _loginCancelToken;
  CancelToken? _verifyCodeCancelToken;

  AuthViewModel(this._repository);

  Future<void> verifyCode(
    String code, {
    required BuildContext context,
    CancelToken? cancelToken,
  }) async {
    setLoading(true);
    _verifyCodeCancelToken = cancelToken ?? CancelToken();

    try {
      await _repository.verifyCode(code, cancelToken: _verifyCodeCancelToken);
      if (!context.mounted) return;
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      if (currentUser != null) {
        await context.read<CartViewModel>().openUserCartBox(currentUser.id);
        await PushNotificationService().syncUserDeviceToken(currentUser.id);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Code verification cancelled');
      } else {
        rethrow;
      }
    } finally {
      setLoading(false);
      _verifyCodeCancelToken = null;
    }
  }

  Future<void> login(
    Map<String, dynamic> userData, {
    required BuildContext context,
    CancelToken? cancelToken,
  }) async {
    setLoading(true);
    _loginCancelToken = cancelToken ?? CancelToken();

    try {
      final tokens = await _repository.login(
        userData,
        cancelToken: _loginCancelToken,
      );

      if (!context.mounted) return;
      await storeLocationIfGranted(context);

      if (!context.mounted) return;
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      if (currentUser != null) {
        await context.read<CartViewModel>().openUserCartBox(currentUser.id);

        final accessToken = tokens['accessToken'] ?? tokens['token'];
        if (accessToken != null && accessToken.toString().isNotEmpty) {
          final currentUser = _repository.currentUserViewModel.currentUser;

          if (currentUser != null) {
            logger.i(
              '[RT] Connecting to WebSocket after login '
              '(${currentUser.role}, ${currentUser.organization?.id ?? "no org"})...',
            );

            await StompRealtimeService().connect(
              token: accessToken,
              userRole: currentUser.role,
              restaurantId: currentUser.organization?.id,
              userId: currentUser.id,
            );

            _syncDeviceTokenAfterAuth(currentUser.id);

            if (currentUser.userRoleEnum == UserRole.driver &&
                context.mounted) {
              context.read<DriverHomeViewModel>().resetDriverSessionLocal();
            }
          } else {
            logger.w('[RT] Cannot connect WebSocket — user not loaded yet');
          }
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Login cancelled');
      } else {
        rethrow;
      }
    } finally {
      setLoading(false);
      _loginCancelToken = null;
    }
  }

  Future<void> loadUserFromToken(BuildContext context) async {
    setLoading(true);
    try {
      final token = await _repository.loadUserFromToken();
      if (token != null) {
        await AuthInterceptor.cacheAccessToken(token);
      }

      if (!context.mounted) return;
      await storeLocationIfGranted(context);

      if (token != null && token.toString().isNotEmpty) {
        final currentUser = _repository.currentUserViewModel.currentUser;

        if (currentUser != null) {
          logger.i(
            '[RT] Connecting to WebSocket from saved token '
            '(${currentUser.role}, ${currentUser.organization?.id ?? "no org"})...',
          );

          await StompRealtimeService().connect(
            token: token,
            userRole: currentUser.role,
            restaurantId: currentUser.organization?.id,
            userId: currentUser.id,
          );

          _syncDeviceTokenAfterAuth(currentUser.id);

          if (currentUser.userRoleEnum == UserRole.driver && context.mounted) {
            context.read<DriverHomeViewModel>().resetDriverSessionLocal();
          }
        } else {
          logger.w('[RT] Cannot connect WebSocket — user not loaded yet');
        }
      }

      if (!context.mounted) return;
      final currentUser = context.read<CurrentUserViewModel>().currentUser;
      if (currentUser != null) {
        await context.read<CartViewModel>().openUserCartBox(currentUser.id);
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final currentUser = context.read<CurrentUserViewModel>().currentUser;

      if (currentUser?.userRoleEnum == UserRole.driver) {
        await context.read<DriverHomeViewModel>().resetDriverSessionServer();
      }

      if (currentUser != null) {
        await PushNotificationService().unregisterUserDeviceToken(
          currentUser.id,
        );
        await _repository.logoutFromServer();
      }

      if (!context.mounted) return;
      await logoutLocal(context);
    } catch (e, stack) {
      logger.e('[Auth] logout failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> logoutLocal(BuildContext context) async {
    await NotificationSoundService().disposeForLogout();
    if (!context.mounted) return;
    final cartVM = context.read<CartViewModel>();
    await cartVM.closeUserCartBox();
    await cartVM.clearCart();
    cartVM.clearDeliveryAddress();
    await StompRealtimeService().disconnect();
    await _repository.logout();
    notifyListeners();
  }

  Future<bool> isAuthenticated() => _repository.isAuthenticated();

  Future<void> updateCourierStatus(String courierStatus) {
    return _repository.updateCourierStatus(courierStatus);
  }

  void _syncDeviceTokenAfterAuth(String userId) {
    unawaited(
      PushNotificationService().syncUserDeviceToken(userId).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        logger.e(
          '[Push] Device token sync after auth failed',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void cancelVerifyCode() {
    _verifyCodeCancelToken?.cancel("Code verification cancelled by user");
    Future.microtask(() => setLoading(false));
  }

  void cancelLogin() {
    _loginCancelToken?.cancel("Login cancelled by user");
    Future.microtask(() => setLoading(false));
  }
}
