import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';

class AdminSplashScreen extends StatelessWidget {
  const AdminSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: BrandColors.plum,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scales down rather than clipping on a very narrow phone.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: BrandLogo(
                  height: 56,
                  showAdminTag: true,
                  textColor: BrandColors.creamText,
                ),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: BrandColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
