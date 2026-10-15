import 'package:dineroo_mobile/customer/models/domain/wallet.dart';
import 'package:dineroo_mobile/customer/models/dto/wallet_response_dto.dart';
import 'package:dineroo_mobile/customer/services/wallet/wallet_service.dart';

class WalletRepository {
  final WalletService _service;

  WalletRepository({required WalletService service}) : _service = service;

  Future<Wallet> getWallet(String customerId) async {
    final json = await _service.getWallet(customerId);
    return WalletResponseDto.fromJson(json).toDomain();
  }
}
