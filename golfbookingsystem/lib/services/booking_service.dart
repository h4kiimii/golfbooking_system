import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/booking.dart';
import '../model/feedback_message.dart';

class BookingService {
  BookingService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _random = Random.secure();

  static const _bookingsTable = 'bookings';
  static const _paymentsTable = 'payments';
  static const _feedbackTable = 'feedback_review';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Please log in before saving data.');
    }
    return id;
  }

  Future<List<Booking>> loadMyBookings() async {
    await _ensureCurrentUserProfile();
    final rows = await _client
        .from(_bookingsTable)
        .select('*, payments(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    final bookings = rows
        .map<Booking>((row) => Booking.fromSupabase(row))
        .toList(growable: false);

    final paymentByBookingId = await _loadPaymentsForBookings(
      bookings.map((booking) => booking.id).toList(growable: false),
    );

    return bookings
        .map((booking) => booking.mergePayment(paymentByBookingId[booking.id]))
        .toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> _loadPaymentsForBookings(
    List<String> bookingIds,
  ) async {
    if (bookingIds.isEmpty) return const {};

    try {
      final rows = await _client
          .from(_paymentsTable)
          .select()
          .eq('user_id', _userId)
          .inFilter('booking_id', bookingIds);

      final payments = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final payment = Map<String, dynamic>.from(row as Map);
        final bookingId = payment['booking_id']?.toString();
        if (bookingId != null && !payments.containsKey(bookingId)) {
          payments[bookingId] = payment;
        }
      }
      return payments;
    } catch (_) {
      return const {};
    }
  }

  Future<Booking> createBooking(Booking booking) async {
    await _ensureCurrentUserProfile();
    final id = _isUuid(booking.id) ? booking.id : _newUuid();
    final bookingToSave = booking.copyWith(id: id);
    final bookingData = await _bookingDataForAdminWebsite(bookingToSave);
    final saved = await _client
        .from(_bookingsTable)
        .insert({'id': id, ...bookingData})
        .select()
        .single();

    await _savePaymentIfNeeded(bookingToSave);
    return Booking.fromSupabase(saved);
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await _ensureCurrentUserProfile();
    final patch = {
      'status': status.name,
      'booking_status': _bookingStatusForWebsite(status),
    };
    if (status == BookingStatus.cancelled) {
      patch.addAll({
        'payment_status': 'not_paid',
        'cancellation_type': 'user_cancelled',
        'cancelled_by': _userId,
        'cancelled_at': DateTime.now().toIso8601String(),
      });
    }

    await _client
        .from(_bookingsTable)
        .update(patch)
        .eq('id', bookingId)
        .eq('user_id', _userId);
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime date,
    required String time,
  }) async {
    await _ensureCurrentUserProfile();
    await _client
        .from(_bookingsTable)
        .update({
          'booking_date': date.toIso8601String().split('T').first,
          'booking_time': _postgresTime(time),
          'start_time': time,
          'scheduled_date': date.toIso8601String().split('T').first,
          'scheduled_time': _postgresTime(time),
          'status': BookingStatus.rescheduled.name,
          'booking_status': _bookingStatusForWebsite(BookingStatus.rescheduled),
          'payment_status': 'not_paid',
        })
        .eq('id', bookingId)
        .eq('user_id', _userId);
  }

  Future<void> deleteBooking(String bookingId) async {
    await _ensureCurrentUserProfile();
    await _client
        .from(_bookingsTable)
        .delete()
        .eq('id', bookingId)
        .eq('user_id', _userId);
  }

  Future<void> submitFeedback(FeedbackMessage feedback) async {
    await _ensureCurrentUserProfile();
    await _client
        .from(_feedbackTable)
        .insert(feedback.toSupabase(userId: _userId));
  }

  Future<void> _ensureCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please log in before saving data.');
    }

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .limit(1)
        .maybeSingle();
    if (existing != null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email ?? '${user.id}@upsi-driving-range.local';
    final payload = {
      'id': user.id,
      'full_name': _metadataText(metadata, 'full_name') ?? 'Golf Member',
      'email': email,
      'age': int.tryParse(_metadataText(metadata, 'age') ?? '') ?? 21,
      'birthday': _metadataText(metadata, 'birthday') ?? '2005-01-01',
      'address': _metadataText(metadata, 'address') ?? 'Kuala Lumpur, Malaysia',
      'phone': _metadataText(metadata, 'phone_number') ?? '+60 12-345 6789',
      'phone_number':
          _metadataText(metadata, 'phone_number') ?? '+60 12-345 6789',
      'login_provider': 'User Email',
    };

    try {
      await _client.from('profiles').insert(payload);
    } on PostgrestException catch (error) {
      if (!_isDuplicateProfileEmail(error)) rethrow;
      await _client.from('profiles').insert({
        ...payload,
        'email': _uniqueFallbackEmail(user.id, email),
      });
    }
  }

  String? _metadataText(Map<String, dynamic> metadata, String key) {
    final value = metadata[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool _isDuplicateProfileEmail(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '23505' &&
        (message.contains('profiles_email_key') ||
            message.contains('duplicate key') ||
            message.contains('email'));
  }

  String _uniqueFallbackEmail(String userId, String email) {
    final atIndex = email.indexOf('@');
    final suffix = userId.replaceAll('-', '').substring(0, 12);
    if (atIndex <= 0) return '$suffix@upsi-driving-range.local';
    return '${email.substring(0, atIndex)}+$suffix${email.substring(atIndex)}';
  }

  Future<void> _savePaymentIfNeeded(Booking booking) async {
    if (booking.paymentReference == null) return;

    await _client.from(_paymentsTable).insert({
      'booking_id': booking.id,
      'user_id': _userId,
      'amount': booking.numericAmount,
      'total_amount': booking.numericAmount,
      'amount_text': booking.amount,
      'payment_method': booking.paymentMethod,
      'payment_reference': booking.paymentReference,
      'payment_note': booking.paymentReference,
      'receipt_file_name': booking.paymentReceiptName,
      'receipt_file_url': booking.paymentReceiptUrl,
      'receipt_url': booking.paymentReceiptUrl,
      'receipt_image_url': booking.paymentReceiptUrl,
      'receipt_uploaded_at': booking.paymentReceiptUploadedAt
          ?.toIso8601String(),
      'status': booking.status == BookingStatus.pendingVerification
          ? 'pendingVerification'
          : 'reserved',
      'payment_status': _paymentStatusForWebsite(booking),
    });
  }

  Future<Map<String, dynamic>> _bookingDataForAdminWebsite(
    Booking booking,
  ) async {
    final data = booking.toSupabase(userId: _userId);
    data.addAll({
      'scheduled_date': booking.date.toIso8601String().split('T').first,
      'scheduled_time': _postgresTime(booking.time),
      'booking_status': _bookingStatusForWebsite(booking.status),
      'payment_status': _paymentStatusForWebsite(booking),
      'number_of_bucket': booking.type == 'Golf Driving Range'
          ? booking.bucketCount
          : null,
      'total_balls': booking.type == 'Golf Driving Range'
          ? booking.totalBalls
          : 0,
      'membership_type': booking.type == 'Golf Driving Range'
          ? booking.membershipType
          : null,
      'lane_label': booking.laneId ?? booking.lane,
      'customer_note': booking.type == 'Golf Trainer'
          ? 'Training time, price and slot will be arranged directly with the trainer.'
          : null,
    });

    if (booking.type == 'Golf Trainer') {
      final trainerId = await _findTrainerId(booking);
      if (trainerId != null) {
        data['trainer_id'] = trainerId;
      }
      final teeSlotId = await _findOrCreateTeeSlot(
        date: booking.date,
        time: null,
        type: 'trainer',
        trainerId: trainerId,
      );
      if (teeSlotId != null) data['tee_slot_id'] = teeSlotId;
    } else {
      final drivingRangeId = await _findFirstId('driving_ranges');
      if (drivingRangeId != null) {
        data['driving_range_id'] = drivingRangeId;
      }
      final bucketOptionId = await _findBucketOptionId(booking, drivingRangeId);
      if (bucketOptionId != null) {
        data['bucket_option_id'] = bucketOptionId;
      }

      final laneId = await _findLaneId(booking.laneId ?? booking.lane);
      if (laneId != null) {
        data['driving_range_lane_id'] = laneId;
      }
      data['lane_id'] = booking.laneId ?? booking.lane;

      final teeSlotId = await _findOrCreateTeeSlot(
        date: booking.date,
        time: booking.time,
        type: 'driving_range',
      );
      if (teeSlotId != null) data['tee_slot_id'] = teeSlotId;
    }

    return data;
  }

  Future<String?> _findOrCreateTeeSlot({
    required DateTime date,
    required String? time,
    required String type,
    String? trainerId,
  }) async {
    final slotDate = date.toIso8601String().split('T').first;
    final slotTime = time == null ? null : _postgresTime(time);
    try {
      var query = _client
          .from('tee_slots')
          .select('id')
          .eq('slot_date', slotDate)
          .eq('slot_type', type);
      if (slotTime != null) query = query.eq('slot_time', slotTime);
      if (trainerId != null) query = query.eq('trainer_id', trainerId);
      final existing = await query.limit(1).maybeSingle();
      final existingId = existing?['id']?.toString();
      if (existingId != null) return existingId;
    } catch (_) {}

    try {
      final payload = {
        'slot_date': slotDate,
        'slot_time': slotTime,
        'slot_type': type,
        'trainer_id': trainerId,
        'status': 'available',
      }..removeWhere((_, value) => value == null);
      final created = await _client
          .from('tee_slots')
          .insert(payload)
          .select('id')
          .single();
      return created['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findBucketOptionId(
    Booking booking,
    String? drivingRangeId,
  ) async {
    final balls = booking.ballsPerBucket;
    for (final column in ['ball_count', 'balls']) {
      try {
        var query = _client
            .from('bucket_options')
            .select('id')
            .eq(column, balls);
        if (drivingRangeId != null) {
          query = query.eq('driving_range_id', drivingRangeId);
        }
        final row = await query.limit(1).maybeSingle();
        final id = row?['id']?.toString();
        if (id != null) return id;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> _findTrainerId(Booking booking) async {
    final email = booking.trainerEmail;
    if (email != null && email.isNotEmpty) {
      final byEmail = await _maybeSingleId(
        table: 'trainers',
        column: 'email',
        value: email,
      );
      if (byEmail != null) return byEmail;
    }

    for (final column in ['name', 'full_name', 'trainer_name']) {
      final id = await _maybeSingleId(
        table: 'trainers',
        column: column,
        value: booking.title,
      );
      if (id != null) return id;
    }
    return null;
  }

  Future<String?> _findLaneId(String? laneCode) async {
    if (laneCode == null || laneCode.isEmpty) return null;
    for (final column in ['code', 'lane_code', 'name']) {
      final id = await _maybeSingleId(
        table: 'driving_range_lanes',
        column: column,
        value: laneCode,
      );
      if (id != null) return id;
    }
    return null;
  }

  Future<String?> _findFirstId(String table) async {
    try {
      final row = await _client.from(table).select('id').limit(1).maybeSingle();
      return row?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _maybeSingleId({
    required String table,
    required String column,
    required String value,
  }) async {
    try {
      final row = await _client
          .from(table)
          .select('id')
          .eq(column, value)
          .limit(1)
          .maybeSingle();
      return row?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String? _postgresTime(String value) {
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

  String _bookingStatusForWebsite(BookingStatus status) {
    return switch (status) {
      BookingStatus.confirmed => 'confirmed',
      BookingStatus.cancelled => 'cancelled',
      BookingStatus.paymentRejected => 'cancelled',
      _ => 'pending_payment',
    };
  }

  String _paymentStatusForWebsite(Booking booking) {
    if (booking.status == BookingStatus.pendingVerification) return 'pending';
    if (booking.status == BookingStatus.paymentRejected) return 'rejected';
    if (booking.status == BookingStatus.confirmed) return 'verified';
    return 'not_paid';
  }
}
