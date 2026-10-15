import 'package:intl/intl.dart';
import 'package:dineroo_mobile/shared/common/constants/currency_constants.dart';

String formatPrice(num price, {String currency = appCurrency}) {
  return '${NumberFormat.decimalPattern('fr_FR').format(price)} $currency';
}
