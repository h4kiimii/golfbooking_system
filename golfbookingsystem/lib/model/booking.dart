enum BookingStatus {
  reserved,
  pendingVerification,
  confirmed,
  paymentRejected,
  expired,
  cancelled,
  rescheduled,
}

BookingStatus bookingStatusFromText(String? value) {
  return BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.reserved,
  );
}

class Booking {
  const Booking({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.startTime,
    this.endTime,
    this.duration,
    this.durationMinutes,
    this.lane,
    this.laneId,
    this.paymentReference,
    this.paymentReceiptName,
    this.paymentReceiptUrl,
    this.paymentReceiptUploadedAt,
    this.trainerPhoneNumber,
    this.trainerEmail,
    this.trainingClassType,
    this.receiptNumber,
    this.verifiedAt,
  });

  final String id;
  final String type;
  final String title;
  final DateTime date;
  final String time;
  final String amount;
  final String paymentMethod;
  final BookingStatus status;
  final String? startTime;
  final String? endTime;
  final String? duration;
  final int? durationMinutes;
  final String? lane;
  final String? laneId;
  final String? paymentReference;
  final String? paymentReceiptName;
  final String? paymentReceiptUrl;
  final DateTime? paymentReceiptUploadedAt;
  final String? trainerPhoneNumber;
  final String? trainerEmail;
  final String? trainingClassType;
  final String? receiptNumber;
  final DateTime? verifiedAt;

  Booking copyWith({
    String? id,
    String? type,
    String? title,
    DateTime? date,
    String? time,
    String? amount,
    String? paymentMethod,
    BookingStatus? status,
    String? startTime,
    String? endTime,
    String? duration,
    int? durationMinutes,
    String? lane,
    String? laneId,
    String? paymentReference,
    String? paymentReceiptName,
    String? paymentReceiptUrl,
    DateTime? paymentReceiptUploadedAt,
    String? trainerPhoneNumber,
    String? trainerEmail,
    String? trainingClassType,
    String? receiptNumber,
    DateTime? verifiedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lane: lane ?? this.lane,
      laneId: laneId ?? this.laneId,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentReceiptName: paymentReceiptName ?? this.paymentReceiptName,
      paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,
      paymentReceiptUploadedAt:
          paymentReceiptUploadedAt ?? this.paymentReceiptUploadedAt,
      trainerPhoneNumber: trainerPhoneNumber ?? this.trainerPhoneNumber,
      trainerEmail: trainerEmail ?? this.trainerEmail,
      trainingClassType: trainingClassType ?? this.trainingClassType,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory Booking.fromSupabase(Map<String, dynamic> data) {
    final payment = _joinedPayment(data['payments']);
    return Booking(
      id: data['id'].toString(),
      type:
          (data['app_booking_type'] as String?) ??
          ((data['booking_type'] as String?) == 'trainer'
              ? 'Golf Trainer'
              : 'Golf Driving Range'),
      title: (data['title'] as String?) ?? 'Booking',
      date:
          DateTime.tryParse((data['booking_date'] as String?) ?? '') ??
          DateTime.now(),
      time: _displayTime(
        data['booking_time'] as String?,
        data['start_time'] as String?,
      ),
      amount: (data['amount_text'] as String?) ?? 'To be negotiated',
      paymentMethod:
          (data['payment_method'] as String?) ?? 'Arrange with trainer',
      status: _statusFromSupabase(data, payment),
      startTime: data['start_time'] as String?,
      endTime: data['end_time'] as String?,
      duration: data['duration_label'] as String?,
      durationMinutes: data['duration_minutes'] as int?,
      lane: data['lane_code'] as String?,
      laneId: data['lane_id_text'] as String?,
      paymentReference:
          (payment?['payment_reference'] as String?) ??
          (payment?['payment_note'] as String?) ??
          data['payment_reference'] as String?,
      paymentReceiptName:
          (payment?['receipt_file_name'] as String?) ??
          data['payment_receipt_name'] as String?,
      paymentReceiptUrl:
          (payment?['receipt_image_url'] as String?) ??
          (payment?['receipt_file_url'] as String?) ??
          (payment?['receipt_url'] as String?) ??
          (data['payment_receipt_url'] as String?) ??
          data['receipt_url'] as String?,
      paymentReceiptUploadedAt: DateTime.tryParse(
        (payment?['receipt_uploaded_at'] as String?) ??
            (data['payment_receipt_uploaded_at'] as String?) ??
            '',
      ),
      trainerPhoneNumber: data['trainer_phone_number'] as String?,
      trainerEmail: data['trainer_email'] as String?,
      trainingClassType: data['training_class_type'] as String?,
      receiptNumber: data['receipt_number'] as String?,
      verifiedAt: DateTime.tryParse(
        (data['verified_at'] as String?) ??
            (payment?['verified_at'] as String?) ??
            '',
      ),
    );
  }

  static BookingStatus _statusFromSupabase(
    Map<String, dynamic> data,
    Map<String, dynamic>? payment,
  ) {
    final appStatus = data['status'] as String?;
    final bookingStatus = data['booking_status'] as String?;
    final paymentStatus =
        (payment?['payment_status'] as String?) ??
        (payment?['status'] as String?) ??
        data['payment_status'] as String?;

    final normalizedPayment = _normalizeStatus(paymentStatus);
    final normalizedBooking = _normalizeStatus(bookingStatus);

    if (normalizedPayment.contains('verified') ||
        normalizedBooking.contains('confirmed')) {
      return BookingStatus.confirmed;
    }
    if (normalizedPayment.contains('reject')) {
      return BookingStatus.paymentRejected;
    }
    if (normalizedBooking.contains('cancel')) {
      return BookingStatus.cancelled;
    }
    if (normalizedBooking.contains('expired')) {
      return BookingStatus.expired;
    }
    if (normalizedBooking.contains('resched')) {
      return BookingStatus.rescheduled;
    }
    if (normalizedPayment.contains('pending')) {
      return BookingStatus.pendingVerification;
    }

    return bookingStatusFromText(appStatus);
  }

  Booking mergePayment(Map<String, dynamic>? payment) {
    if (payment == null) return this;
    return Booking(
      id: id,
      type: type,
      title: title,
      date: date,
      time: time,
      amount: (payment['amount_text'] as String?) ?? amount,
      paymentMethod: paymentMethod,
      status: _statusFromSupabase({
        'status': status.name,
        'booking_status': status.name,
      }, payment),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      durationMinutes: durationMinutes,
      lane: lane,
      laneId: laneId,
      paymentReference:
          (payment['payment_reference'] as String?) ??
          (payment['payment_note'] as String?) ??
          paymentReference,
      paymentReceiptName:
          (payment['receipt_file_name'] as String?) ?? paymentReceiptName,
      paymentReceiptUrl:
          (payment['receipt_image_url'] as String?) ??
          (payment['receipt_file_url'] as String?) ??
          (payment['receipt_url'] as String?) ??
          paymentReceiptUrl,
      paymentReceiptUploadedAt:
          DateTime.tryParse(
            (payment['receipt_uploaded_at'] as String?) ?? '',
          ) ??
          paymentReceiptUploadedAt,
      trainerPhoneNumber: trainerPhoneNumber,
      trainerEmail: trainerEmail,
      trainingClassType: trainingClassType,
      receiptNumber: receiptNumber,
      verifiedAt:
          DateTime.tryParse((payment['verified_at'] as String?) ?? '') ??
          verifiedAt,
    );
  }

  static String _normalizeStatus(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  static Map<String, dynamic>? _joinedPayment(Object? value) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Map<String, dynamic> toSupabase({required String userId}) {
    return {
      'user_id': userId,
      'booking_type': type == 'Golf Trainer' ? 'trainer' : 'driving_range',
      'app_booking_type': type,
      'title': title,
      'booking_date': date.toIso8601String().split('T').first,
      'booking_time': _postgresTime(time),
      'amount': numericAmount,
      'total_amount': numericAmount,
      'amount_text': amount,
      'payment_method': paymentMethod,
      'status': status.name,
      'start_time': startTime == null ? null : _postgresTime(startTime!),
      'end_time': endTime == null ? null : _postgresTime(endTime!),
      'duration_label': duration,
      'duration_minutes': durationMinutes,
      'lane_code': lane,
      'lane_id_text': laneId,
      'payment_reference': paymentReference,
      'payment_receipt_name': paymentReceiptName,
      'payment_receipt_url': paymentReceiptUrl,
      'receipt_url': paymentReceiptUrl,
      'payment_receipt_uploaded_at': paymentReceiptUploadedAt
          ?.toIso8601String(),
      'trainer_phone_number': trainerPhoneNumber,
      'trainer_email': trainerEmail,
      'training_class_type': trainingClassType,
      'receipt_number': receiptNumber,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  double get numericAmount {
    return double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  int get bucketCount {
    final match = RegExp(
      r'^(\d+)\s*x\s+',
      caseSensitive: false,
    ).firstMatch(title);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  int get totalBalls {
    final match = RegExp(
      r'\((\d+)\s+balls\)',
      caseSensitive: false,
    ).firstMatch(title);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  int get ballsPerBucket {
    final count = bucketCount <= 0 ? 1 : bucketCount;
    final total = totalBalls;
    return total <= 0 ? 0 : total ~/ count;
  }

  String get membershipType {
    final suffix = title.split(' - ').last.trim().toLowerCase();
    return suffix == 'member' ? 'member' : 'non-member';
  }

  static String _displayTime(String? bookingTime, String? startTime) {
    final value = startTime ?? bookingTime;
    if (value == null || value.isEmpty) {
      return 'Arrange with trainer';
    }
    return _formatTimeForDisplay(value);
  }

  static String? _postgresTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  static String _formatTimeForDisplay(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
    if (match == null) return value;

    final hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final hour12 = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}
