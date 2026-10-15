import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';

class AuthService {
  final Dio _dio;
  final Dio _publicDio;

  AuthService({Dio? dio, Dio? publicDio})
    : _dio = dio ?? createDioClient(),
      _publicDio = publicDio ?? createPublicDioClient();

  Future<Map<String, dynamic>> verifyCode(
    String code, {
    CancelToken? cancelToken,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userVerifyCode());

    try {
      final response = await _publicDio.post(
        url.toString(),
        data: {"code": code},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status < HttpStatusCode.internalServerError.code,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == HttpStatusCode.notFound.code) {
        throw Exception('Code invalide ou expiré. Demandez un nouveau code.');
      }

      if (response.statusCode == HttpStatusCode.conflict.code) {
        throw Exception(
          'Ce numéro a déjà un compte. Connectez-vous ou réinitialisez votre code PIN.',
        );
      }

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'Code verification failed (status code: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Échec de vérification du code');
      }

      logger.i('Code verified successfully');
      return response.data;
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('Code verification cancelled by user: ${e.message}');
        throw Exception('Code verification cancelled');
      }
      logger.e(
        'Dio error during code verification (status: ${e.response?.statusCode})',
        error: e,
        stackTrace: stack,
      );
      if (e.response?.data != null) {
        logger.e('Code verification response body', error: e.response?.data);
      }
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      if (e is Exception) {
        rethrow;
      }
      logger.e('Unknown error verifying code', error: e, stackTrace: stack);
      throw Exception('Une erreur est survenue');
    }
  }

  Future<Map<String, dynamic>> login(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userToken());

    try {
      final response = await _publicDio.post(
        url.toString(),
        data: userData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status != null &&
              status < HttpStatusCode.internalServerError.code,
        ),
        cancelToken: cancelToken,
      );

      final responseText = response.data.toString().toLowerCase();

      if (response.statusCode == HttpStatusCode.notFound.code) {
        throw Exception(
          'Compte introuvable. Vérifiez le numéro ou créez un compte.',
        );
      }

      if (response.statusCode == HttpStatusCode.unauthorized.code) {
        throw Exception('Numéro ou code PIN invalide.');
      }

      if (response.statusCode == HttpStatusCode.badRequest.code) {
        if (responseText.contains('account disabled')) {
          throw Exception('Ce compte est désactivé. Contactez le support.');
        }
        throw Exception('Informations de connexion invalides.');
      }

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'Login failed (status code: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Invalid credentials');
      }

      logger.i('Login successful');
      return response.data;
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('Login cancelled by user: ${e.message}');
        throw Exception('Login cancelled');
      }
      logger.e(
        'Dio error during login (status: ${e.response?.statusCode})',
        error: e,
        stackTrace: stack,
      );
      if (e.response?.data != null) {
        logger.e('Login response body', error: e.response?.data);
      }
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      if (e is Exception) {
        rethrow;
      }
      logger.e('Unknown error during login', error: e, stackTrace: stack);
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> logout() async {
    final url = ApiUriBuilder.build(ApiConstants.userLogout());

    try {
      final response = await _dio.post(
        url.toString(),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != HttpStatusCode.noContent.code) {
        logger.w('Server logout failed (status code: ${response.statusCode})');
      }
    } on DioException catch (e, stack) {
      logger.e('Dio error during logout', error: e, stackTrace: stack);
    }
  }
}
