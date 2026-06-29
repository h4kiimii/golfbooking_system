import 'user_profile.dart';

class AuthSession {
  const AuthSession({required this.profile, required this.password});

  final UserProfile profile;
  final String password;
}
