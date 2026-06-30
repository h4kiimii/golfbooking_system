import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../theme/app_theme.dart';
import 'widgets/app_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.language, required this.onNavigate});

  final AppLanguage language;
  final ValueChanged<int> onNavigate;

  String _text(String english, String malay) {
    return language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(
        _text('Book Driving Range', 'Tempah Driving Range'),
        Icons.sports_golf_rounded,
        1,
      ),
      _MenuItem(
        _text('Book Golf Trainer', 'Tempah Jurulatih Golf'),
        Icons.school_rounded,
        1,
      ),
      _MenuItem(
        _text('My Bookings', 'Tempahan Saya'),
        Icons.receipt_long_rounded,
        2,
      ),
      _MenuItem(
        _text('Contact & Feedback', 'Hubungi & Maklum Balas'),
        Icons.feedback_rounded,
        3,
      ),
      _MenuItem(_text('About', 'Tentang'), Icons.info_rounded, 4),
      _MenuItem(_text('My Profile', 'Profil Saya'), Icons.person_rounded, 5),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(
                width: 112,
                height: 82,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _text(
                  'Welcome to UPSI Driving Range',
                  'Selamat Datang ke UPSI Driving Range',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _text(
                  'Reserve driving range slots, book trainers, and manage your bookings in one simple app.',
                  'Tempah slot driving range, jurulatih golf, dan urus tempahan anda dalam satu aplikasi.',
                ),
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _text('Main Menu', 'Menu Utama'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
