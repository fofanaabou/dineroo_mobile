import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dineroo_mobile/shared/repositories/user_repository.dart';
import 'package:dineroo_mobile/shared/services/user/user_service.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserViewModel', () {
    late _FakeUserService service;
    late UserViewModel viewModel;

    setUp(() {
      service = _FakeUserService();
      viewModel = UserViewModel(UserRepository(service: service));
    });

    test('creates a user and toggles loading', () async {
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.createUser({'firstName': 'Aminata'});

      expect(service.createdUsers, [
        {'firstName': 'Aminata'},
      ]);
      expect(loadingStates, [true, false]);
    });

    test('converts cancelled user creation to a clear exception', () async {
      service.createUserException = _cancelledDioException();

      expect(
        () => viewModel.createUser({'firstName': 'Aminata'}),
        throwsA(predicate((Object e) => e.toString().contains('cancelled'))),
      );
    });

    test('uploads a file with cancellation handling', () async {
      final file = File('test_resources/identity.png');

      await viewModel.uploadUserFile(
        userId: 'user-1',
        file: file,
        fileType: 'IDENTITY',
      );

      expect(service.uploadedUserId, 'user-1');
      expect(service.uploadedFileType, 'IDENTITY');

      service.uploadFileException = _cancelledDioException();
      expect(
        () => viewModel.uploadUserFile(
          userId: 'user-1',
          file: file,
          fileType: 'IDENTITY',
        ),
        throwsA(predicate((Object e) => e.toString().contains('cancelled'))),
      );
    });

    test('updates and reads user data through the repository', () async {
      service.userByPhone = {'id': 'user-1', 'telephone': '620000000'};

      await viewModel.updateUser(
        userId: 'user-1',
        firstName: 'Aminata',
        lastName: 'Diallo',
        telephone: '620000000',
      );
      final user = await viewModel.getUserByPhone('620000000');

      expect(service.updatedUserId, 'user-1');
      expect(user['id'], 'user-1');
      expect(viewModel.isLoading, isFalse);
    });

    test('sends and validates verification codes', () async {
      await viewModel.sendVerificationCode(
        userId: 'user-1',
        telephone: '620000000',
      );
      await viewModel.validateCode(userId: 'user-1', code: '1234');

      expect(service.sentCodeUserId, 'user-1');
      expect(service.validatedCode, '1234');
      expect(viewModel.isLoading, isFalse);
    });

    test('resets pin by phone and id', () async {
      await viewModel.resetCodePinWithPhone(
        telephone: '620000000',
        codePin: '1111',
      );
      await viewModel.resetCodePinWithId(userId: 'user-1', codePin: '2222');

      expect(service.resetPhonePin, '1111');
      expect(service.resetIdPin, '2222');
      expect(viewModel.isLoading, isFalse);
    });

    test('cancel methods clear loading on a microtask', () async {
      viewModel.setLoading(true);
      viewModel.cancelCreateUser();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoading, isFalse);

      viewModel.setLoading(true);
      viewModel.cancelUploadUserFile();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isLoading, isFalse);
    });
  });
}

class _FakeUserService extends UserService {
  final List<Map<String, dynamic>> createdUsers = [];
  DioException? createUserException;
  DioException? uploadFileException;
  String? uploadedUserId;
  String? uploadedFileType;
  String? updatedUserId;
  Map<String, dynamic> userByPhone = const {};
  String? sentCodeUserId;
  String? validatedCode;
  String? resetPhonePin;
  String? resetIdPin;

  @override
  Future<void> createUser(
    Map<String, dynamic> userData, {
    CancelToken? cancelToken,
  }) async {
    final exception = createUserException;
    if (exception != null) throw exception;
    createdUsers.add(userData);
  }

  @override
  Future<void> uploadUserFile({
    required String userId,
    required File file,
    required String fileType,
    CancelToken? cancelToken,
  }) async {
    final exception = uploadFileException;
    if (exception != null) throw exception;
    uploadedUserId = userId;
    uploadedFileType = fileType;
  }

  @override
  Future<void> updateUser({
    required String userId,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    updatedUserId = userId;
  }

  @override
  Future<Map<String, dynamic>> getUserByPhone(String telephone) async {
    return userByPhone;
  }

  @override
  Future<void> sendVerificationCode({
    required String userId,
    required String telephone,
  }) async {
    sentCodeUserId = userId;
  }

  @override
  Future<void> validateCode({
    required String userId,
    required String code,
  }) async {
    validatedCode = code;
  }

  @override
  Future<void> resetCodePinWithPhone({
    required String telephone,
    required String codePin,
  }) async {
    resetPhonePin = codePin;
  }

  @override
  Future<void> resetCodePinWithId({
    required String userId,
    required String codePin,
  }) async {
    resetIdPin = codePin;
  }
}

DioException _cancelledDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/users'),
    type: DioExceptionType.cancel,
  );
}
