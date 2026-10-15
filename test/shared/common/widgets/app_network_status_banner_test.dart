import 'package:dineroo_mobile/shared/common/widgets/app_network_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNetworkStatusBanner', () {
    const methodChannel = MethodChannel(
      'dev.fluttercommunity.plus/connectivity',
    );

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    testWidgets('shows offline banner when connectivity reports none', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
            if (message.method == 'check') {
              return ['none'];
            }
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(home: AppNetworkStatusBanner(child: const SizedBox())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Connexion Internet perdue'), findsOneWidget);
    });

    testWidgets('does not render banner when online', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (message) async {
            if (message.method == 'check') {
              return ['wifi'];
            }
            return null;
          });

      await tester.pumpWidget(
        MaterialApp(home: AppNetworkStatusBanner(child: const SizedBox())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Connexion Internet perdue'), findsNothing);
      expect(find.text('Connexion rétablie'), findsNothing);
    });
  });
}
