# UPSI Driving Range Booking System

Flutter mobile application for booking UPSI driving range sessions and golf trainer appointments.

## Project Overview

This application allows users to create an account, log in, view available driving range packages, book lanes, arrange trainer sessions, manage profile details, submit feedback, and view booking/payment status. The app uses Supabase for authentication, profile data, app setup data, booking records, payment receipt data, and profile image storage.

## Main Features

- User sign up and login
- English and Bahasa Melayu language toggle
- Driving range package booking
- Lane and time availability checking
- Trainer appointment request
- QR payment and pay-at-counter booking flow
- Booking history and booking status tracking
- Profile update and password change
- Feedback submission
- Contact/about pages
- Light and dark mode

## APK

The APK file included for assignment testing is:

`UPSI-Driving-Range-release-2026-06-29.apk`

Install the APK on an Android device or emulator to test the application.

## How To Run From Source Code

1. Install Flutter.
2. Open this project folder in VS Code or Android Studio.
3. Run:

```bash
flutter pub get
flutter run
```

To check the project:

```bash
flutter analyze
flutter test
```

Latest local check:

- `flutter analyze`: passed
- `flutter test`: passed, 11 tests

## Login Notes

The app is connected to Supabase authentication. New users can register from the sign-up screen. If a lecturer or tester needs a prepared demo account, create one in Supabase Auth before submission and provide the email/password separately.

## Database Files

The included SQL files document the Supabase database setup used by the app:

- `supabase_app_data.sql`
- `supabase_profiles.sql`
- `supabase_profile_images.sql`
- `supabase_payment_receipts.sql`
- `supabase_qr_payment_settings.sql`
- `supabase_manage_user_roles.sql`
- `supabase_fix_profile_duplicates.sql`

## Suggested Assignment Submission

For Google Drive submission, include:

- Source code zip
- APK file
- SQL files
- This README file

The source code zip does not need generated/cache folders such as `build`, `.dart_tool`, IDE folders, temporary website inspection folders, or log files.
