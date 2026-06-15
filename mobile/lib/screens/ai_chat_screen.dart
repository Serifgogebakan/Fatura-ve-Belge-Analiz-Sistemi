import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatScreen extends StatefulWidget {
  final double bakiye;
  final double ciro;
  final double vergiYuku;
  final double karMarji;
  final String userName;

  const AiChatScreen({
    super.key,
    required this.bakiye,
    required this.ciro,
    required this.vergiYuku,
    required this.karMarji,
    required this.userName,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // İlk karşılama mesajı
    _messages.add({
      'role': 'assistant',
      'content': 'Merhaba ${widget.userName}! Ben BillMind Finansal Yapay Zeka Asistanıyım. Güncel finansal verilerini analiz ettim. Bütçe optimizasyonu, vergi yükü tasarrufu veya nakit akışın hakkında bana ne sormak istersin?',
      'time': DateTime.now(),
    });
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
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sistem hatası: Yapay zeka API anahtarı bulunamadı. Lütfen yöneticinizle iletişime geçin.',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      final systemContext = '''
Sen BillMind uygulamasının uzman Finansal Zeka ve Yapay Zeka Asistanısın. Kullanıcı ile finansal durum analizi, bütçe tasarrufları ve fatura optimizasyonu üzerine konuşuyorsun.
Kullanıcının güncel finansal profili şu şekildedir:
- Şirket Sahibi / Kullanıcı Adı: ${widget.userName}
- Toplam Kasa Bakiyesi: ₺${widget.bakiye.toStringAsFixed(2)}
- Aylık Ciro / Gelir: ₺${widget.ciro.toStringAsFixed(2)}
- Tahmini Vergi Yükü (%20): ₺${widget.vergiYuku.toStringAsFixed(2)}
- Net Kâr Marjı: %${widget.karMarji.toStringAsFixed(1)}

Sorulan sorulara Türkçe, samimi ama son derece profesyonel bir üslupla, finans danışmanı edasıyla cevap ver. Yanıtlarında kullanıcının yukarıdaki finansal durumuna atıfta bulunarak gerçekçi ve uygulanabilir tasarruf tavsiyeleri ver. Yanıtları maddeler halinde ve okuması kolay şekilde biçimlendir.
''';

      // İstek gövdesi hazırlama (Yerel hoş geldiniz mesajını atlayarak API'nin kullanıcı mesajıyla başlamasını sağlıyoruz)
      final messagesPayload = [
        {'role': 'system', 'content': systemContext},
        ..._messages.skip(1).map((m) => {
          'role': m['role'],
          'content': m['content'],
        }),
      ];

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': messagesPayload,
          'temperature': 0.6,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'] as String;

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': reply.trim(),
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
      } else {
        debugPrint('Groq API Hata Detayı: ${response.statusCode} - ${response.body}');
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Üzgünüm, şu an yanıt üretemiyorum. Lütfen daha sonra tekrar deneyin. (Hata Kodu: ${response.statusCode})',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Bağlantı hatası oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
          'time': DateTime.now(),
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.12),
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BillMind AI Asistan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Çevrimiçi',
                      style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                final isMe = msg['role'] == 'user';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? primaryColor
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                    ),
                    child: Text(
                      msg['content'],
                      style: TextStyle(
                        fontSize: 13,
                        color: isMe ? Colors.white : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Asistan düşünüyor...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Sorunuzu yazın...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: primaryColor, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
