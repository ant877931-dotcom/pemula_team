import 'package:flutter/material.dart';

class PinDialog extends StatefulWidget {
  final String correctPin;
  const PinDialog({super.key, required this.correctPin});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("PIN M-Banking"),
      content: TextField(
        controller: _pinController,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(hintText: "Masukkan 6 Digit PIN"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
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
          child: const Text("Konfirmasi"),
        ),
      ],
    );
  }
}
