import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/dummy_data.dart';
import '../model/driving_range_package.dart';
import '../model/trainer.dart';

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.packages,
    required this.trainers,
    required this.teeTimes,
    required this.drivingRangeLanes,
    required this.paymentMethods,
    required this.contactSettings,
    required this.backgroundSettings,
  });

  final List<DrivingRangePackage> packages;
  final List<Trainer> trainers;
  final List<String> teeTimes;
  final List<String> drivingRangeLanes;
  final List<String> paymentMethods;
  final ContactSettings contactSettings;
  final AppBackgroundSettings backgroundSettings;
}

class ContactSettings {
  const ContactSettings({
    this.phone = '014 813 4213',
    this.email = 'dingolfzero@gmail.com',
    this.address =
        'Universiti Pendidikan Sultan Idris, 35900 Tanjong Malim, '
        'Perak Darul Ridzuan, Malaysia',
    this.operatingHours = '10:00 AM - 11:00 PM',
  });

  final String phone;
  final String email;
  final String address;
  final String operatingHours;

  ContactSettings copyWith({
    String? phone,
    String? email,
    String? address,
    String? operatingHours,
  }) {
    return ContactSettings(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }
}

class AppBackgroundSettings {
  const AppBackgroundSettings({this.loginUrl, this.appUrl});

  final String? loginUrl;
  final String? appUrl;
}

class AppDataService {
  AppDataService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppDataSnapshot> load() async {
    final packages = await _loadPackages();
    final trainers = await _loadTrainers();
    final teeTimes = await _loadTeeTimes();
    final lanes = await _loadDrivingRangeLanes();
    final paymentMethods = await _loadPaymentMethods();
    final contactSettings = await _loadContactSettings();
    final backgroundSettings = await _loadBackgroundSettings();

    return AppDataSnapshot(
      packages: packages.isEmpty
          ? List.of(DummyData.drivingRangePackages)
          : packages,
      trainers: trainers.isEmpty ? List.of(DummyData.trainers) : trainers,
      teeTimes: teeTimes.isEmpty ? List.of(DummyData.availableTimes) : teeTimes,
      drivingRangeLanes: lanes.isEmpty
          ? List.of(DummyData.drivingRangeLanes)
          : lanes,
      paymentMethods: paymentMethods.isEmpty
          ? List.of(DummyData.paymentMethods)
          : paymentMethods,
      contactSettings: contactSettings,
      backgroundSettings: backgroundSettings,
    );
  }

  Future<List<DrivingRangePackage>> _loadPackages() async {
    try {
      final rows = await _client
          .from('bucket_options')
          .select()
          .order('ball_count', ascending: true);

      return rows
          .map<DrivingRangePackage>((row) {
            final balls = _intValue(row, ['ball_count', 'balls']);
            final name =
                _textValue(row, ['bucket_name', 'label', 'name']) ??
                '${balls <= 0 ? 0 : balls}-Ball Bucket';
            return DrivingRangePackage(
              name: name,
              description:
                  _textValue(row, ['description']) ??
                  'One bucket containing $balls driving-range balls.',
              nonMemberPrice: _moneyText(
                _numberValue(row, ['non_member_price', 'price']),
              ),
              memberPrice: _moneyText(_numberValue(row, ['member_price'])),
              balls: balls,
            );
          })
          .where((package) => package.balls > 0)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Trainer>> _loadTrainers() async {
    try {
      final rows = await _client
          .from('trainers')
          .select()
          .order('full_name', ascending: true);

      return rows
          .map<Trainer>((row) {
            return Trainer(
              name:
                  _textValue(row, ['full_name', 'name', 'trainer_name']) ??
                  'Trainer',
              phoneNumber:
                  _textValue(row, [
                    'whatsapp_phone',
                    'phone',
                    'phone_number',
                  ]) ??
                  '',
              email: _textValue(row, ['email']),
              imagePath: _textValue(row, [
                'profile_image_url',
                'image_url',
                'image',
              ]),
              level:
                  _textValue(row, [
                    'level',
                    'qualification',
                    'specialist',
                    'speciality',
                  ]) ??
                  Trainer.defaultLevel,
            );
          })
          .where((trainer) => trainer.name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadTeeTimes() async {
    try {
      final rows = await _client
          .from('tee_slots')
          .select('slot_time,status,slot_type')
          .order('slot_time', ascending: true);
      final times = <String>{};
      for (final row in rows) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        final type = (row['slot_type'] ?? '').toString().toLowerCase();
        if (status.contains('inactive') || status.contains('unavailable')) {
          continue;
        }
        if (type.isNotEmpty && !type.contains('driving')) continue;
        final time = _formatTime(row['slot_time']?.toString());
        if (time != null) times.add(time);
      }
      return times.toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadDrivingRangeLanes() async {
    try {
      final rows = await _client.from('driving_range_lanes').select();
      final lanes = <String>[];
      for (final row in rows) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        if (status.contains('inactive') || status.contains('unavailable')) {
          continue;
        }
        final code = _textValue(row, [
          'lane_code',
          'code',
          'name',
          'lane_name',
        ]);
        if (code != null && code.isNotEmpty) lanes.add(code.toUpperCase());
      }
      lanes.sort();
      return lanes;
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadPaymentMethods() async {
    try {
      final rows = await _client
          .from('system_settings')
          .select('setting_key,setting_value')
          .inFilter('setting_key', ['payment_methods']);
      if (rows.isEmpty) return const [];

      final raw = rows.first['setting_value']?.toString() ?? '';
      return raw
          .split(RegExp(r'[,|]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<ContactSettings> _loadContactSettings() async {
    const fallback = ContactSettings();
    try {
      final rows = await _client
          .from('system_settings')
          .select('setting_key,setting_value')
          .inFilter('setting_key', [
            'contact_phone',
            'contact_email',
            'contact_address',
            'operating_hours',
          ]);
      if (rows.isEmpty) return fallback;

      final values = <String, String>{};
      for (final row in rows) {
        final key = row['setting_key']?.toString();
        final value = row['setting_value']?.toString().trim();
        if (key != null && value != null && value.isNotEmpty) {
          values[key] = value;
        }
      }

      return fallback.copyWith(
        phone: values['contact_phone'],
        email: values['contact_email'],
        address: values['contact_address'],
        operatingHours: values['operating_hours'],
      );
    } catch (_) {
      return fallback;
    }
  }

  Future<AppBackgroundSettings> _loadBackgroundSettings() async {
    try {
      final rows = await _client
          .from('system_settings')
          .select('setting_key,setting_value')
          .inFilter('setting_key', [
            'login_background_url',
            'app_background_url',
          ]);

      String? loginUrl;
      String? appUrl;
      for (final row in rows) {
        final key = row['setting_key']?.toString();
        final value = row['setting_value']?.toString().trim();
        if (value == null || value.isEmpty) continue;
        if (key == 'login_background_url') loginUrl = value;
        if (key == 'app_background_url') appUrl = value;
      }
      return AppBackgroundSettings(loginUrl: loginUrl, appUrl: appUrl);
    } catch (_) {
      return const AppBackgroundSettings();
    }
  }

  String? _textValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  int _intValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double _numberValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _moneyText(double value) {
    final amount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return 'RM $amount';
  }

  String? _formatTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
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
