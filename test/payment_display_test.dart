import 'package:fixify_admin/helpers/payment_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows CASH for the reported UUID reference', () {
    const reference = 'CASH-cab15da9-15de-4f2a-a9ac-d15679ec996c';
    expect(paymentReferenceLabel(reference), 'CASH');
    expect(paymentReferenceLabel(' cash-12345 '), 'CASH');
    expect(paymentReferenceLabel('CASH'), 'CASH');
    expect(paymentReferenceLabel('pay_123456789'), 'pay_123456789');
    expect(paymentReferenceLabel(''), '');
  });

  test('extracts the actual QR image from the reported response shape', () {
    const url =
        'https://api.qrserver.com/v1/create-qr-code/'
        '?size=400x400&margin=10&data=https%3A%2F%2Frzp.io%2Frzp%2Fexample';
    expect(
      paymentQrImageValue({
        'success': true,
        'data': {
          'group_token': 'test-group',
          'qr_code_id': 'plink_test',
          'qr_code_url': url,
          'amount': 110.31,
          'currency': 'INR',
          'payment_status': 'pending',
        },
      }),
      url,
    );
  });

  test('prioritizes the QR image over unrelated or payment URLs', () {
    expect(
      paymentQrImageValue({
        'url': 'https://example.com',
        'payment_url': 'https://rzp.io/example',
        'qr_code': {'qr_code_url': 'https://example.com/qr.png'},
      }),
      'https://example.com/qr.png',
    );
  });

  test('never converts response maps, lists, or IDs into QR text', () {
    for (final value in [
      {
        'data': {'group_token': 'test', 'qr_code_id': 'plink_test'},
      },
      {
        'qr_code': {'id': 'plink_test'},
      },
      {
        'qr': ['invalid'],
      },
      {'qr_code_url': 123},
      {'payment_url': 'https://rzp.io/example'},
      {'data': ''},
    ]) {
      expect(paymentQrImageValue(value), isNull);
    }
  });

  test('supports legacy images and nested lists', () {
    expect(
      paymentQrImageValue({'data': 'data:image/png;base64,aGVsbG8='}),
      'data:image/png;base64,aGVsbG8=',
    );
    expect(
      paymentQrImageValue({
        'data': [
          {'qrImage': ' aGVsbG8= '},
        ],
      }),
      'aGVsbG8=',
    );
    expect(
      paymentQrImageValue({'qr_code_url': '', 'qr_image': 'aGVsbG8='}),
      'aGVsbG8=',
    );
  });
}
