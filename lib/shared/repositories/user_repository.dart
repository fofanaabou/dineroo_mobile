import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class UserRepository {
  final UserService _service;

  UserRepository({required UserService service}) : _service = service;

  Future<void> createUser(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _service.createUser(userData, cancelToken: cancelToken);
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('User creation cancelled by user: ${e.message}');
        rethrow;
      }
      logger.e('Failed to create user', error: e, stackTrace: stack);
      throw Exception('Failed to create user');
    }
  }

  Future<void> uploadUserFile({
    required String userId,
    required File file,
    required String fileType,
    CancelToken? cancelToken,
  }) async {
    try {
      await _service.uploadUserFile(
        userId: userId,
        file: file,
        fileType: fileType,
        cancelToken: cancelToken,
      );
    } on DioException catch (e, stack) {
      if (CancelToken.isCancel(e)) {
        logger.w('User file upload cancelled by user: ${e.message}');
        rethrow;
      }
      logger.e('Failed to upload user file', error: e, stackTrace: stack);
      throw Exception('Failed to upload user file');
    }
  }

  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    try {
      await _service.updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        telephone: telephone,
      );
    } catch (e, stack) {
      logger.e('Failed to update user', error: e, stackTrace: stack);
      throw Exception('Failed to update user');
    }
  }

  Future<Map<String, dynamic>> getUserByPhone(String telephone) async {
    try {
      return await _service.getUserByPhone(telephone);
    } catch (e, stack) {
      logger.e('Failed to get user by phone', error: e, stackTrace: stack);
      throw Exception('Failed to get user by phone');
    }
  }

  Future<void> sendVerificationCode({
    required String userId,
    required String telephone,
  }) async {
    try {
      await _service.sendVerificationCode(userId: userId, telephone: telephone);
    } catch (e, stack) {
      logger.e('Failed to send code', error: e, stackTrace: stack);
      throw Exception('Failed to send code');
    }
  }

  Future<void> validateCode({
    required String userId,
    required String code,
  }) async {
    try {
      await _service.validateCode(userId: userId, code: code);
    } catch (e, stack) {
      logger.e('Failed to validate code', error: e, stackTrace: stack);
      throw Exception('Failed to validate code');
    }
  }

  Future<void> resetCodePinWithPhone({
    required String telephone,
    required String codePin,
  }) async {
    await _service.resetCodePinWithPhone(
      telephone: telephone,
      codePin: codePin,
    );
  }

  Future<void> resetCodePinWithId({
    required String userId,
    required String codePin,
  }) async {
    await _service.resetCodePinWithId(userId: userId, codePin: codePin);
  }
}
