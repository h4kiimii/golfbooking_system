class FeedbackMessage {
  const FeedbackMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.message,
    required this.submittedAt,
    this.isRead = false,
  });

  final String id;
  final String name;
  final String email;
  final String category;
  final String message;
  final DateTime submittedAt;
  final bool isRead;

  FeedbackMessage copyWith({bool? isRead}) {
    return FeedbackMessage(
      id: id,
      name: name,
      email: email,
      category: category,
      message: message,
      submittedAt: submittedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toSupabase({required String userId}) {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'category': category,
      'message': message,
      'status': 'active',
      'submitted_at': submittedAt.toIso8601String(),
      'created_at': submittedAt.toIso8601String(),
    };
  }
}
