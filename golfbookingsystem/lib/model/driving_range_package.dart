class DrivingRangePackage {
  const DrivingRangePackage({
    required this.name,
    required this.description,
    required this.nonMemberPrice,
    required this.memberPrice,
    required this.balls,
  });

  final String name;
  final String description;
  final String nonMemberPrice;
  final String memberPrice;
  final int balls;

  DrivingRangePackage copyWith({
    String? name,
    String? description,
    String? nonMemberPrice,
    String? memberPrice,
    int? balls,
  }) {
    return DrivingRangePackage(
      name: name ?? this.name,
      description: description ?? this.description,
      nonMemberPrice: nonMemberPrice ?? this.nonMemberPrice,
      memberPrice: memberPrice ?? this.memberPrice,
      balls: balls ?? this.balls,
    );
  }
}
