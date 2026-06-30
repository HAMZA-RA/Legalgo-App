import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legalgo_mobile/app/legalgo_app.dart';

void main() {
  testWidgets('LegalGo app builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LegalGoApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
