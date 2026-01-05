import 'package:flutter/material.dart';

class PinDialog extends StatefulWidget {
  final String correctPin;
  const PinDialog({super.key, required this.correctPin});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pinController = TextEditingController();
  final Color colorBottom = const Color(0xFF003366);
  final Color colorGold = const Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorGold, width: 2),
      ),
      backgroundColor: Colors.white,
      title: Text(
        "PIN M-Banking",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorBottom, 
          fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Masukkan 6 Digit PIN Keamanan",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 10,
              color: colorBottom,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: colorGold.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colorGold),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text == widget.correctPin) {
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("PIN Salah!"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorBottom,
            foregroundColor: colorGold,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Konfirmasi"),
        ),
      ],
    );
  }
}
