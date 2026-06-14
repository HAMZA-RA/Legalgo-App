import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/widgets/legalgo_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LegalGoMark(),
            SizedBox(height: 28),
            SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
