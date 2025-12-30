import 'package:flutter/material.dart';
import '../../services/admin_ai_service.dart';

class AdminAIPage extends StatefulWidget {
  const AdminAIPage({super.key});

  @override
  State<AdminAIPage> createState() => _AdminAIPageState();
}

class _AdminAIPageState extends State<AdminAIPage> {
  final _adminAIService = AdminAIService();
  String _report =
      "Tekan tombol di bawah untuk meminta AI menganalisis data sistem dan memberikan wawasan bisnis.";
  bool _isLoading = false;

  final Color colorTop = const Color(0xFF007AFF);
  final Color colorBottom = const Color(0xFF003366);
  final Color colorGold = const Color(0xFFFFD700);

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
      backgroundColor: const Color(0xFFF4F7FA),
      body: Stack(
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorTop, colorBottom],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "AI BUSINESS ANALYST",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: colorGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorGold, width: 2),
                  ),
                  child: Icon(Icons.auto_awesome, size: 45, color: colorGold),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: colorBottom.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: colorGold.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "ANALYSIS REPORT",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: colorBottom,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                              Icon(
                                Icons.analytics_outlined,
                                color: colorGold,
                                size: 20,
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: _isLoading
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 50),
                                          CircularProgressIndicator(
                                            color: colorTop,
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            "AI sedang mengumpulkan data...",
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: colorBottom.withOpacity(
                                                0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      _report,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: colorBottom.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colorTop, colorBottom]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: colorBottom.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateReport,
                      icon: Icon(Icons.psychology_rounded, color: colorGold),
                      label: const Text(
                        "GENERATE BUSINESS REPORT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
