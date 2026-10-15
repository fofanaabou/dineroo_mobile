import 'package:dineroo_mobile/shared/views/auth/whoiam_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders app name and role selection buttons', (tester) async {
    await tester.pumpWidget(MaterialApp(home: WhoiamView()));
    await tester.pump();

    expect(find.text('Dineroo'), findsOneWidget);
    expect(find.text('Qui \u00eates-vous ?'), findsOneWidget);
    expect(find.text('JE SUIS UN CLIENT'), findsOneWidget);
    expect(find.text('JE SUIS UN LIVREUR'), findsOneWidget);
    expect(find.text('ESPACE RESTAURANT'), findsOneWidget);
  });
}
