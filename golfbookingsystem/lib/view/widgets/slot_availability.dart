import 'package:flutter/material.dart';

import '../../model/booking.dart';
import '../../theme/app_theme.dart';

bool isSlotBooked({
  required List<Booking> bookings,
  required DateTime date,
  required String time,
  required String bookingType,
  String? trainerName,
  String? lane,
  int durationMinutes = 60,
  String? excludedBookingId,
}) {
  return bookings.any((booking) {
    if (booking.id == excludedBookingId ||
        _doesNotBlockSlot(booking.status) ||
        booking.type != bookingType ||
        !_isSameDate(booking.date, date)) {
      return false;
    }

    if (bookingType == 'Golf Trainer') {
      return booking.time == time && booking.title == trainerName;
    }

    if (bookingType == 'Golf Driving Range' && lane != null) {
      if ((booking.laneId ?? booking.lane) != lane) return false;

      final requestedStart = bookingDateTime(date, time);
      final requestedEnd = requestedStart?.add(
        Duration(minutes: durationMinutes),
      );
      final existingStart = bookingDateTime(
        booking.date,
        booking.startTime ?? booking.time,
      );
      final existingEnd = booking.endTime == null
          ? existingStart?.add(Duration(minutes: booking.durationMinutes ?? 60))
          : bookingDateTime(booking.date, booking.endTime!);

      if (requestedStart == null ||
          requestedEnd == null ||
          existingStart == null ||
          existingEnd == null) {
        return booking.time == time;
      }

      return _rangesOverlap(
        requestedStart,
        requestedEnd,
        existingStart,
        existingEnd,
      );
    }

    return booking.time == time;
  });
}

bool isLaneTimeBooked({
  required List<Booking> bookings,
  required DateTime date,
  required String time,
  required String lane,
  int durationMinutes = 60,
  String? excludedBookingId,
}) {
  return isSlotBooked(
    bookings: bookings,
    date: date,
    time: time,
    bookingType: 'Golf Driving Range',
    lane: lane,
    durationMinutes: durationMinutes,
    excludedBookingId: excludedBookingId,
  );
}

DateTime? bookingDateTime(DateTime date, String time) {
  final parsed = _parseTime(time);
  if (parsed == null) return null;

  return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
}

String formatBookingTime(DateTime value) {
  final hour12 = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

class SlotAvailability extends StatelessWidget {
  const SlotAvailability({
    super.key,
    required this.selectedDate,
    required this.bookings,
    required this.teeTimes,
    required this.bookingType,
    this.lanes = const [],
    this.blockedLanesByTime = const {},
    this.durationMinutes = 60,
    this.trainerName,
    this.excludedBookingId,
  });

  final DateTime? selectedDate;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final String bookingType;
  final List<String> lanes;
  final Map<String, Set<String>> blockedLanesByTime;
  final int durationMinutes;
  final String? trainerName;
  final String? excludedBookingId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot Availability',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              selectedDate == null
                  ? 'Select a date to check availability.'
                  : bookingType == 'Golf Driving Range' && lanes.isNotEmpty
                  ? 'Green lanes are available for that time. Grey lanes are already booked.'
                  : 'Green times are available. Grey times are already booked.',
            ),
            if (selectedDate != null) ...[
              const SizedBox(height: 12),
              if (teeTimes.isEmpty)
                const Text(
                  'No time slots are configured. Please contact the administrator.',
                )
              else if (bookingType == 'Golf Driving Range' && lanes.isNotEmpty)
                _DrivingRangeAvailabilityTable(
                  selectedDate: selectedDate!,
                  bookings: bookings,
                  teeTimes: teeTimes,
                  lanes: lanes,
                  blockedLanesByTime: blockedLanesByTime,
                  durationMinutes: durationMinutes,
                  excludedBookingId: excludedBookingId,
                )
              else
                _TimeAvailabilityTable(
                  selectedDate: selectedDate!,
                  bookings: bookings,
                  teeTimes: teeTimes,
                  bookingType: bookingType,
                  trainerName: trainerName,
                  excludedBookingId: excludedBookingId,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrivingRangeAvailabilityTable extends StatelessWidget {
  const _DrivingRangeAvailabilityTable({
    required this.selectedDate,
    required this.bookings,
    required this.teeTimes,
    required this.lanes,
    required this.blockedLanesByTime,
    required this.durationMinutes,
    this.excludedBookingId,
  });

  final DateTime selectedDate;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final List<String> lanes;
  final Map<String, Set<String>> blockedLanesByTime;
  final int durationMinutes;
  final String? excludedBookingId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 46,
        dataRowMaxHeight: 46,
        columnSpacing: 12,
        horizontalMargin: 10,
        columns: [
          const DataColumn(label: Text('Time')),
          const DataColumn(label: Text('Open')),
          ...lanes.map((lane) => DataColumn(label: Text(lane))),
        ],
        rows: teeTimes.map((time) {
          final laneBooked = {
            for (final lane in lanes)
              lane:
                  (blockedLanesByTime[time]?.contains(lane.toUpperCase()) ??
                      false) ||
                  isLaneTimeBooked(
                    bookings: bookings,
                    date: selectedDate,
                    time: time,
                    lane: lane,
                    durationMinutes: durationMinutes,
                    excludedBookingId: excludedBookingId,
                  ),
          };
          final availableCount = laneBooked.values
              .where((booked) => !booked)
              .length;

          return DataRow(
            cells: [
              DataCell(Text(time)),
              DataCell(Text('$availableCount/${lanes.length}')),
              ...lanes.map((lane) {
                final booked = laneBooked[lane] ?? false;
                return DataCell(_AvailabilityDot(booked: booked));
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TimeAvailabilityTable extends StatelessWidget {
  const _TimeAvailabilityTable({
    required this.selectedDate,
    required this.bookings,
    required this.teeTimes,
    required this.bookingType,
    this.trainerName,
    this.excludedBookingId,
  });

  final DateTime selectedDate;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final String bookingType;
  final String? trainerName;
  final String? excludedBookingId;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowHeight: 38,
      dataRowMinHeight: 46,
      dataRowMaxHeight: 46,
      columnSpacing: 18,
      horizontalMargin: 10,
      columns: const [
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Status')),
      ],
      rows: teeTimes.map((time) {
        final booked = isSlotBooked(
          bookings: bookings,
          date: selectedDate,
          time: time,
          bookingType: bookingType,
          trainerName: trainerName,
          excludedBookingId: excludedBookingId,
        );

        return DataRow(
          cells: [
            DataCell(Text(time)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AvailabilityDot(booked: booked),
                  const SizedBox(width: 8),
                  Text(booked ? 'Booked' : 'Available'),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _AvailabilityDot extends StatelessWidget {
  const _AvailabilityDot({required this.booked});

  final bool booked;

  @override
  Widget build(BuildContext context) {
    final color = booked ? Colors.grey.shade500 : AppTheme.darkGreen;
    return Tooltip(
      message: booked ? 'Booked' : 'Available',
      child: Icon(
        booked ? Icons.close_rounded : Icons.check_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

bool _doesNotBlockSlot(BookingStatus status) {
  return status == BookingStatus.cancelled ||
      status == BookingStatus.paymentRejected ||
      status == BookingStatus.expired;
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool _rangesOverlap(
  DateTime firstStart,
  DateTime firstEnd,
  DateTime secondStart,
  DateTime secondEnd,
) {
  return firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);
}

({int hour, int minute})? _parseTime(String value) {
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

  return (hour: hour, minute: minute);
}
