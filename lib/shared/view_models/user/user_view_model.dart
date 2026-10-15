import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:flutter/material.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CancelToken? _createUserCancelToken;
  CancelToken? _uploadFileCancelToken;

  UserViewModel(this._repository);

  Future<void> createUser(Map<String, dynamic> userData) async {
    setLoading(true);
    _createUserCancelToken = CancelToken();

    try {
      await _repository.createUser(
        userData,
        cancelToken: _createUserCancelToken,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('User creation cancelled');
      } else {
        rethrow;
      }
    } finally {
      setLoading(false);
      _createUserCancelToken = null;
    }
  }

  Future<void> uploadUserFile({
    required String userId,
    required File file,
    required String fileType,
  }) async {
    setLoading(true);
    _uploadFileCancelToken = CancelToken();

    try {
      await _repository.uploadUserFile(
        userId: userId,
        file: file,
        fileType: fileType,
        cancelToken: _uploadFileCancelToken,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('File upload cancelled');
      } else {
        rethrow;
      }
    } finally {
      setLoading(false);
      _uploadFileCancelToken = null;
    }
  }

  void cancelCreateUser() {
    _createUserCancelToken?.cancel('User creation cancelled');
    Future.microtask(() => setLoading(false));
  }

  void cancelUploadUserFile() {
    _uploadFileCancelToken?.cancel('File upload cancelled');
    Future.microtask(() => setLoading(false));
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        telephone: telephone,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUserByPhone(String telephone) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _repository.getUserByPhone(telephone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationCode({
    required String userId,
    required String telephone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.sendVerificationCode(
        userId: userId,
        telephone: telephone,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> validateCode({
    required String userId,
    required String code,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.validateCode(userId: userId, code: code);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetCodePinWithPhone({
    required String telephone,
    required String codePin,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.resetCodePinWithPhone(
        telephone: telephone,
        codePin: codePin,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetCodePinWithId({
    required String userId,
    required String codePin,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.resetCodePinWithId(userId: userId, codePin: codePin);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
