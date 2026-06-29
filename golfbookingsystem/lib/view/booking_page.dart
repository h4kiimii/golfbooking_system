import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dummy_data.dart';
import '../model/booking.dart';
import '../model/driving_range_package.dart';
import '../model/trainer.dart';
import '../services/lane_availability_service.dart';
import '../services/payment_settings_service.dart';
import '../services/payment_receipt_service.dart';
import '../theme/app_theme.dart';
import 'widgets/profile_image.dart';
import 'widgets/slot_availability.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({
    super.key,
    required this.packages,
    required this.trainers,
    required this.bookings,
    required this.teeTimes,
    required this.drivingRangeLanes,
    required this.paymentMethods,
    required this.onBookingCreated,
  });

  final List<DrivingRangePackage> packages;
  final List<Trainer> trainers;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final List<String> drivingRangeLanes;
  final List<String> paymentMethods;
  final ValueChanged<Booking> onBookingCreated;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.softGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.darkGreen,
                tabs: [
                  Tab(
                    icon: Icon(Icons.sports_golf_rounded),
                    text: 'Driving Range',
                  ),
                  Tab(icon: Icon(Icons.school_rounded), text: 'Trainer'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DrivingRangeBookingForm(
                  packages: packages,
                  bookings: bookings,
                  teeTimes: teeTimes,
                  lanes: drivingRangeLanes,
                  paymentMethods: paymentMethods,
                  onBookingCreated: onBookingCreated,
                ),
                _TrainerBookingForm(
                  trainers: trainers,
                  bookings: bookings,
                  teeTimes: teeTimes,
                  onBookingCreated: onBookingCreated,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrivingRangeBookingForm extends StatefulWidget {
  const _DrivingRangeBookingForm({
    required this.packages,
    required this.bookings,
    required this.teeTimes,
    required this.lanes,
    required this.paymentMethods,
    required this.onBookingCreated,
  });

  final List<DrivingRangePackage> packages;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final List<String> lanes;
  final List<String> paymentMethods;
  final ValueChanged<Booking> onBookingCreated;

  @override
  State<_DrivingRangeBookingForm> createState() =>
      _DrivingRangeBookingFormState();
}

class _DrivingRangeBookingFormState extends State<_DrivingRangeBookingForm> {
  final _formKey = GlobalKey<FormState>();
  late DrivingRangePackage _selectedPackage;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedLane;
  _BookingDuration _selectedDuration = _bookingDurations.first;
  String _customerType = 'Non-member';
  late String _paymentMethod;
  bool _paymentConfirmed = false;
  String? _receiptFileName;
  String? _receiptFileUrl;
  int _bucketQuantity = 1;
  bool _showDateError = false;
  bool _isLoadingLaneBlocks = false;
  int _laneBlockRequestId = 0;
  Map<String, Set<String>> _blockedLanesByTime = const {};

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.packages.first;
    _paymentMethod = widget.paymentMethods.first;
    _paymentConfirmed = !_isQrPayment(_paymentMethod);
  }

  double get _pricePerBucket {
    final price = _customerType == 'Member'
        ? _selectedPackage.memberPrice
        : _selectedPackage.nonMemberPrice;
    return double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  String get _totalPrice {
    final total = _pricePerBucket * _bucketQuantity;
    return 'RM ${total == total.roundToDouble() ? total.toStringAsFixed(0) : total.toStringAsFixed(2)}';
  }

  int get _totalBalls => _selectedPackage.balls * _bucketQuantity;

  List<String> get _availableTimes {
    if (_selectedDate == null) return const [];
    return widget.teeTimes
        .where(
          (time) => widget.lanes.any(
            (lane) => !_isLaneBlocked(lane: lane, time: time),
          ),
        )
        .toList();
  }

  List<String> get _availableLanes {
    if (_selectedDate == null || _selectedTime == null) return const [];
    return widget.lanes
        .where((lane) => !_isLaneBlocked(lane: lane, time: _selectedTime!))
        .toList();
  }

  bool _isLaneBlocked({required String lane, required String time}) {
    if (_selectedDate == null) return false;
    final normalizedLane = lane.toUpperCase();
    final remoteBlocked =
        _blockedLanesByTime[time]?.contains(normalizedLane) ?? false;
    if (remoteBlocked) return true;

    return isLaneTimeBooked(
      bookings: widget.bookings,
      date: _selectedDate!,
      time: time,
      lane: lane,
      durationMinutes: _selectedDuration.minutes,
    );
  }

  void _setDuration(_BookingDuration duration) {
    setState(() {
      _selectedDuration = duration;
      _selectedLane = null;
      if (_selectedTime != null && !_availableTimes.contains(_selectedTime)) {
        _selectedTime = null;
      }
    });
    _loadRemoteLaneBlocks();
  }

  String get _endTime {
    if (_selectedDate == null || _selectedTime == null) {
      return 'Select start time';
    }

    final start = bookingDateTime(_selectedDate!, _selectedTime!);
    if (start == null) return 'Select start time';

    return formatBookingTime(
      start.add(Duration(minutes: _selectedDuration.minutes)),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _selectedLane = null;
        _showDateError = false;
        _blockedLanesByTime = const {};
      });
      _loadRemoteLaneBlocks();
    }
  }

  Future<void> _loadRemoteLaneBlocks() async {
    final date = _selectedDate;
    if (date == null || widget.teeTimes.isEmpty) return;

    final requestId = ++_laneBlockRequestId;
    setState(() => _isLoadingLaneBlocks = true);
    try {
      final service = LaneAvailabilityService();
      final entries = await Future.wait(
        widget.teeTimes.map((time) async {
          final lanes = await service.blockedLanes(
            date: date,
            time: time,
            durationMinutes: _selectedDuration.minutes,
          );
          return MapEntry(time, lanes);
        }),
      );

      if (!mounted || requestId != _laneBlockRequestId) return;
      setState(() {
        _blockedLanesByTime = Map<String, Set<String>>.fromEntries(entries);
        if (_selectedTime != null && !_availableTimes.contains(_selectedTime)) {
          _selectedTime = null;
          _selectedLane = null;
        } else if (_selectedLane != null &&
            !_availableLanes.contains(_selectedLane)) {
          _selectedLane = null;
        }
      });
    } catch (_) {
      if (!mounted || requestId != _laneBlockRequestId) return;
      setState(() => _blockedLanesByTime = const {});
    } finally {
      if (mounted && requestId == _laneBlockRequestId) {
        setState(() => _isLoadingLaneBlocks = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      setState(() => _showDateError = _selectedDate == null);
      return;
    }

    final isQrPayment = _isQrPayment(_paymentMethod);
    final paymentReference = isQrPayment
        ? _generateReference('PAY')
        : _generateReference('RES');

    widget.onBookingCreated(
      Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Golf Driving Range',
        title:
            '$_bucketQuantity x ${_selectedPackage.name} ($_totalBalls balls) - $_customerType',
        date: _selectedDate!,
        time: _selectedTime!,
        amount: _totalPrice,
        paymentMethod: _paymentMethod,
        status: isQrPayment
            ? BookingStatus.pendingVerification
            : BookingStatus.reserved,
        startTime: _selectedTime,
        endTime: _endTime,
        duration: _selectedDuration.label,
        durationMinutes: _selectedDuration.minutes,
        lane: _selectedLane,
        laneId: _selectedLane,
        paymentReference: paymentReference,
        paymentReceiptName: _receiptFileName,
        paymentReceiptUrl: _receiptFileUrl,
        paymentReceiptUploadedAt: isQrPayment ? DateTime.now() : null,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isQrPayment
              ? 'Payment submitted for admin verification.'
              : 'Slot reserved. Confirm and pay at the counter before your session.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Golf Driving Range Booking',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<DrivingRangePackage>(
                initialValue: _selectedPackage,
                decoration: const InputDecoration(
                  labelText: 'Ball bucket',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                items: widget.packages
                    .map(
                      (package) => DropdownMenuItem(
                        value: package,
                        child: Text('${package.balls} balls'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPackage = value;
                      _paymentConfirmed = false;
                      _receiptFileName = null;
                      _receiptFileUrl = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _customerType,
                decoration: const InputDecoration(
                  labelText: 'Customer type',
                  prefixIcon: Icon(Icons.card_membership_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Non-member',
                    child: Text('Non-member'),
                  ),
                  DropdownMenuItem(value: 'Member', child: Text('Member')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _customerType = value;
                    _paymentConfirmed = false;
                    _receiptFileName = null;
                    _receiptFileUrl = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              _PackagePreview(
                package: _selectedPackage,
                customerType: _customerType,
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Select date',
                selectedDate: _selectedDate,
                onTap: _pickDate,
                showError: _showDateError,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedDate),
                initialValue: _selectedTime,
                decoration: const InputDecoration(
                  labelText: 'Select available slot',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
                items: _availableTimes
                    .map(
                      (time) =>
                          DropdownMenuItem(value: time, child: Text(time)),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedTime = value;
                  _selectedLane = null;
                }),
                validator: (value) =>
                    value == null ? 'Select an available slot' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_BookingDuration>(
                initialValue: _selectedDuration,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.timelapse_rounded),
                ),
                items: _bookingDurations
                    .map(
                      (duration) => DropdownMenuItem(
                        value: duration,
                        child: Text(duration.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _setDuration(value);
                },
              ),
              const SizedBox(height: 12),
              _EndTimePreview(startTime: _selectedTime, endTime: _endTime),
              const SizedBox(height: 12),
              SlotAvailability(
                selectedDate: _selectedDate,
                bookings: widget.bookings,
                teeTimes: widget.teeTimes,
                bookingType: 'Golf Driving Range',
                lanes: widget.lanes,
                blockedLanesByTime: _blockedLanesByTime,
                durationMinutes: _selectedDuration.minutes,
              ),
              if (_isLoadingLaneBlocks) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 3),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  '${_selectedDate?.toIso8601String()}-$_selectedTime-${_selectedDuration.minutes}',
                ),
                initialValue: _selectedLane,
                decoration: const InputDecoration(
                  labelText: 'Select available lane',
                  prefixIcon: Icon(Icons.view_week_rounded),
                ),
                items: _availableLanes
                    .map(
                      (lane) =>
                          DropdownMenuItem(value: lane, child: Text(lane)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedLane = value),
                validator: (value) =>
                    value == null ? 'Select an available lane' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _bucketQuantity,
                decoration: const InputDecoration(
                  labelText: 'Number of buckets',
                  prefixIcon: Icon(Icons.shopping_basket_rounded),
                ),
                items: List.generate(10, (index) => index + 1).map((quantity) {
                  return DropdownMenuItem(
                    value: quantity,
                    child: Text(
                      '$quantity ${quantity == 1 ? 'bucket' : 'buckets'}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _bucketQuantity = value;
                    _paymentConfirmed = false;
                    _receiptFileName = null;
                    _receiptFileUrl = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calculate_rounded,
                        color: AppTheme.darkGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_bucketQuantity x ${_selectedPackage.balls} balls = $_totalBalls balls',
                        ),
                      ),
                      Text(
                        _totalPrice,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _PaymentSection(
                amount: _totalPrice,
                paymentMethods: widget.paymentMethods,
                paymentMethod: _paymentMethod,
                paymentConfirmed: _paymentConfirmed,
                receiptFileName: _receiptFileName,
                onPaymentMethodChanged: (value) => setState(() {
                  _paymentMethod = value;
                  _paymentConfirmed = !_isQrPayment(value);
                  if (!_isQrPayment(value)) {
                    _receiptFileName = null;
                    _receiptFileUrl = null;
                  }
                }),
                onPaymentConfirmed: (value) =>
                    setState(() => _paymentConfirmed = value),
                onReceiptUploaded: (name, url) => setState(() {
                  _receiptFileName = name;
                  _receiptFileUrl = url;
                  _paymentConfirmed = name != null && url != null;
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Submit Booking'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrainerBookingForm extends StatefulWidget {
  const _TrainerBookingForm({
    required this.trainers,
    required this.bookings,
    required this.teeTimes,
    required this.onBookingCreated,
  });

  final List<Trainer> trainers;
  final List<Booking> bookings;
  final List<String> teeTimes;
  final ValueChanged<Booking> onBookingCreated;

  @override
  State<_TrainerBookingForm> createState() => _TrainerBookingFormState();
}

class _TrainerBookingFormState extends State<_TrainerBookingForm> {
  final _formKey = GlobalKey<FormState>();
  late Trainer _selectedTrainer;
  DateTime? _selectedDate;
  String _selectedClassType = 'Beginner';
  bool _showDateError = false;
  static const _classTypes = [
    'Beginner',
    'Intermediate',
    'Amateur',
    'Professional',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTrainer = widget.trainers.first;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showDateError = false;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      setState(() => _showDateError = _selectedDate == null);
      return;
    }

    widget.onBookingCreated(
      Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Golf Trainer',
        title: _selectedTrainer.name,
        date: _selectedDate!,
        time: 'Arrange with trainer',
        startTime: 'Arrange with trainer',
        amount: 'To be negotiated',
        paymentMethod: 'Arrange with trainer',
        status: BookingStatus.reserved,
        trainerPhoneNumber: _selectedTrainer.phoneNumber,
        trainerEmail: _selectedTrainer.email,
        trainingClassType: _selectedClassType,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Trainer booking saved. Contact the trainer to discuss the session price.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Golf Trainer Booking',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Trainer>(
                initialValue: _selectedTrainer,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select trainer',
                  prefixIcon: Icon(Icons.person_search_rounded),
                ),
                items: widget.trainers
                    .map(
                      (trainer) => DropdownMenuItem(
                        value: trainer,
                        child: Text(trainer.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTrainer = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              _TrainerPreview(trainer: _selectedTrainer),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedClassType,
                decoration: const InputDecoration(
                  labelText: 'Training class type',
                  prefixIcon: Icon(Icons.leaderboard_rounded),
                ),
                items: _classTypes
                    .map(
                      (classType) => DropdownMenuItem(
                        value: classType,
                        child: Text(classType),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedClassType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Select date',
                selectedDate: _selectedDate,
                onTap: _pickDate,
                showError: _showDateError,
              ),
              const SizedBox(height: 12),
              const _TrainerArrangementNotice(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openWhatsApp(_selectedTrainer.phoneNumber),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Discuss Time, Price and Slot'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Submit Booking'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentSection extends StatefulWidget {
  const _PaymentSection({
    required this.amount,
    required this.paymentMethods,
    required this.paymentMethod,
    required this.paymentConfirmed,
    required this.receiptFileName,
    required this.onPaymentMethodChanged,
    required this.onPaymentConfirmed,
    required this.onReceiptUploaded,
  });

  final String amount;
  final List<String> paymentMethods;
  final String paymentMethod;
  final bool paymentConfirmed;
  final String? receiptFileName;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<bool> onPaymentConfirmed;
  final void Function(String? name, String? url) onReceiptUploaded;

  @override
  State<_PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<_PaymentSection> {
  late final Future<PaymentQrSettings> _qrSettingsFuture;
  bool _isUploadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _qrSettingsFuture = PaymentSettingsService().loadQrSettings();
  }

  Future<void> _uploadReceipt(FormFieldState<bool> field) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _isUploadingReceipt = true);
    try {
      final receipt = await PaymentReceiptService().uploadReceipt(
        bytes: await picked.readAsBytes(),
        fileName: picked.name,
      );
      if (!mounted) return;
      field.didChange(true);
      widget.onReceiptUploaded(receipt.name, receipt.url);
      widget.onPaymentConfirmed(true);
    } catch (error) {
      if (!mounted) return;
      field.didChange(false);
      widget.onReceiptUploaded(null, null);
      widget.onPaymentConfirmed(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload receipt: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingReceipt = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: widget.paymentConfirmed,
      validator: (_) =>
          !_isQrPayment(widget.paymentMethod) || widget.paymentConfirmed
          ? null
          : 'Upload your QR payment receipt',
      builder: (field) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: widget.paymentMethod,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                items: widget.paymentMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  field.didChange(!_isQrPayment(value));
                  widget.onPaymentMethodChanged(value);
                  if (!_isQrPayment(value)) {
                    widget.onReceiptUploaded(null, null);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _isQrPayment(widget.paymentMethod)
                        ? Icons.qr_code_2_rounded
                        : Icons.storefront_rounded,
                    color: AppTheme.darkGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.paymentMethod,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    widget.amount,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (_isQrPayment(widget.paymentMethod)) ...[
                const SizedBox(height: 12),
                const Text(
                  'Scan this QR code with your preferred banking or e-wallet app, then upload your payment receipt for admin verification.',
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: FutureBuilder<PaymentQrSettings>(
                      future: _qrSettingsFuture,
                      builder: (context, snapshot) {
                        final settings =
                            snapshot.data ??
                            const PaymentQrSettings(
                              data: DummyData.qrPaymentData,
                            );
                        final imageUrl = settings.imageUrl;
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          return Image.network(
                            imageUrl,
                            width: 190,
                            height: 190,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _GeneratedQrCode(
                              data: settings.data,
                              amount: widget.amount,
                            ),
                          );
                        }

                        return _GeneratedQrCode(
                          data: settings.data,
                          amount: widget.amount,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isUploadingReceipt
                      ? null
                      : () => _uploadReceipt(field),
                  icon: Icon(
                    _isUploadingReceipt
                        ? Icons.hourglass_top_rounded
                        : Icons.upload_file_rounded,
                  ),
                  label: Text(
                    _isUploadingReceipt
                        ? 'Uploading Receipt...'
                        : widget.receiptFileName == null
                        ? 'Upload Payment Receipt'
                        : 'Replace Receipt',
                  ),
                ),
                if (widget.receiptFileName != null) ...[
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.darkGreen,
                    ),
                    title: const Text('Receipt uploaded'),
                    subtitle: Text(widget.receiptFileName!),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'Your booking will be recorded now. Counter staff can confirm it when you arrive.',
                ),
              ],
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneratedQrCode extends StatelessWidget {
  const _GeneratedQrCode({required this.data, required this.amount});

  final String data;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: '$data?amount=${Uri.encodeComponent(amount)}',
      size: 190,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppTheme.darkGreen,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppTheme.charcoal,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.selectedDate,
    required this.onTap,
    required this.showError,
  });

  final String label;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final value = selectedDate == null
        ? 'Choose date'
        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_month_rounded),
            ),
            child: Text(value),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 6),
            child: Text(
              'Select a date',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _BookingDuration {
  const _BookingDuration({required this.label, required this.minutes});

  final String label;
  final int minutes;
}

const _bookingDurations = [
  _BookingDuration(label: '1 hour', minutes: 60),
  _BookingDuration(label: '1 hour 30 minutes', minutes: 90),
  _BookingDuration(label: '2 hours', minutes: 120),
];

class _EndTimePreview extends StatelessWidget {
  const _EndTimePreview({required this.startTime, required this.endTime});

  final String? startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.update_rounded, color: AppTheme.darkGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                startTime == null
                    ? 'End time will be calculated after start time is selected.'
                    : 'End time: $endTime',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerArrangementNotice extends StatelessWidget {
  const _TrainerArrangementNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_rounded, color: AppTheme.darkGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Time, price and training slot will be arranged directly with the trainer through WhatsApp.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackagePreview extends StatelessWidget {
  const _PackagePreview({required this.package, required this.customerType});

  final DrivingRangePackage package;
  final String customerType;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.darkGreen,
              child: Icon(Icons.sports_golf_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.description),
                  const SizedBox(height: 4),
                  Text(
                    '${package.balls} balls per bucket - '
                    '${customerType == 'Member' ? package.memberPrice : package.nonMemberPrice}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerPreview extends StatelessWidget {
  const _TrainerPreview({required this.trainer});

  final Trainer trainer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileImage(
                  imagePath: trainer.imagePath,
                  radius: 32,
                  icon: Icons.sports_golf_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trainer.level,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TrainerContactRow(
              icon: Icons.workspace_premium_rounded,
              text: trainer.level,
            ),
            const SizedBox(height: 8),
            _TrainerContactRow(
              icon: Icons.phone_rounded,
              text: trainer.phoneNumber,
              actionLabel: 'WhatsApp',
              onTap: () => _openWhatsApp(trainer.phoneNumber),
            ),
            const SizedBox(height: 8),
            _TrainerContactRow(
              icon: Icons.email_rounded,
              text: trainer.email ?? 'Email not provided',
            ),
            const SizedBox(height: 10),
            const Text(
              'Training price will be discussed directly with the trainer.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerContactRow extends StatelessWidget {
  const _TrainerContactRow({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.darkGreen, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
        if (onTap != null && actionLabel != null)
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: Text(actionLabel!),
          ),
      ],
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

bool _isQrPayment(String method) {
  return method.toLowerCase().contains('qr');
}

String _generateReference(String prefix) {
  final value = DateTime.now().microsecondsSinceEpoch.toString();
  return '$prefix-${value.substring(value.length - 8)}';
}
