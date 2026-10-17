/// Keeps backend cash references out of customer-facing payment labels.
String paymentReferenceLabel(String reference) {
  final value = reference.trim();
  if (value.toUpperCase() == 'CASH' ||
      value.toUpperCase().startsWith('CASH-')) {
    return 'CASH';
  }
  return reference;
}

/// Finds an image string without ever stringifying a response object.
String? paymentQrImageValue(Map<String, dynamic> data) {
  const imageKeys = [
    'qr_code_url',
    'qrCodeUrl',
    'qr_image_url',
    'qrImageUrl',
    'qr_image',
    'qrImage',
    'qr_code',
    'qrCode',
    'qr',
    'image',
    'url',
  ];

  String? findString(Object? value, String key) {
    if (value is Map) {
      final candidate = value[key];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
      for (final nested in value.values) {
        final found = findString(nested, key);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final nested in value) {
        final found = findString(nested, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  for (final key in imageKeys) {
    final value = findString(data, key);
    if (value != null) return value;
  }

  // Some older responses contain just the image string in `data`.
  final value = data['data'];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}
