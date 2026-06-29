import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/dummy_data.dart';

class PaymentQrSettings {
  const PaymentQrSettings({required this.data, this.imageUrl});

  final String data;
  final String? imageUrl;
}

class PaymentSettingsService {
  PaymentSettingsService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  static const _settingsTable = 'system_settings';

  Future<PaymentQrSettings> loadQrSettings() async {
    try {
      final client = _client ?? Supabase.instance.client;
      final rows = await client
          .from(_settingsTable)
          .select('setting_key,setting_value')
          .inFilter('setting_key', [
            'qr_payment_data',
            'qr_payment_image_url',
            'payment_qr_url',
            'payment_instruction',
          ]);

      String? data;
      String? imageUrl;
      for (final row in rows) {
        final key = row['setting_key'] as String?;
        final value = row['setting_value']?.toString().trim();
        if (value == null || value.isEmpty) continue;
        if (value == 'PASTE_YOUR_SUPABASE_STORAGE_QR_IMAGE_PUBLIC_URL_HERE') {
          continue;
        }
        if (key == 'qr_payment_data') data = value;
        if (key == 'qr_payment_image_url' || key == 'payment_qr_url') {
          imageUrl = value;
        }
        data ??= key == 'payment_instruction' ? value : null;
      }

      return PaymentQrSettings(
        data: data ?? DummyData.qrPaymentData,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return const PaymentQrSettings(data: DummyData.qrPaymentData);
    }
  }
}
