import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 64,
    this.height = 50,
    this.backgroundColor = Colors.transparent,
  });

  final double width;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(height * 0.04),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height * 0.18),
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.sports_golf_rounded, color: AppTheme.darkGreen),
      ),
    );
  }
}

class AppBarBrand extends StatelessWidget {
  const AppBarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(width: 42, height: 34),
        SizedBox(width: 8),
        Flexible(child: Text('UPSI Driving Range')),
      ],
    );
  }
}
