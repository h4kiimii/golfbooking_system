import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class UploadedReceipt {
  const UploadedReceipt({required this.name, required this.url});

  final String name;
  final String url;
}

class PaymentReceiptService {
  PaymentReceiptService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bucket = 'payment-receipts';

  Future<UploadedReceipt> uploadReceipt({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Please log in before uploading a receipt.');
    }

    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension = extension == fileName ? 'jpg' : extension;
    final receiptName =
        'receipt-${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final path = '$userId/$receiptName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(safeExtension),
            upsert: true,
          ),
        );

    return UploadedReceipt(
      name: receiptName,
      url: _client.storage.from(_bucket).getPublicUrl(path),
    );
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
  }
}
