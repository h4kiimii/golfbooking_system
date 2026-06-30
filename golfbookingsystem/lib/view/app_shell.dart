import 'package:flutter/material.dart';

import '../model/booking.dart';
import '../model/driving_range_package.dart';
import '../model/feedback_message.dart';
import '../model/trainer.dart';
import '../model/user_profile.dart';
import '../services/app_data_service.dart';
import '../services/app_language.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import 'about_page.dart';
import 'booking_page.dart';
import 'contact_page.dart';
import 'home_page.dart';
import 'my_bookings_page.dart';
import 'profile_page.dart';
import 'widgets/app_background.dart';
import 'widgets/app_logo.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.profile,
    required this.packages,
    required this.trainers,
    required this.bookings,
    required this.teeTimes,
    required this.drivingRangeLanes,
    required this.paymentMethods,
    this.contactSettings = const ContactSettings(),
    this.backgroundUrl,
    this.appDataWarnings = const [],
    required this.feedbackMessages,
    required this.currentPassword,
    required this.onPasswordChanged,
    required this.onDataChanged,
    required this.onProfileUpdated,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final UserProfile profile;
  final List<DrivingRangePackage> packages;
  final List<Trainer> trainers;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final List<String> drivingRangeLanes;
  final List<String> paymentMethods;
  final ContactSettings contactSettings;
  final String? backgroundUrl;
  final List<String> appDataWarnings;
  final List<FeedbackMessage> feedbackMessages;
  final String currentPassword;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onDataChanged;
  final ValueChanged<UserProfile> onProfileUpdated;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool _isLoadingBookings = false;

  BookingService? get _bookingService {
    try {
      return BookingService();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSupabaseBookings();
  }

  Future<void> _loadSupabaseBookings() async {
    final service = _bookingService;
    if (service == null) return;

    setState(() => _isLoadingBookings = true);
    try {
      final bookings = await service.loadMyBookings();
      if (!mounted) return;
      setState(() {
        widget.bookings
          ..clear()
          ..addAll(bookings);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load Supabase bookings: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  Future<void> _addBooking(Booking booking) async {
    final service = _bookingService;
    try {
      final savedBooking = service == null
          ? booking
          : await service.createBooking(booking);
      if (!mounted) return;
      setState(() {
        widget.bookings.insert(0, savedBooking);
        _previousIndex = _currentIndex;
        _currentIndex = 2;
      });
      widget.onDataChanged();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save booking to Supabase: $error')),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final service = _bookingService;
    try {
      await service?.updateStatus(bookingId, BookingStatus.cancelled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel booking in Supabase: $error')),
      );
      return;
    }

    setState(() {
      final index = widget.bookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (index != -1) {
        widget.bookings[index] = widget.bookings[index].copyWith(
          status: BookingStatus.cancelled,
        );
      }
    });
    widget.onDataChanged();
  }

  Future<void> _deleteBooking(String bookingId) async {
    final service = _bookingService;
    try {
      await service?.deleteBooking(bookingId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete booking in Supabase: $error')),
      );
      return;
    }

    setState(() {
      widget.bookings.removeWhere((booking) => booking.id == bookingId);
    });
    widget.onDataChanged();
  }

  void _rescheduleBooking(String bookingId, DateTime date, String time) {
    final service = _bookingService;
    service
        ?.rescheduleBooking(bookingId: bookingId, date: date, time: time)
        .catchError((Object error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not reschedule booking in Supabase: $error'),
            ),
          );
        });

    setState(() {
      final index = widget.bookings.indexWhere(
        (booking) => booking.id == bookingId,
      );
      if (index != -1) {
        widget.bookings[index] = widget.bookings[index].copyWith(
          date: date,
          time: time,
          status: BookingStatus.rescheduled,
        );
      }
    });
    widget.onDataChanged();
  }

  void _submitFeedback(FeedbackMessage feedback) {
    final service = _bookingService;
    service?.submitFeedback(feedback).catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save feedback to Supabase: $error')),
      );
    });

    widget.feedbackMessages.insert(0, feedback);
    widget.onDataChanged();
  }

  String _text(String english, String malay) {
    return widget.language == AppLanguage.malay ? malay : english;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(language: widget.language, onNavigate: _goToTab),
      BookingPage(
        packages: widget.packages,
        trainers: widget.trainers,
        bookings: widget.bookings,
        teeTimes: widget.teeTimes,
        drivingRangeLanes: widget.drivingRangeLanes,
        paymentMethods: widget.paymentMethods,
        onBookingCreated: _addBooking,
      ),
      MyBookingsPage(
        bookings: widget.bookings,
        teeTimes: widget.teeTimes,
        drivingRangeLanes: widget.drivingRangeLanes,
        onCancel: _cancelBooking,
        onDelete: _deleteBooking,
        onReschedule: _rescheduleBooking,
      ),
      ContactPage(
        profile: widget.profile,
        contactSettings: widget.contactSettings,
        onFeedbackSubmitted: _submitFeedback,
        language: widget.language,
      ),
      AboutPage(language: widget.language),
      ProfilePage(
        profile: widget.profile,
        currentPassword: widget.currentPassword,
        onPasswordChanged: widget.onPasswordChanged,
        onProfileUpdated: widget.onProfileUpdated,
        onLogout: widget.onLogout,
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const AppBarBrand()),
      body: AppBackground(
        imageUrl: widget.backgroundUrl,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final movingForward = _currentIndex >= _previousIndex;
              final offset = movingForward ? 0.035 : -0.035;
              final slideAnimation = Tween<Offset>(
                begin: Offset(offset, 0),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnimation, child: child),
              );
            },
            child: _isLoadingBookings
                ? const Center(child: CircularProgressIndicator())
                : KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: Column(
                      children: [
                        if (widget.appDataWarnings.isNotEmpty)
                          _AppDataWarningBanner(
                            warnings: widget.appDataWarnings,
                          ),
                        Expanded(child: pages[_currentIndex]),
                      ],
                    ),
                  ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGreen.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _goToTab,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: _text('Home', 'Utama'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.event_available_rounded),
              label: _text('Booking', 'Tempahan'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              label: _text('My Bookings', 'Tempahan Saya'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.contact_mail_rounded),
              label: _text('Feedback', 'Maklum Balas'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.info_rounded),
              label: _text('About', 'Tentang'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: _text('Profile', 'Profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDataWarningBanner extends StatelessWidget {
  const _AppDataWarningBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  warnings.first,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (warnings.length > 1)
                Text(
                  '+${warnings.length - 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
