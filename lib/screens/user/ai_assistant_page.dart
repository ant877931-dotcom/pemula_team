import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_user.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';

class AIAssistantPage extends StatefulWidget {
  final CustomerUser user;

  const AIAssistantPage({super.key, required this.user});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  bool _isTyping = false;

  // Warna Tema
  final Color primaryTeal = const Color(0xFF1A9591);

  @override
  void initState() {
    super.initState();
    // Pesan sambutan otomatis dari AI
    _messages.add(
      ChatMessage(
        text:
            "Halo! Saya asisten keuangan digital Anda. Ada yang bisa saya bantu terkait akun midBank Anda hari ini?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    // Konteks sistem agar AI memahami data finansial user
    final String systemContext =
        """
      Kamu adalah 'midBank Personal AI Assistant' yang cerdas dan ramah.
      Data Akun User:
      - Email: ${widget.user.email}
      - Saldo Saat Ini: Rp ${widget.user.balance}
      - Nomor Rekening: ${widget.user.accountNumber}
      
      Tugas kamu:
      1. Membantu user mengecek informasi saldo dan rekening mereka.
      2. Memberikan saran finansial bijak (misal: cara menabung atau tips belanja).
      3. Menjawab dengan bahasa Indonesia yang sopan dan profesional.
      4. Jika user bertanya di luar topik perbankan/keuangan, arahkan kembali dengan sopan.
    """;

    final response = await _aiService.getAIResponse(userText, systemContext);

    setState(() {
      _messages.add(
        ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
      );
      _isTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Financial Assistant"),
        backgroundColor: primaryTeal, // DIUBAH: Indigo -> Teal
        foregroundColor: Colors.white,
        elevation: 0, // Dibuat flat agar lebih modern
      ),
      body: Container(
        color: Colors.white, // Latar belakang chat tetap putih bersih
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "midBank AI sedang berpikir...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: primaryTeal.withOpacity(0.7), // DIUBAH: Warna tulisan mengetik
                  ),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser)
            CircleAvatar(
              backgroundColor: primaryTeal, // DIUBAH: Indigo -> Teal
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // DIUBAH: Bubble User pakai Teal, Bubble AI pakai Abu-abu lembut
                color: msg.isUser ? primaryTeal : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                  bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                      color: msg.isUser ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser)
            CircleAvatar(
              // DIUBAH: Avatar user menggunakan Teal muda agar senada (sebelumnya orange)
              backgroundColor: const Color(0xFF67C3C0),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: primaryTeal, // DIUBAH: Warna kursor teal
                decoration: InputDecoration(
                  hintText: "Tanya midBank AI...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: primaryTeal, // DIUBAH: Indigo -> Teal
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}