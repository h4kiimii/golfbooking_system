import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'widgets/app_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem('Book Driving Range', Icons.sports_golf_rounded, 1),
      _MenuItem('Book Golf Trainer', Icons.school_rounded, 1),
      _MenuItem('My Bookings', Icons.receipt_long_rounded, 2),
      _MenuItem('Contact & Feedback', Icons.feedback_rounded, 3),
      _MenuItem('My Profile', Icons.person_rounded, 4),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.mediumGreen.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLogo(width: 112, height: 82, backgroundColor: Colors.white),
              SizedBox(height: 16),
              Text(
                'Welcome to UPSI Driving Range',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Reserve driving range slots, book trainers, and manage your bookings in one simple app.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Main Menu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...menuItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                onTap: () => onNavigate(item.tabIndex),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.darkGreen,
                  child: Icon(item.icon),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkGreen,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem(this.title, this.icon, this.tabIndex);

  final String title;
  final IconData icon;
  final int tabIndex;
}
