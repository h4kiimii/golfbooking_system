import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/booking.dart';
import '../theme/app_theme.dart';
import 'widgets/slot_availability.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({
    super.key,
    required this.bookings,
    required this.teeTimes,
    required this.drivingRangeLanes,
    required this.onCancel,
    required this.onDelete,
    required this.onReschedule,
  });

  final List<Booking> bookings;
  final List<String> teeTimes;
  final List<String> drivingRangeLanes;
  final ValueChanged<String> onCancel;
  final ValueChanged<String> onDelete;
  final void Function(String bookingId, DateTime date, String time)
  onReschedule;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('My Bookings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No booking history yet.'),
            ),
          )
        else
          ...bookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _BookingCard(
                booking: booking,
                onCancel: () => _confirmCancel(context, booking),
                onDelete: () => _confirmDelete(context, booking),
                onReschedule: () => _showRescheduleSheet(context, booking),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context, Booking booking) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure you want to cancel ${booking.title}? This will release the booking slot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      onCancel(booking.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Booking booking) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Booking?'),
        content: const Text(
          'This inactive booking will be permanently removed from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      onDelete(booking.id);
    }
  }

  Future<void> _showRescheduleSheet(
    BuildContext context,
    Booking booking,
  ) async {
    DateTime selectedDate = booking.date;
    String selectedTime = booking.time;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final availableTimes = teeTimes
                    .where(
                      (time) => !isSlotBooked(
                        bookings: bookings,
                        date: selectedDate,
                        time: time,
                        bookingType: booking.type,
                        trainerName: booking.type == 'Golf Trainer'
                            ? booking.title
                            : null,
                        lane: booking.type == 'Golf Driving Range'
                            ? booking.lane
                            : null,
                        durationMinutes: booking.durationMinutes ?? 60,
                        excludedBookingId: booking.id,
                      ),
                    )
                    .toList();
                if (!availableTimes.contains(selectedTime)) {
                  selectedTime = '';
                }

                return ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  children: [
                    Text(
                      'Reschedule',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate.isBefore(now)
                              ? now
                              : selectedDate,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                            selectedTime = '';
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${selectedDate.toIso8601String()}-$selectedTime',
                      ),
                      initialValue: selectedTime.isEmpty ? null : selectedTime,
                      decoration: const InputDecoration(
                        labelText: 'New time',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      items: availableTimes
                          .map(
                            (time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedTime = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SlotAvailability(
                      selectedDate: selectedDate,
                      bookings: bookings,
                      teeTimes: teeTimes,
                      bookingType: booking.type,
                      lanes: booking.type == 'Golf Driving Range'
                          ? ((booking.laneId ?? booking.lane) == null
                                ? drivingRangeLanes
                                : [(booking.laneId ?? booking.lane)!])
                          : const [],
                      durationMinutes: booking.durationMinutes ?? 60,
                      trainerName: booking.type == 'Golf Trainer'
                          ? booking.title
                          : null,
                      excludedBookingId: booking.id,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: selectedTime.isEmpty
                          ? null
                          : () async {
                              final shouldReschedule = await _confirmReschedule(
                                context,
                                booking,
                                selectedDate,
                                selectedTime,
                              );
                              if (shouldReschedule != true) return;
                              if (!sheetContext.mounted) return;

                              onReschedule(
                                booking.id,
                                selectedDate,
                                selectedTime,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                      icon: const Icon(Icons.update_rounded),
                      label: const Text('Save Changes'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmReschedule(
    BuildContext context,
    Booking booking,
    DateTime selectedDate,
    String selectedTime,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reschedule Booking?'),
        content: Text(
          'Move ${booking.title} to ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $selectedTime?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Current'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onDelete,
    required this.onReschedule,
  });

  final Booking booking;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final isTrainerBooking = booking.type == 'Golf Trainer';
    final canDelete =
        booking.status == BookingStatus.cancelled ||
        booking.status == BookingStatus.paymentRejected ||
        booking.status == BookingStatus.expired;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.darkGreen,
                  child: Icon(
                    booking.type == 'Golf Trainer'
                        ? Icons.school_rounded
                        : Icons.sports_golf_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.type,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(booking.title),
                    ],
                  ),
                ),
                _StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${booking.date.day}/${booking.date.month}/${booking.date.year}',
                ),
                if (!isTrainerBooking) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(booking.startTime ?? booking.time),
                  if (booking.endTime != null) Text(' - ${booking.endTime}'),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (!isTrainerBooking && booking.duration != null) ...[
              Row(
                children: [
                  const Icon(Icons.timelapse_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Duration: ${booking.duration}'),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (booking.lane != null) ...[
              Row(
                children: [
                  const Icon(Icons.view_week_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Lane ${booking.laneId ?? booking.lane}'),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (isTrainerBooking) ...[
              if (booking.trainingClassType != null) ...[
                Row(
                  children: [
                    const Icon(Icons.leaderboard_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('Class type: ${booking.trainingClassType}'),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (booking.trainerPhoneNumber != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(booking.trainerPhoneNumber!)),
                    TextButton.icon(
                      onPressed: () =>
                          _openWhatsApp(booking.trainerPhoneNumber!),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (booking.trainerEmail != null) ...[
                Row(
                  children: [
                    const Icon(Icons.email_rounded, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(booking.trainerEmail!)),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const Row(
                children: [
                  Icon(Icons.handshake_rounded, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Arrange time, price and training slot with the trainer',
                    ),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${booking.amount} - ${booking.paymentMethod}'),
                  ),
                ],
              ),
            if (booking.paymentReference != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Reference: ${booking.paymentReference}'),
                  ),
                ],
              ),
            ],
            if (booking.paymentReceiptName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.upload_file_rounded, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Uploaded receipt: ${booking.paymentReceiptName}',
                    ),
                  ),
                ],
              ),
            ],
            if (booking.receiptNumber != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_rounded,
                        color: AppTheme.mediumGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Receipt',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('Receipt: ${booking.receiptNumber}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _BookingStatusMessage(booking: booking),
            const SizedBox(height: 14),
            if (canDelete)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Delete Booking'),
                ),
              )
            else
              Row(
                children: [
                  if (!isTrainerBooking) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReschedule,
                        icon: const Icon(Icons.update_rounded),
                        label: const Text('Reschedule'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openWhatsApp(String phoneNumber) async {
  final normalizedNumber = _normalizeMalaysiaPhoneNumber(phoneNumber);
  final uri = Uri.parse('https://wa.me/$normalizedNumber');

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not open WhatsApp for $phoneNumber');
  }
}

String _normalizeMalaysiaPhoneNumber(String phoneNumber) {
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('60')) return digits;
  if (digits.startsWith('0')) return '60${digits.substring(1)}';
  return digits;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      BookingStatus.reserved => 'Reserved',
      BookingStatus.pendingVerification => 'Pending Verification',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.paymentRejected => 'Payment Rejected',
      BookingStatus.expired => 'Expired',
      BookingStatus.cancelled => 'Cancelled',
      BookingStatus.rescheduled => 'Rescheduled',
    };
    final color = switch (status) {
      BookingStatus.reserved => Colors.blue.shade700,
      BookingStatus.pendingVerification => Colors.amber.shade900,
      BookingStatus.confirmed => AppTheme.darkGreen,
      BookingStatus.paymentRejected => Colors.red.shade800,
      BookingStatus.expired => Colors.grey.shade700,
      BookingStatus.cancelled => Colors.red.shade700,
      BookingStatus.rescheduled => Colors.orange.shade800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BookingStatusMessage extends StatelessWidget {
  const _BookingStatusMessage({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final message = switch (booking.status) {
      BookingStatus.reserved =>
        booking.type == 'Golf Trainer'
            ? 'Trainer booking saved. Contact the trainer to discuss the training session price.'
            : 'Reserved for pay at counter. Counter staff will confirm it when you arrive. If it is not confirmed within 10 minutes after the booking time, admin may cancel it manually.',
      BookingStatus.pendingVerification =>
        'Your QR payment is awaiting admin verification. A receipt will appear here after confirmation.',
      BookingStatus.confirmed =>
        booking.type == 'Golf Trainer'
            ? 'Your trainer booking has been confirmed.'
            : 'Your booking and payment have been confirmed.',
      BookingStatus.paymentRejected =>
        'The submitted payment could not be verified. Please contact the administrator.',
      BookingStatus.expired =>
        'This booking was marked expired or cancelled by admin because confirmation was not completed in time.',
      BookingStatus.cancelled => 'This booking has been cancelled.',
      BookingStatus.rescheduled =>
        'This booking was rescheduled. Check the updated date and time above.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
