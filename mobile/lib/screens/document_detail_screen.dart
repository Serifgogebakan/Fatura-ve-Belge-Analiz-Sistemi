import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentDetailScreen extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final String? documentName;

  const DocumentDetailScreen({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.documentName,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  String _firmaAdi = 'Taranıyor...';
  String _tarih = 'Taranıyor...';
  String _tutar = 'Taranıyor...';
  String _ocrMetni = 'Metin çıkarılıyor, lütfen bekleyin...';
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    if (widget.imageFile == null) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _ocrMetni = 'Görsel bulunamadı, OCR yapılamıyor.';
          _firmaAdi = '-';
          _tarih = '-';
          _tutar = '-';
        });
      }
      return;
    }

    try {
      final inputImage = InputImage.fromFile(widget.imageFile!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      
      String extractedTarih = 'Bulunamadı';
      String extractedTutar = 'Bulunamadı';
      String extractedFirma = 'Bulunamadı';

      if (text.trim().isNotEmpty) {
        List<String> lines = text.split('\n');
        // İlk satırı genellikle firma veya başlık olarak alalım
        for (String line in lines) {
          if (line.trim().length > 3) {
            extractedFirma = line.trim();
            break;
          }
        }

        // Tarih formatı bulma (örn: 24.06.2024 veya 24/06/2024)
        RegExp dateRegExp = RegExp(r'\b(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})\b');
        var dateMatch = dateRegExp.firstMatch(text);
        if (dateMatch != null) {
          extractedTarih = dateMatch.group(0) ?? 'Bulunamadı';
        }

        // Tutar formatı bulma (TOPLAM kelimesini arayarak)
        RegExp totalRegExp = RegExp(r'TOPLAM[\s:]*([0-9.,]+)', caseSensitive: false);
        var totalMatch = totalRegExp.firstMatch(text);
        if (totalMatch != null) {
          extractedTutar = '₺' + (totalMatch.group(1) ?? '');
        } else {
           // Eğer TOPLAM kelimesi yoksa, metin sonlarındaki büyük rakamları bulmayı deneyebiliriz
           // Şimdilik basit tutuyoruz
           extractedTutar = 'Bulunamadı';
        }
      } else {
        text = 'Görselde okunabilir metin bulunamadı.';
      }

      if (mounted) {
        setState(() {
          _ocrMetni = text;
          _firmaAdi = extractedFirma;
          _tarih = extractedTarih;
          _tutar = extractedTutar;
          _isScanning = false;
        });
      }
      
      textRecognizer.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocrMetni = 'OCR Hatası: ${e.toString()}';
          _isScanning = false;
          _firmaAdi = 'Hata';
          _tarih = '-';
          _tutar = '-';
        });
      }
    }
  }

  void _kopyaAl() {
    Clipboard.setData(ClipboardData(text: _ocrMetni));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Metin panoya kopyalandı!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _belgeyiOnayla() {
    // Burada belgeyi onaylayıp verileri bir önceki ekrana (upload_screen) döndürüyoruz
    final data = {
      'firmaAdi': _firmaAdi,
      'tarih': _tarih,
      'tutar': _tutar,
      'ocrMetni': _ocrMetni,
    };
    Navigator.of(context).pop(data);
  }

  Future<void> _showEditDialog(String title, String currentValue, Function(String) onSave) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0056D2);

    if (title == 'Tarih') {
      DateTime initialDate = DateTime.now();
      if (currentValue != 'Bulunamadı' && currentValue != '-') {
        try {
          final parts = currentValue.split(RegExp(r'[./-]'));
          if (parts.length == 3) {
            int y = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
            int m = int.parse(parts[1]);
            int d = int.parse(parts[0]);
            initialDate = DateTime(y, m, d);
          }
        } catch (_) {}
      }
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark ? ColorScheme.dark(primary: primaryColor) : ColorScheme.light(primary: primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        String formatted = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
        onSave(formatted);
      }
      return;
    }

    String initialText = currentValue == 'Bulunamadı' || currentValue == '-' ? '' : currentValue;
    if (title == 'Tutar') {
      initialText = initialText.replaceAll('₺', '').replaceAll('.', '').replaceAll(',', '.').trim();
      if (initialText.endsWith('.00')) initialText = initialText.substring(0, initialText.length - 3);
    }
    
    final TextEditingController _ctrl = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$title Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: _ctrl,
          keyboardType: title == 'Tutar' ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: title == 'Tutar' ? 'Örn: 1000 VEYA 1000.50' : 'Yeni değer girin...',
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_ctrl.text.trim().isNotEmpty) {
                String text = _ctrl.text.trim();
                if (title == 'Tutar') {
                  text = text.replaceAll('.', '').replaceAll(',', '.');
                  double? val = double.tryParse(text);
                  if (val != null) {
                    String formatted = val.toStringAsFixed(2);
                    List<String> p = formatted.split('.');
                    String intPart = p[0];
                    String res = '';
                    for (int i = 0; i < intPart.length; i++) {
                      if (i > 0 && (intPart.length - i) % 3 == 0) {
                        res += '.';
                      }
                      res += intPart[i];
                    }
                    if (p[1] != '00') {
                      text = '₺$res,${p[1]}';
                    } else {
                      text = '₺$res';
                    }
                  } else {
                    text = '₺$text';
                  }
                }
                onSave(text);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0056D2);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Belge Detayı',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── BELGE GÖRSELİ KARTI ────────────────────────────
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.imageFile != null
                            ? Image.file(
                                widget.imageFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (widget.imageUrl != null
                                ? Image.network(
                                    widget.imageUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                                    ),
                                  )),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: widget.imageFile != null
                                          ? Image.file(widget.imageFile!)
                                          : (widget.imageUrl != null 
                                              ? Image.network(widget.imageUrl!)
                                              : const Icon(Icons.error, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── FİRMA BİLGİSİ ────────────────────────────
                GestureDetector(
                  onTap: () => _showEditDialog('Firma Adı', _firmaAdi, (val) => setState(() => _firmaAdi = val)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'FİRMA',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 10, color: Colors.grey.shade400),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _firmaAdi,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.point_of_sale_rounded, color: primaryColor, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── TARİH VE TUTAR ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditDialog('Tarih', _tarih, (val) => setState(() => _tarih = val)),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'TARİH',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 10, color: Colors.grey.shade400),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tarih,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showEditDialog('Tutar', _tutar, (val) => setState(() => _tutar = val)),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'TUTAR',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, size: 10, color: Colors.grey.shade400),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tutar,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── OCR METNİ BAŞLIK ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'OCR ile Çıkarılmış Metin',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GÜVENLİ',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── OCR METNİ KUTUSU ────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isScanning 
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ocrMetni,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _kopyaAl,
                          icon: Icon(Icons.copy_rounded, size: 16, color: primaryColor),
                          label: Text(
                            'METNİ KOPYALA',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── SABİT ONAYLA BUTONU ────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _belgeyiOnayla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Belgeyi Onayla',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
