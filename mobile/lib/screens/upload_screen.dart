import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path_util;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:billmind/screens/document_detail_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0;
  double _storageUsedGB = 1.2;
  double _storageTotalGB = 5.0;
  String _selectedBelgeTipi = 'gider'; // 'gelir' veya 'gider'

  List<Map<String, dynamic>> _recentUploads = [];

  @override
  void initState() {
    super.initState();
    _loadRecentUploads();
  }

  Future<void> _loadRecentUploads() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('documents')
          .select('name, cloudinary_secure_url, created_at, file_type')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() {
          _recentUploads = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {}
  }

  // ─── Kamera ile çek (Akıllı Tarama) ────────────────────────────────
  Future<void> _pickFromCamera() async {
    try {
      final List<String> pictures =
          await CunningDocumentScanner.getPictures() ?? [];

      if (pictures.isNotEmpty && mounted) {
        // İlk taranan sayfayı detay ekranına gönderelim
        final File file = File(pictures.first);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentDetailScreen(imageFile: file),
          ),
        );
        if (result != null && result is Map<String, dynamic> && mounted) {
          await _uploadFile(file, 'image/jpeg', parsedData: result);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Belge tarayıcı başlatılamadı: ${e.toString()}');
      }
    }
  }

  // ─── Galeriden seç ─────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DocumentDetailScreen(imageFile: File(image.path)),
        ),
      );
      if (result != null && result is Map<String, dynamic> && mounted) {
        await _uploadFile(File(image.path), 'image/jpeg', parsedData: result);
      }
    }
  }

  // ─── Dosya seç (PDF, PNG, JPG) ─────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null && mounted) {
      final file = File(result.files.single.path!);
      final navResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailScreen(
            imageFile: file,
            documentName: result.files.single.name,
          ),
        ),
      );
      if (navResult != null && navResult is Map<String, dynamic> && mounted) {
        final ext = result.files.single.extension ?? 'pdf';
        final mime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
        await _uploadFile(file, mime, parsedData: navResult);
      }
    }
  }

  // ─── Supabase'e yükle ──────────────────────────────────────────────
  Future<void> _uploadFile(
    File file,
    String mimeType, {
    Map<String, dynamic>? parsedData,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final fileName =
          '${userId}/${DateTime.now().millisecondsSinceEpoch}_${path_util.basename(file.path)}';
      final fileBytes = await file.readAsBytes();

      // Simüle edilmiş progress (Cloudinary de stream vermediği için)
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _uploadProgress = i / 10);
      }

      // Cloudinary upload
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
      final preset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = preset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: path_util.basename(file.path),
          ),
        );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception(
          'Cloudinary upload hatası: ${response.statusCode} - $resBody',
        );
      }

      final data = jsonDecode(resBody);
      final publicUrl = data['secure_url'] as String;

      if (mounted) setState(() => _uploadProgress = 0.8);

      // Tutar parse etme (örn: ₺12.450,00 -> 12450.00)
      double? parsedAmount;
      if (parsedData != null && parsedData['tutar'] != null) {
        String t = parsedData['tutar']
            .toString()
            .replaceAll('₺', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();
        parsedAmount = double.tryParse(t);
      }

      // Tarihi YYYY-MM-DD formatına çevirme (örn: 06.06.2026)
      String? isoDate;
      if (parsedData != null && parsedData['tarih'] != null && parsedData['tarih'] != 'Bulunamadı') {
        try {
          final parts = parsedData['tarih'].toString().split(RegExp(r'[./-]'));
          if (parts.length == 3) {
            String year = parts[2].length == 2 ? '20${parts[2]}' : parts[2];
            String month = parts[1].padLeft(2, '0');
            String day = parts[0].padLeft(2, '0');
            isoDate = '$year-$month-$day';
          }
        } catch (_) {}
      }

      // DB'ye kaydet (Önce documents tablosuna)
      final title = parsedData != null && parsedData['firmaAdi'] != 'Bulunamadı'
          ? parsedData['firmaAdi']
          : path_util.basenameWithoutExtension(file.path);

      final docResponse = await _supabase
          .from('documents')
          .insert({
            'user_id': userId,
            'name': title,
            'original_filename': path_util.basename(file.path),
            'cloudinary_secure_url': publicUrl,
            'file_type': mimeType.contains('pdf') ? 'pdf' : 'image',
            'category': 'DİĞER',
            'status': 'beklemede',
            'payment_status': 'beklemede',
            'amount': parsedAmount,
            'belge_tipi': _selectedBelgeTipi, // YENI: gelir/gider tipi
            if (isoDate != null) 'created_at': '${isoDate}T12:00:00Z',
          })
          .select()
          .single();

      final documentId = docResponse['id'];

      // Eğer OCR verisi varsa extracted_data tablosuna kaydet
      if (parsedData != null) {
        await _supabase.from('extracted_data').insert({
          'document_id': documentId,
          'vendor_name': parsedData['firmaAdi'] == 'Bulunamadı'
              ? null
              : parsedData['firmaAdi'],
          'invoice_date': isoDate,
          'total_amount': parsedAmount,
          'raw_text': parsedData['ocrMetni'],
          'processing_model':
              'google-mlkit-flutter', // Hangi modelin işlediği bilinsin
        });
      }

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _isUploading = false;
        });
        _showSuccess('Belge başarıyla yüklendi!');
        _loadRecentUploads();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showError('Yükleme başarısız: ${e.toString()}');
      }
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final progress = _storageUsedGB / _storageTotalGB;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Belge Yükle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // ✅ Geri tuşu - otomatik olarak Navigator.pop yapar
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Belge Yükle',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Güvenli kasanıza yeni bir doküman ekleyin.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ─── BELGE TİPİ SEÇİMİ ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBelgeTipi = 'gider'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedBelgeTipi == 'gider' ? Colors.red.shade600 : cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedBelgeTipi == 'gider' ? Colors.red.shade600 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded,
                                size: 18,
                                color: _selectedBelgeTipi == 'gider' ? Colors.white : Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text('GİDER', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedBelgeTipi == 'gider' ? Colors.white : Colors.grey.shade500,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBelgeTipi = 'gelir'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _selectedBelgeTipi == 'gelir' ? Colors.green.shade600 : cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedBelgeTipi == 'gelir' ? Colors.green.shade600 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward_rounded,
                                size: 18,
                                color: _selectedBelgeTipi == 'gelir' ? Colors.white : Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text('GELİR', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedBelgeTipi == 'gelir' ? Colors.white : Colors.grey.shade500,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── KAMERA BUTONU ─────────────────────────────────────────
                GestureDetector(
                  onTap: _isUploading ? null : _pickFromCamera,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          isDark
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF2563EB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belge Tara',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fatura veya fişinizi fotoğraflayın',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── GALERİ & DEPOLAMA ────────────────────────────────────
                Row(
                  children: [
                    // GALERİDEN YÜKLE
                    Expanded(
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickFromGallery,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                color: primaryColor,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'GALERİDEN YÜKLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // DEPOLAMA GÖSTERGESİ
                    Expanded(
                      child: Container(
                        height: 90,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'DEPOLAMA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AKTİF',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_storageUsedGB.toStringAsFixed(1)} GB / ${_storageTotalGB.toStringAsFixed(1)} GB',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: isDark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── DOSYA YÜKLE ALANI ────────────────────────────────────
                GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Dosyayı buraya sürükleyin\nveya ',
                              ),
                              TextSpan(
                                text: 'buraya tıklayın',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.blue.shade400
                                      : Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MAKSİMUM 20MB (PDF, JPG, PNG)',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── SON YÜKLEMELER ───────────────────────────────────────
                if (_recentUploads.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SON YÜKLEMELER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._recentUploads.map((upload) {
                    final title = (upload['name'] as String?) ?? 'Belge';
                    final type = (upload['file_type'] as String?) ?? 'Dosya';
                    final createdAt = (upload['created_at'] as String?) ?? '';
                    String dateStr = '-';
                    if (createdAt.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(createdAt).toLocal();
                        dateStr =
                            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      } catch (_) {}
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade100,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              type.toLowerCase().contains('pdf')
                                  ? Icons.picture_as_pdf
                                  : Icons.image_outlined,
                              color: Colors.red.shade400,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: 18,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // ─── YÜKLEME OVERLAY ─────────────────────────────────────────────
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _uploadProgress,
                          strokeWidth: 5,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Yükleniyor... %${(_uploadProgress * 100).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lütfen bekleyin',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
