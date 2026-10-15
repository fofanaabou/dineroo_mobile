import 'package:flutter/material.dart';
import 'package:dineroo_mobile/customer/models/domain/wallet.dart';
import 'package:dineroo_mobile/customer/repositories/wallet_repository.dart';
import 'package:dineroo_mobile/shared/common/config/logger.dart';

class WalletViewModel extends ChangeNotifier {
  final WalletRepository _repo;

  WalletViewModel(this._repo);

  Wallet? wallet;
  String? error;
  bool isLoading = false;

  Future<Wallet> getWallet(String customerId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final loadedWallet = await _repo.getWallet(customerId);
      wallet = loadedWallet;
      return loadedWallet;
    } catch (e, stack) {
      error = e.toString();
      logger.e('[WALLET][VM] get failed', error: e, stackTrace: stack);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
