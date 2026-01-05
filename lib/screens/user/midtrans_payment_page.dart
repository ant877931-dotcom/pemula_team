import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransPaymentPage extends StatefulWidget {
  final String snapToken;
  const MidtransPaymentPage({super.key, required this.snapToken});

  @override
  State<MidtransPaymentPage> createState() => _MidtransPaymentPageState();
}

class _MidtransPaymentPageState extends State<MidtransPaymentPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // URL Midtrans Sandbox
    final String paymentUrl =
        "https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('finish') || url.contains('success')) {
              Navigator.pop(context, true);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
        "Pembayaran Top Up",
        )
        ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
