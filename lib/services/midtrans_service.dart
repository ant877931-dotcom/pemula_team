import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  final String serverKey = "SB-Mid-server-EglgwV4vUg8Pt4H_w5XhxXva";

  Future<String?> getSnapToken({
    required String orderId,
    required double amount,
    required String username,
    required String email,
  }) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    try {
      final response = await http.post(
        Uri.parse('https://app.sandbox.midtrans.com/snap/v1/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": amount.toInt(),
          },
          "customer_details": {"first_name": username, "email": email},
          "expiry": {"unit": "minutes", "duration": 60},
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['token'];
      } else {
        print("Midtrans Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Midtrans Exception: $e");
      return null;
    }
  }
}
