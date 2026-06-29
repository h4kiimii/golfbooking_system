import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({
    super.key,
    this.imagePath,
    this.radius = 34,
    this.icon = Icons.person_rounded,
  });

  final String? imagePath;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.lightGreen,
      foregroundColor: AppTheme.darkGreen,
      child: path == null || path.isEmpty
          ? Icon(icon, size: radius)
          : ClipOval(
              child: path.startsWith('http')
                  ? Image.network(
                      path,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(icon, size: radius),
                    )
                  : Image.asset(
                      path,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(icon, size: radius),
                    ),
            ),
    );
  }
}
