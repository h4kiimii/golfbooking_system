class UserProfile {
  const UserProfile({
    this.id,
    required this.fullName,
    required this.email,
    required this.age,
    required this.birthday,
    required this.address,
    required this.phoneNumber,
    required this.loginProvider,
    this.imagePath,
  });

  final String? id;
  final String fullName;
  final String email;
  final String age;
  final DateTime birthday;
  final String address;
  final String phoneNumber;
  final String loginProvider;
  final String? imagePath;

  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String?,
      fullName: (data['full_name'] as String?) ?? 'Golf Member',
      email: (data['email'] as String?) ?? '',
      age: (data['age']?.toString()) ?? '',
      birthday:
          DateTime.tryParse((data['birthday'] as String?) ?? '') ??
          DateTime(2005, 1, 1),
      address: (data['address'] as String?) ?? '',
      phoneNumber:
          (data['phone_number'] as String?) ?? (data['phone'] as String?) ?? '',
      loginProvider: (data['login_provider'] as String?) ?? 'User Email',
      imagePath:
          (data['image_path'] as String?) ??
          data['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toSupabase({String? userId}) {
    final profileId = userId ?? id;
    final data = {
      'full_name': fullName,
      'email': email,
      'age': int.tryParse(age) ?? age,
      'birthday': birthday.toIso8601String().split('T').first,
      'address': address,
      'phone': phoneNumber,
      'phone_number': phoneNumber,
      'login_provider': loginProvider,
      'image_path': imagePath,
      'profile_image_url': imagePath,
    };
    if (profileId != null) {
      data['id'] = profileId;
    }
    return data;
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? age,
    DateTime? birthday,
    String? address,
    String? phoneNumber,
    String? loginProvider,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      age: age ?? this.age,
      birthday: birthday ?? this.birthday,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      loginProvider: loginProvider ?? this.loginProvider,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    );
  }
}
