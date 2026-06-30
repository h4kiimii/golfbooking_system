import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/dummy_data.dart';
import 'model/auth_session.dart';
import 'model/booking.dart';
import 'model/driving_range_package.dart';
import 'model/feedback_message.dart';
import 'model/trainer.dart';
import 'model/user_profile.dart';
import 'services/account_service.dart';
import 'services/app_language.dart';
import 'services/app_data_service.dart';
import 'theme/app_theme.dart';
import 'view/auth_page.dart';
import 'view/app_shell.dart';
import 'view/widgets/app_background.dart';
import 'view/widgets/app_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gzbctvkbwwvffnvvwwzg.supabase.co',
    publishableKey: 'sb_publishable_zFa_bjtrPuGMKFfxY5Y7wg_gXnbeLWk',
  );
  runApp(const GolfDrivingRangeBookingApp());
}

class GolfDrivingRangeBookingApp extends StatefulWidget {
  const GolfDrivingRangeBookingApp({super.key});

  @override
  State<GolfDrivingRangeBookingApp> createState() =>
      _GolfDrivingRangeBookingAppState();
}

class _GolfDrivingRangeBookingAppState
    extends State<GolfDrivingRangeBookingApp> {
  static const _darkModeKey = 'dark_mode_enabled';
  static const _languageKey = 'app_language';
  static const _loginSplashDuration = Duration(milliseconds: 1800);

  UserProfile? _profile;
  String? _sessionPassword;
  bool _isDarkMode = false;
  AppLanguage _language = AppLanguage.english;
  bool _showLoginSplash = true;
  Timer? _loginSplashTimer;
  final List<DrivingRangePackage> _packages = List.of(
    DummyData.drivingRangePackages,
  );
  final List<Trainer> _trainers = List.of(DummyData.trainers);
  final List<Booking> _bookings = List.of(DummyData.sampleBookings);
  final List<String> _teeTimes = List.of(DummyData.availableTimes);
  final List<String> _drivingRangeLanes = List.of(DummyData.drivingRangeLanes);
  final List<String> _paymentMethods = List.of(DummyData.paymentMethods);
  final List<FeedbackMessage> _feedbackMessages = [];
  ContactSettings _contactSettings = const ContactSettings();
  AppBackgroundSettings _backgroundSettings = const AppBackgroundSettings();

  @override
  void initState() {
    super.initState();
    _loginSplashTimer = Timer(_loginSplashDuration, () {
      if (!mounted) return;
      setState(() => _showLoginSplash = false);
    });
    _loadThemeMode();
    _loadLanguage();
    _loadSupabaseAppData();
  }

  @override
  void dispose() {
    _loginSplashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isDarkMode = preferences.getBool(_darkModeKey) ?? false;
    });
  }

  Future<void> _handleThemeChanged(bool enabled) async {
    setState(() => _isDarkMode = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
  }

  Future<void> _loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_languageKey);
    if (!mounted) return;
    setState(() {
      _language = value == AppLanguage.malay.name
          ? AppLanguage.malay
          : AppLanguage.english;
    });
  }

  Future<void> _handleLanguageChanged(AppLanguage language) async {
    setState(() => _language = language);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language.name);
  }

  Future<void> _loadSupabaseAppData() async {
    try {
      final data = await AppDataService().load();
      if (!mounted) return;
      setState(() {
        _packages
          ..clear()
          ..addAll(data.packages);
        _trainers
          ..clear()
          ..addAll(data.trainers);
        _teeTimes
          ..clear()
          ..addAll(data.teeTimes);
        _drivingRangeLanes
          ..clear()
          ..addAll(data.drivingRangeLanes);
        _paymentMethods
          ..clear()
          ..addAll(data.paymentMethods);
        _contactSettings = data.contactSettings;
        _backgroundSettings = data.backgroundSettings;
      });
    } catch (_) {
      // Keep bundled fallback data when shared app setup data is unavailable.
    }
  }

  void _handleLogin(AuthSession session) {
    setState(() {
      _profile = session.profile;
      _sessionPassword = session.password;
    });
    _loadSupabaseAppData();
  }

  void _handleProfileUpdated(UserProfile profile) {
    setState(() => _profile = profile);
    try {
      AccountService().saveProfile(profile).catchError((Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile to Supabase: $error')),
        );
      });
    } catch (_) {}
  }

  void _handleLogout() {
    try {
      AccountService().signOut();
    } catch (_) {}
    setState(() {
      _profile = null;
      _sessionPassword = null;
    });
  }

  void _handlePasswordChanged(String newPassword) {
    setState(() => _sessionPassword = newPassword);
  }

  void _handleDataChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPSI Driving Range',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _profile == null && _showLoginSplash
          ? _LoginSplashPage(backgroundUrl: _backgroundSettings.loginUrl)
          : _profile == null
          ? AuthPage(
              backgroundUrl: _backgroundSettings.loginUrl,
              language: _language,
              onLanguageChanged: _handleLanguageChanged,
              onAuthenticated: _handleLogin,
            )
          : AppShell(
              profile: _profile!,
              packages: _packages,
              trainers: _trainers,
              bookings: _bookings,
              teeTimes: _teeTimes,
              drivingRangeLanes: _drivingRangeLanes,
              paymentMethods: _paymentMethods,
              contactSettings: _contactSettings,
              backgroundUrl: _backgroundSettings.appUrl,
              feedbackMessages: _feedbackMessages,
              currentPassword: _sessionPassword!,
              onPasswordChanged: _handlePasswordChanged,
              onDataChanged: _handleDataChanged,
              onProfileUpdated: _handleProfileUpdated,
              onLogout: _handleLogout,
              isDarkMode: _isDarkMode,
              onThemeChanged: _handleThemeChanged,
              language: _language,
              onLanguageChanged: _handleLanguageChanged,
            ),
    );
  }
}

class _LoginSplashPage extends StatelessWidget {
  const _LoginSplashPage({required this.backgroundUrl});

  final String? backgroundUrl;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1210),
        body: AppBackground(
          imageUrl: backgroundUrl,
          forceDarkOverlay: true,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(
                  width: 190,
                  height: 132,
                  backgroundColor: AppTheme.lightGreen,
                ),
                SizedBox(height: 24),
                Text(
                  'UPSI Driving Range',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Booking System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFEAF4EF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
