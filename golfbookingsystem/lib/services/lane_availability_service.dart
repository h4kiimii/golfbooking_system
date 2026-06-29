import 'package:supabase_flutter/supabase_flutter.dart';

class LaneAvailabilityService {
  LaneAvailabilityService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Set<String>> blockedLanes({
    required DateTime date,
    required String time,
    required int durationMinutes,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'upsi_driving_range_booked_lanes',
      params: {
        'p_booking_date': _dateText(date),
        'p_booking_time': time,
        'p_duration': durationMinutes,
        'p_exclude_booking_id': null,
      },
    );

    return rows
        .whereType<Map>()
        .map((row) => row['lane_code']?.toString().trim().toUpperCase())
        .whereType<String>()
        .where((lane) => lane.isNotEmpty)
        .toSet();
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
