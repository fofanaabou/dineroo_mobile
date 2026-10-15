import 'package:dio/dio.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/shared/common/helpers/user_role_helper.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/services/auth/auth_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_role_view_model.dart';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepository {
  final AuthService _authService;
  final CurrentUserViewModel _currentUserViewModel;
  final UserRoleViewModel _userRoleViewModel;

  AuthRepository(
    this._authService,
    this._currentUserViewModel,
    this._userRoleViewModel,
  );

  CurrentUserViewModel get currentUserViewModel => _currentUserViewModel;
  UserRoleViewModel get userRoleViewModel => _userRoleViewModel;

  Future<Map<String, dynamic>> verifyCode(
    String code, {
    CancelToken? cancelToken,
  }) async {
    final data = await _authService.verifyCode(code, cancelToken: cancelToken);
    await _handleAuthData(data);
    return data;
  }

  Future<Map<String, dynamic>> login(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    final data = await _authService.login(userData, cancelToken: cancelToken);
    await _handleAuthData(data);
    return data;
  }

  Future<String?> loadUserFromToken() async {
    final authBox = await Hive.openBox('auth');
    final accessToken = authBox.get('accessToken');
    final isTemporaryPin = authBox.get('isTemporaryPin') == true;
    final courierStatus = authBox.get('courierStatus')?.toString();

    if (accessToken is String && accessToken.isNotEmpty) {
      final user = setUserFromToken(
        accessToken,
        isTemporaryPin: isTemporaryPin,
        courierStatus: courierStatus,
      );
      _setUserRole(user);
      return accessToken;
    }
    return null;
  }

  Future<void> _handleAuthData(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] ?? '';
    final refreshToken = data['refreshToken'] ?? '';
    final idToken = data['idToken'] ?? '';
    final isTemporaryPin =
        (data['temporaryPin'] ?? data['isTemporaryPin']) == true;
    final courierStatus = data['courierStatus']?.toString();
    await _persistTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      isTemporaryPin: isTemporaryPin,
      courierStatus: courierStatus,
    );
    await AuthInterceptor.cacheAccessToken(accessToken);

    final user = setUserFromToken(
      accessToken,
      isTemporaryPin: isTemporaryPin,
      courierStatus: courierStatus,
    );
    _setUserRole(user);
  }

  Future<void> _persistTokens({
    required String accessToken,
    required String refreshToken,
    String idToken = '',
    bool isTemporaryPin = false,
    String? courierStatus,
  }) async {
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', accessToken);
    await authBox.put('refreshToken', refreshToken);
    await authBox.put('idToken', idToken);
    await authBox.put('isTemporaryPin', isTemporaryPin);
    if (courierStatus == null || courierStatus.isEmpty) {
      await authBox.delete('courierStatus');
    } else {
      await authBox.put('courierStatus', courierStatus);
    }
  }

  User setUserFromToken(
    String accessToken, {
    bool isTemporaryPin = false,
    String? courierStatus,
  }) {
    final decodedToken = JwtDecoder.decode(accessToken);
    final user = User.fromToken(
      decodedToken,
    ).copyWith(isTemporaryPin: isTemporaryPin, courierStatus: courierStatus);

    _currentUserViewModel.setUser(user);
    return user;
  }

  void _setUserRole(User user) {
    final userRole = parseUserRole(user.role);
    _userRoleViewModel.setRole(userRole);
  }

  Future<bool> isAuthenticated() async {
    final authBox = await Hive.openBox('auth');
    final accessToken = authBox.get('accessToken');
    return accessToken != null && accessToken.toString().isNotEmpty;
  }

  Future<String?> getStoredAccessToken() async {
    final authBox = await Hive.openBox('auth');
    final token = authBox.get('accessToken');
    return token is String && token.isNotEmpty ? token : null;
  }

  Future<String?> getStoredRefreshToken() async {
    final authBox = await Hive.openBox('auth');
    final token = authBox.get('refreshToken');
    return token is String && token.isNotEmpty ? token : null;
  }

  Future<String?> getStoredIdToken() async {
    final authBox = await Hive.openBox('auth');
    final token = authBox.get('idToken');
    return token is String && token.isNotEmpty ? token : null;
  }

  Future<void> updateAccessToken(String accessToken) async {
    final authBox = await Hive.openBox('auth');
    await authBox.put('accessToken', accessToken);
  }

  Future<void> updateRefreshToken(String refreshToken) async {
    final authBox = await Hive.openBox('auth');
    await authBox.put('refreshToken', refreshToken);
  }

  Future<void> updateCourierStatus(String courierStatus) async {
    final authBox = await Hive.openBox('auth');
    await authBox.put('courierStatus', courierStatus);

    final currentUser = _currentUserViewModel.currentUser;
    if (currentUser != null) {
      _currentUserViewModel.setUser(
        currentUser.copyWith(courierStatus: courierStatus),
      );
    }
  }

  Future<void> logoutFromServer() async {
    await _authService.logout();
  }

  Future<void> logout() async {
    final authBox = await Hive.openBox('auth');
    await authBox.clear();
    await AuthInterceptor.clearCachedToken();
    _currentUserViewModel.clear();
    _userRoleViewModel.clear();
  }
}
