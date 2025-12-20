import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAIService {
  final String apiKey = "sk-qz1-zMuj5405dY1rB2ao-w";
  final String baseUrl = "https://litellm.koboi2026.biz.id/v1/chat/completions";

  Future<String> getBusinessAnalysis() async {
    try {
      // 1. Ambil data mentah untuk konteks AI
      final txData = await Supabase.instance.client
          .from('transactions')
          .select();
      final userData = await Supabase.instance.client
          .from('profiles')
          .select('id');

      // 2. Olah ringkasan sederhana agar AI tidak bingung
      double totalIn = 0;
      double totalOut = 0;
      for (var tx in txData) {
        double amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'deposit' || tx['type'] == 'transfer_in') {
          totalIn += amount;
        } else {
          totalOut += amount;
        }
      }

      String systemContext =
          """
        Kamu adalah 'Senior Business Analyst' untuk Bank Digital.
        Data saat ini:
        - Total Transaksi: ${txData.length}
        - Total User: ${userData.length}
        - Total Uang Masuk: Rp $totalIn
        - Total Uang Keluar: Rp $totalOut
        
        Tugasmu: Berikan laporan singkat (3-4 poin) mengenai kondisi kesehatan bank dan saran strategi pemasaran atau keamanan.
      """;

      // 3. Panggil LiteLLM
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": systemContext},
            {
              "role": "user",
              "content": "Berikan analisis performa bank hari ini.",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return "Gagal mendapatkan analisis AI.";
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }
}
