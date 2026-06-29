class Trainer {
  const Trainer({
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.imagePath,
    this.level = defaultLevel,
  });

  static const defaultLevel = 'Professional Amateur( Prof. Am.)';

  final String name;
  final String phoneNumber;
  final String? email;
  final String? imagePath;
  final String level;

  Trainer copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? imagePath,
    String? level,
  }) {
    return Trainer(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      level: level ?? this.level,
    );
  }
}
