import 'package:flutter/material.dart';
import '../../services/admin_ai_service.dart';

class AdminAIPage extends StatefulWidget {
  const AdminAIPage({super.key});

  @override
  State<AdminAIPage> createState() => _AdminAIPageState();
}

class _AdminAIPageState extends State<AdminAIPage> {
  final _adminAIService = AdminAIService();
  String _report = "Tekan tombol di bawah untuk meminta AI menganalisis data.";
  bool _isLoading = false;

  void _generateReport() async {
    setState(() => _isLoading = true);
    final result = await _adminAIService.getBusinessAnalysis();
    setState(() {
      _report = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Business Analyst"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 100,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        )
                      : Text(
                          _report,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: const Icon(Icons.psychology),
                label: const Text("GENERATE AI REPORT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
