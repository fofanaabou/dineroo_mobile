import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/enums/http_status_code.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_uri_builder.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';

class UserService {
  final Dio _dio;
  final Dio _publicDio;

  UserService({Dio? dio, Dio? publicDio})
    : _dio = dio ?? createDioClient(),
      _publicDio = publicDio ?? createPublicDioClient();

  Future<void> createUser(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.users);

    try {
      final response = await _publicDio.post(
        url.toString(),
        data: userData,
        options: Options(headers: {'Content-Type': 'application/json'}),
        cancelToken: cancelToken,
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'User creation failed (status code: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('Failed to create user');
      }

      logger.i('User created successfully');
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('User creation cancelled by user: ${e.message}');
        throw Exception('User creation cancelled');
      }
      logger.e('Dio error during user creation', error: e, stackTrace: stack);
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      logger.e(
        'Unknown error during user creation',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> uploadUserFile({
    required String userId,
    required File file,
    required String fileType,
    CancelToken? cancelToken,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.uploadUserFile);

    final formData = FormData.fromMap({
      'userId': userId,
      'fileName': file.path.split('/').last,
      'fileType': fileType,
      'file': await MultipartFile.fromFile(file.path),
    });

    try {
      final response = await _dio.post(
        url.toString(),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e(
          'File upload failed (status code: ${response.statusCode})',
          error: response.data,
        );
        throw Exception('File upload failed');
      }

      logger.i('User file uploaded successfully');
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('File upload cancelled by user: ${e.message}');
        throw Exception('File upload cancelled');
      }
      logger.e('Dio error during file upload', error: e, stackTrace: stack);
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      logger.e('Unknown error during file upload', error: e, stackTrace: stack);
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userById(userId));

    try {
      final response = await _dio.put(
        url.toString(),
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'telephone': telephone,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        logger.e('User update failed', error: response.data);
        throw Exception('User update failed');
      }

      logger.i('User updated successfully');
    } catch (e, stack) {
      logger.e('Error updating user', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserByPhone(String telephone) async {
    final url = ApiUriBuilder.build(ApiConstants.userByPhone(telephone));

    try {
      final response = await _publicDio.get(
        url.toString(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.ok.code) {
        throw Exception('User not found');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch user by phone: $e');
    }
  }

  Future<void> sendVerificationCode({
    required String userId,
    required String telephone,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userSendCode());

    final body = {'id': userId, 'telephone': telephone};

    try {
      final response = await _publicDio.post(
        url.toString(),
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.noContent.code) {
        logger.e('Failed to send code: ${response.statusCode}');
        throw Exception('Failed to send code');
      }

      logger.i('Code sent successfully');
    } catch (e, stack) {
      logger.e('Error sending code', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> validateCode({
    required String userId,
    required String code,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userValidateCode());

    final body = {'id': userId, 'code': code};

    try {
      final response = await _publicDio.post(
        url.toString(),
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.noContent.code) {
        logger.e('Code validation failed: ${response.statusCode}');
        throw Exception('Code validation failed');
      }

      logger.i('Code validated successfully');
    } catch (e, stack) {
      logger.e('Error validating code', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> resetCodePinWithPhone({
    required String telephone,
    required String codePin,
  }) async {
    final url = ApiUriBuilder.build(
      ApiConstants.userResetPinWithPhone(telephone),
    );
    final body = {'codePin': codePin};

    final response = await _publicDio.put(
      url.toString(),
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != HttpStatusCode.noContent.code) {
      throw Exception('Reset code PIN via téléphone échoué');
    }
  }

  Future<void> resetCodePinWithId({
    required String userId,
    required String codePin,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userResetPinWithId(userId));
    final body = {'codePin': codePin};

    final response = await _dio.put(
      url.toString(),
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode != HttpStatusCode.noContent.code) {
      throw Exception('Reset code PIN via ID échoué');
    }
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userDeviceTokens(userId));

    try {
      final response = await _dio.post(
        url.toString(),
        data: {'token': token, 'platform': platform},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.noContent.code) {
        logger.e(
          '[Push] Token registration failed for userId=$userId '
          'status=${response.statusCode} url=$url',
          error: response.data,
        );
        throw Exception('Push token registration failed');
      }

      logger.i(
        '[Push] Token registered successfully for userId=$userId url=$url',
      );
    } on DioException catch (e, stack) {
      logger.e(
        '[Push] Dio error during token registration for userId=$userId '
        'url=$url status=${e.response?.statusCode} type=${e.type} body=${e.response?.data}',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      logger.e(
        '[Push] Unknown error during device token registration for userId=$userId url=$url',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> deleteDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final url = ApiUriBuilder.build(ApiConstants.userDeviceTokens(userId));

    try {
      final response = await _dio.delete(
        url.toString(),
        data: {'token': token, 'platform': platform},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != HttpStatusCode.noContent.code) {
        logger.e(
          '[Push] Token deletion failed for userId=$userId '
          'status=${response.statusCode} url=$url',
          error: response.data,
        );
        throw Exception('Push token deletion failed');
      }

      logger.i('[Push] Token deleted successfully for userId=$userId url=$url');
    } on DioException catch (e, stack) {
      logger.e(
        '[Push] Dio error during token deletion for userId=$userId '
        'url=$url status=${e.response?.statusCode} type=${e.type} body=${e.response?.data}',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Erreur de connexion réseau ou serveur');
    } catch (e, stack) {
      logger.e(
        'Unknown error during device token deletion',
        error: e,
        stackTrace: stack,
      );
      throw Exception('Une erreur est survenue');
    }
  }
}
