class Trainer {
  const Trainer({
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.imagePath,
    this.description,
    this.level = defaultLevel,
  });

  static const defaultLevel = 'Professional Amateur( Prof. Am.)';

  final String name;
  final String phoneNumber;
  final String? email;
  final String? imagePath;
  final String? description;
  final String level;

  Trainer copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? imagePath,
    String? description,
    String? level,
  }) {
    return Trainer(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      level: level ?? this.level,
    );
  }
}
