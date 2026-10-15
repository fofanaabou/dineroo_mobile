import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/common/helpers/url_helper.dart';

class ApiUriBuilder {
  static Uri build(
    String path, {
    Map<String, String>? queryParameters,
    ApiContext? context,
  }) {
    final params = <String, String>{
      if (queryParameters != null) ...queryParameters,
      if (context != null) 'context': apiContextQueryValue(context),
    };

    return Uri.parse('${getApiBaseUrl()}$path').replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }
}
