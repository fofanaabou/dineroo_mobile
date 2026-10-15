import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

const _silenceLogs = bool.fromEnvironment('DINEROO_SILENCE_LOGS');

final logger = Logger(
  level: kReleaseMode || _silenceLogs ? Level.off : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);
