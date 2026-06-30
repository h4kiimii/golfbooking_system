import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/auth_session.dart';
import '../model/user_profile.dart';

class AccountService {
  AccountService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _profilesTable = 'profiles';
  static const _profileImagesBucket = 'profile-images';

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Login failed. Please check your account.');
    }

    final profile = await _getOrCreateProfile(
      userId: user.id,
      email: user.email ?? email,
      fallback: _profileFromAuthUser(
        user: user,
        email: user.email ?? email,
        loginProvider: 'User Email',
      ),
    );

    return AuthSession(profile: profile, password: password);
  }

  Future<AuthSession> signUp({
    required UserProfile profile,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: profile.email,
      password: password,
      data: {
        'full_name': profile.fullName,
        'age': profile.age,
        'birthday': profile.birthday.toIso8601String().split('T').first,
        'address': profile.address,
        'phone_number': profile.phoneNumber,
      },
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'Account created. Please verify your email before logging in.',
      );
    }
    if (response.session == null) {
      throw const AuthException(
        'Account created. Please verify your email, then log in to finish your profile record.',
      );
    }

    final savedProfile = profile.copyWith(
      id: user.id,
      email: user.email ?? profile.email,
      loginProvider: 'Email Sign Up',
    );
    await saveProfile(savedProfile);

    return AuthSession(profile: savedProfile, password: password);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final userId = profile.id ?? _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No logged in user was found.');
    }

    await _client
        .from(_profilesTable)
        .upsert(profile.toSupabase(userId: userId));
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException(
        'Please log in before uploading a profile photo.',
      );
    }

    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = extension == fileName ? 'jpg' : extension;
    final path =
        '$userId/profile-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await _client.storage
        .from(_profileImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(safeExtension),
            upsert: true,
          ),
        );

    return _client.storage.from(_profileImagesBucket).getPublicUrl(path);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<UserProfile> _getOrCreateProfile({
    required String userId,
    required String email,
    required UserProfile fallback,
  }) async {
    final existing = await _client
        .from(_profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return UserProfile.fromSupabase(existing);
    }

    try {
      await _client
          .from(_profilesTable)
          .insert(fallback.toSupabase(userId: userId));
    } on PostgrestException catch (error) {
      if (error.code != '23505') {
        rethrow;
      }
    }
    return fallback.copyWith(id: userId, email: email);
  }

  UserProfile _defaultProfile({
    required String userId,
    required String email,
    required String loginProvider,
  }) {
    return UserProfile(
      id: userId,
      fullName: 'Golf Member',
      email: email,
      age: '21',
      birthday: DateTime(2005, 1, 1),
      address: 'Kuala Lumpur, Malaysia',
      phoneNumber: '+60 12-345 6789',
      loginProvider: loginProvider,
    );
  }

  UserProfile _profileFromAuthUser({
    required User user,
    required String email,
    required String loginProvider,
  }) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final defaultProfile = _defaultProfile(
      userId: user.id,
      email: email,
      loginProvider: loginProvider,
    );
    final birthday = DateTime.tryParse((metadata['birthday'] as String?) ?? '');

    return defaultProfile.copyWith(
      fullName: _metadataText(metadata, 'full_name') ?? defaultProfile.fullName,
      age: _metadataText(metadata, 'age') ?? defaultProfile.age,
      birthday: birthday ?? defaultProfile.birthday,
      address: _metadataText(metadata, 'address') ?? defaultProfile.address,
      phoneNumber:
          _metadataText(metadata, 'phone_number') ??
          _metadataText(metadata, 'phone') ??
          defaultProfile.phoneNumber,
    );
  }

  String? _metadataText(Map<String, dynamic> metadata, String key) {
    final value = metadata[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
