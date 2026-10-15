import 'package:dineroo_mobile/shared/common/constants/constants.dart';
import 'package:dineroo_mobile/shared/enums/file_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Retrieves API base URL from environment variable
/// or defaults based on platform and build mode
String getApiBaseUrl() {
  final configuredBaseUrl = dotenv.env['API_BASE_URL']?.trim();
  if (configuredBaseUrl != null && configuredBaseUrl.isNotEmpty) {
    return configuredBaseUrl;
  }

  if (kReleaseMode) {
    return 'https://api.dineroo.africa';
  }

  throw StateError(
    'API_BASE_URL is missing. Run `make run dev` or set API_BASE_URL in .env.',
  );
}

String getProfilePhotoUrl(String userId) {
  final uri = Uri.parse('${getApiBaseUrl()}${ApiConstants.userDownloadFile(userId)}')
      .replace(queryParameters: {'fileType': FileType.profilePhoto.value});
  return uri.toString();
}
