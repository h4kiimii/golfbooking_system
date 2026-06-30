import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbookingsystem/main.dart';
import 'package:golfbookingsystem/model/booking.dart';
import 'package:golfbookingsystem/view/widgets/slot_availability.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpAppPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const GolfDrivingRangeBookingApp());
  await tester.pump(const Duration(milliseconds: 1900));
}

void main() {
  testWidgets('shows login screen first', (tester) async {
    await pumpAppPastSplash(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('UPSI Driving Range'), findsWidgets);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Google'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
    expect(find.text('New user? Create an account'), findsOneWidget);
  });

  testWidgets('user can submit feedback', (tester) async {
    await pumpAppPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feedback').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Submit Feedback'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Feedback message'),
      'Please add more evening slots.',
    );
    await tester.tap(find.text('Submit Feedback'));
    await tester.pumpAndSettle();
    expect(
      find.text('Feedback submitted to the administrator.'),
      findsOneWidget,
    );
  });

  testWidgets('user can change the current session password', (tester) async {
    await pumpAppPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      5,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Current password'),
      'password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'newpass1',
    );
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Password updated successfully.'), findsOneWidget);
  });

  testWidgets('remember me keeps email only, not password', (tester) async {
    SharedPreferences.setMockInitialValues({
      'remembered_login_email': 'saved@example.com',
      'remembered_login_password': 'old-secret',
    });

    await pumpAppPastSplash(tester);

    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(0),
    );
    final passwordField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );

    expect(emailField.controller?.text, 'saved@example.com');
    expect(passwordField.controller?.text, isEmpty);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('remembered_login_password'), isNull);
  });

  testWidgets('user can toggle dark mode from profile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpAppPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).onTap!(
      5,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(SwitchListTile),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });

  testWidgets('about tab is between feedback and profile', (tester) async {
    await pumpAppPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('About the Application'), findsOneWidget);
    expect(find.text('Development Team'), findsOneWidget);
    expect(find.text('Muhammad Hakimi Adly bin Hazlee'), findsOneWidget);
  });

  test('cancelled bookings do not occupy an available slot', () {
    final date = DateTime(2026, 7, 1);
    final bookings = [
      Booking(
        id: 'cancelled',
        type: 'Golf Driving Range',
        title: '50-Ball Bucket',
        date: date,
        time: '10:00 AM',
        amount: 'RM 10',
        paymentMethod: 'Pay at Counter',
        status: BookingStatus.cancelled,
      ),
    ];

    expect(
      isSlotBooked(
        bookings: bookings,
        date: date,
        time: '10:00 AM',
        bookingType: 'Golf Driving Range',
      ),
      isFalse,
    );
  });

  testWidgets('trainer booking only requires date and contact arrangement', (
    tester,
  ) async {
    await pumpAppPastSplash(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Booking').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trainer'));
    await tester.pumpAndSettle();

    expect(find.text('Select available slot'), findsNothing);
    expect(find.text('Discuss Time, Price and Slot'), findsOneWidget);
  });

  test('rejected and expired payments release their slots', () {
    final date = DateTime(2026, 7, 2);
    final bookings = [
      Booking(
        id: 'rejected',
        type: 'Golf Driving Range',
        title: '50-Ball Bucket',
        date: date,
        time: '3:00 PM',
        amount: 'RM 10',
        paymentMethod: 'QR Payment',
        status: BookingStatus.paymentRejected,
      ),
      Booking(
        id: 'expired',
        type: 'Golf Driving Range',
        title: '100-Ball Bucket',
        date: date,
        time: '4:00 PM',
        amount: 'RM 15',
        paymentMethod: 'Pay at Counter',
        status: BookingStatus.expired,
      ),
    ];

    expect(
      isSlotBooked(
        bookings: bookings,
        date: date,
        time: '3:00 PM',
        bookingType: 'Golf Driving Range',
      ),
      isFalse,
    );
    expect(
      isSlotBooked(
        bookings: bookings,
        date: date,
        time: '4:00 PM',
        bookingType: 'Golf Driving Range',
      ),
      isFalse,
    );
  });

  test(
    'pay at counter reservations keep their lane until admin changes status',
    () {
      final date = DateTime(2026, 7, 3);
      final bookings = [
        Booking(
          id: 'counter',
          type: 'Golf Driving Range',
          title: '50-Ball Bucket',
          date: date,
          time: '5:00 PM',
          amount: 'RM 10',
          paymentMethod: 'Pay at Counter',
          status: BookingStatus.reserved,
          lane: 'KD01',
        ),
      ];

      expect(
        isLaneTimeBooked(
          bookings: bookings,
          date: date,
          time: '5:00 PM',
          lane: 'KD01',
        ),
        isTrue,
      );
    },
  );

  test(
    'driving range bookings block overlapping durations on the same lane',
    () {
      final date = DateTime(2026, 7, 4);
      final bookings = [
        Booking(
          id: 'range',
          type: 'Golf Driving Range',
          title: '100-Ball Bucket',
          date: date,
          time: '12:00 PM',
          startTime: '12:00 PM',
          endTime: '1:30 PM',
          duration: '1 hour 30 minutes',
          durationMinutes: 90,
          amount: 'RM 15',
          paymentMethod: 'Pay at Counter',
          status: BookingStatus.reserved,
          lane: 'KD01',
          laneId: 'KD01',
        ),
      ];

      expect(
        isLaneTimeBooked(
          bookings: bookings,
          date: date,
          time: '1:00 PM',
          lane: 'KD01',
          durationMinutes: 60,
        ),
        isTrue,
      );
      expect(
        isLaneTimeBooked(
          bookings: bookings,
          date: date,
          time: '1:30 PM',
          lane: 'KD01',
          durationMinutes: 60,
        ),
        isFalse,
      );
      expect(
        isLaneTimeBooked(
          bookings: bookings,
          date: date,
          time: '1:00 PM',
          lane: 'KD02',
          durationMinutes: 60,
        ),
        isFalse,
      );
    },
  );
}
