import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/pdf_report_service.dart';
import 'budget_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _thisMonthExpense = 0;
  double _lastMonthExpense = 0;
  double _thisMonthIncome = 0;
  double _lastMonthIncome = 0;
  double _sgkPrimi = 15000;
  int _uyumSkoru = 100;
  int _missingCategoryCount = 0;
  int _missingNameCount = 0;
  int _missingAmountCount = 0;
  int _missingTypeCount = 0;
  int _totalDocs = 0;

  List<Map<String, dynamic>> _aiInsights = [];
  List<Map<String, dynamic>> _topSuppliers = [];
  List<Map<String, dynamic>> _docsThisMonth = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('documents')
          .select('amount, category, name, created_at, belge_tipi')
          .eq('user_id', userId);

      final now = DateTime.now();
      double tExpense = 0;
      double lExpense = 0;
      int mCatCount = 0;
      int mNameCount = 0;
      int penaltyPoints = 0; // Uyum Skoru için ceza puanları
      
      Map<String, double> supplierTotals = {};
      List<Map<String, dynamic>> docsThisMonth = [];

      for (final doc in response) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        final category = (doc['category'] as String?)?.toUpperCase() ?? 'DİĞER';
        final name = doc['name'] as String? ?? 'Bilinmeyen';
        final createdAtStr = doc['created_at'] as String?;

        // Uyum Skoru Hesaplaması: Eksik bilgili faturalar puan kırar
        if (category == 'DİĞER' || category.isEmpty) {
          penaltyPoints += 5;
          mCatCount++;
        }
        if (name == 'Bilinmeyen' || name.isEmpty) {
          penaltyPoints += 5;
          mNameCount++;
        }

        if (createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();
            int diffMonths = (now.year - dt.year) * 12 + now.month - dt.month;
            
            final belge_tipi = (doc['belge_tipi'] as String?) ?? 'gider';

            if (diffMonths == 0) {
              if (belge_tipi == 'gelir') {
                tExpense += 0; // gelir belgesi gider sayılmaz
              } else {
                tExpense += amount;
              }
              if (name != 'Bilinmeyen' && name.isNotEmpty && belge_tipi != 'gelir') {
                supplierTotals[name] = (supplierTotals[name] ?? 0) + amount;
              }
              docsThisMonth.add({'name': name, 'amount': amount, 'category': category, 'tipi': belge_tipi});
            } else if (diffMonths == 1) {
              if (belge_tipi != 'gelir') lExpense += amount;
            }
          } catch (_) {}
        }
      }

      // Gerçek gelir: belge_tipi = 'gelir' olan belgelerden bu ay
      double realIncome = 0;
      double realLastIncome = 0;
      for (final doc in response) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        final belge_tipi = (doc['belge_tipi'] as String?) ?? 'gider';
        final createdAtStr = doc['created_at'] as String?;
        if (belge_tipi == 'gelir' && createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();
            int diffMonths = (now.year - dt.year) * 12 + now.month - dt.month;
            if (diffMonths == 0) realIncome += amount;
            else if (diffMonths == 1) realLastIncome += amount;
          } catch (_) {}
        }
      }

      final prefs = await SharedPreferences.getInstance();
      // Gerçek gelir yoksa SharedPreferences'taki sabit geliri kullan
      double tIncome = realIncome > 0 ? realIncome : (prefs.getDouble('aylikGelir') ?? 50000);
      double lIncome = realLastIncome > 0 ? realLastIncome : (tIncome * 0.95);
      double sgkPrimi = prefs.getDouble('sgkPrimi') ?? 15000;

      // ===== UYUM SKORU: Çok Faktörlü Puanlama =====
      // Her belge için aşağıdaki kriterler değerlendirilir:
      // Başlangıç 100, her eksik kriter için puan düşer
      
      int totalDocs = response.length;
      int docsWithCategory = 0;   // Kategori atanmış (DİĞER değil)
      int docsWithName = 0;        // Firma adı olan
      int docsWithAmount = 0;      // Tutar girilmiş
      int docsWithDate = 0;        // Tarih var
      int docsWithType = 0;        // Belge tipi (gelir/gider) seçilmiş  
      int giderCount = 0;
      int gelirCount = 0;

      for (final doc in response) {
        final category = (doc['category'] as String?)?.toUpperCase() ?? 'DİĞER';
        final name = doc['name'] as String? ?? '';
        final amount = (doc['amount'] as num?)?.toDouble();
        final createdAt = doc['created_at'] as String?;
        final belge = (doc['belge_tipi'] as String?) ?? 'gider';

        if (category != 'DİĞER' && category.isNotEmpty) docsWithCategory++;
        if (name.isNotEmpty && name != 'Bilinmeyen') docsWithName++;
        if (amount != null && amount > 0) docsWithAmount++;
        if (createdAt != null) docsWithDate++;
        if (doc['belge_tipi'] != null) docsWithType++;
        if (belge == 'gelir') gelirCount++; else giderCount++;
      }

      if (totalDocs == 0) totalDocs = 1; // Sıfıra bölme önlemi

      // Puan hesaplama: Her kriterin ağırlığı farklı
      // Kategori %30, Firma Adı %25, Tutar %20, Tarih %15, Belge Tipi %10
      double catScore    = (docsWithCategory / totalDocs) * 30;
      double nameScore   = (docsWithName / totalDocs) * 25;
      double amountScore = (docsWithAmount / totalDocs) * 20;
      double dateScore   = (docsWithDate / totalDocs) * 15;
      double typeScore   = (docsWithType / totalDocs) * 10;

      int score = (catScore + nameScore + amountScore + dateScore + typeScore).round();
      if (score < 20) score = 20;
      if (score > 100) score = 100;

      // Missing count (eski değişkenler UI için hala kullanılıyor)
      mCatCount = totalDocs - docsWithCategory;
      mNameCount = totalDocs - docsWithName;
      int mAmountCount = totalDocs - docsWithAmount;
      int mTypeCount = totalDocs - docsWithType;


      // Tedarikçi Verimliliği (En çok ödeme yapılan top 3)
      var sortedSuppliers = supplierTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      List<Map<String, dynamic>> suppliersList = [];
      for (int i = 0; i < sortedSuppliers.length && i < 3; i++) {
        suppliersList.add({
          'name': sortedSuppliers[i].key,
          'amount': sortedSuppliers[i].value,
        });
      }

      // AI Insights - Groq API ile
      List<Map<String, dynamic>> insightsList = [];
      docsThisMonth.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
      
      try {
        final apiKey = dotenv.env['GROQ_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty && docsThisMonth.isNotEmpty) {
          // LLM'e sadece en büyük 15 faturayı göndererek bağlamı koruyalım
          String dataStr = docsThisMonth.take(15).map((e) => "Firma: ${e['name']} | Kategori: ${e['category']} | Tutar: ₺${e['amount']}").join('\n');
          
          final prompt = '''Sen şirketin Finansal Zeka ve Uyum Asistanısın. Aşağıda bu ayki en büyük harcamaların listesi var. Bu veritabanı kayıtlarını inceleyerek bana sadece 2 maddelik çarpıcı bir "Tasarruf Fırsatı" veya "Finansal Uyarı" çıkar.
DİKKAT: Mutlaka aşağıdaki JSON formatında dön, JSON harici hiçbir metin (merhaba vs.) yazma:
[
  {"title": "Kısa Çarpıcı Başlık", "desc": "Detaylı açıklama ve öneri", "amount": tahmini_fayda_sadece_rakam_olarak_1000_gibi}
]

Faturalar:
$dataStr
''';

          final groqRes = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama3-8b-8192',
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.3,
            }),
          );

          if (groqRes.statusCode == 200) {
            final resData = jsonDecode(utf8.decode(groqRes.bodyBytes));
            String content = resData['choices'][0]['message']['content'];
            // Bazen LLM json formatının dışına çıkabilir, temizleyelim
            int startIdx = content.indexOf('[');
            int endIdx = content.lastIndexOf(']');
            if (startIdx != -1 && endIdx != -1) {
              content = content.substring(startIdx, endIdx + 1);
              List<dynamic> parsed = jsonDecode(content);
              for (var item in parsed) {
                insightsList.add({
                  'title': item['title'] ?? 'Finansal Uyarı',
                  'desc': item['desc'] ?? '',
                  'amount': double.tryParse(item['amount'].toString()) ?? 0.0,
                  'icon': Icons.auto_awesome
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Groq API Hatası: $e');
      }

      // API çalışmazsa veya veri yoksa fallback (eski statik mantık)
      if (insightsList.isEmpty && docsThisMonth.isNotEmpty) {
        var topDoc = docsThisMonth[0];
        insightsList.add({
          'title': 'Yüksek Gider Tespiti',
          'desc': 'Bu ayki en büyük harcamanız ${topDoc['name']} firmasına ait. Gider kalemlerini optimize edebilirsiniz.',
          'amount': topDoc['amount'],
          'icon': Icons.warning_amber_rounded
        });
        
        if (docsThisMonth.length > 1) {
          var secDoc = docsThisMonth[1];
          insightsList.add({
            'title': 'Vergi İndirimi Potansiyeli',
            'desc': '${secDoc['name']} faturanız için KDV iadesi veya ek vergi indirimi uygulanabilir.',
            'amount': secDoc['amount'] * 0.18,
            'icon': Icons.savings_outlined
          });
        }
      }
      
      if (insightsList.isEmpty) {
        insightsList.add({
          'title': 'Veri Bekleniyor',
          'desc': 'Yapay zeka analizi için daha fazla belge yüklemeniz gerekmektedir.',
          'amount': 0.0,
          'icon': Icons.auto_awesome
        });
      }

      if (mounted) {
        setState(() {
          _thisMonthExpense = tExpense;
          _lastMonthExpense = lExpense;
          _thisMonthIncome = tIncome;
          _lastMonthIncome = lIncome;
          _sgkPrimi = sgkPrimi;
          _uyumSkoru = score;
          _missingCategoryCount = mCatCount;
          _missingNameCount = mNameCount;
          _missingAmountCount = mAmountCount;
          _missingTypeCount = mTypeCount;
          _totalDocs = response.length;
          _topSuppliers = suppliersList;
          _aiInsights = insightsList;
          _docsThisMonth = docsThisMonth;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isFetchingInsights = false;

  Future<void> _fetchNewInsights() async {
    if (_docsThisMonth.isEmpty) return;
    setState(() => _isFetchingInsights = true);
    
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        String dataStr = _docsThisMonth.take(15).map((e) => "Firma: ${e['name']} | Kategori: ${e['category']} | Tutar: ₺${e['amount']}").join('\n');
        
        final prompt = '''Sen şirketin Finansal Asistanısın. Aşağıda bu ayki en büyük harcamalar var. Bana 2 farklı ve YENİ "Tasarruf Fırsatı" veya "Uyarı" çıkar.
Lütfen önceki tavsiyelerden farklı ve yaratıcı açılara odaklan.
DİKKAT: JSON formatında dön:
[
  {"title": "Kısa Başlık", "desc": "Açıklama", "amount": 1000}
]

Rastgele Zaman Damgası: ${DateTime.now().millisecondsSinceEpoch}
Faturalar:
$dataStr
''';

        final groqRes = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama3-8b-8192',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.9,
          }),
        );

        if (groqRes.statusCode == 200) {
          final resData = jsonDecode(utf8.decode(groqRes.bodyBytes));
          String content = resData['choices'][0]['message']['content'];
          int startIdx = content.indexOf('[');
          int endIdx = content.lastIndexOf(']');
          if (startIdx != -1 && endIdx != -1) {
            content = content.substring(startIdx, endIdx + 1);
            List<dynamic> parsed = jsonDecode(content);
            List<Map<String, dynamic>> newInsights = [];
            for (var item in parsed) {
              newInsights.add({
                'title': item['title'] ?? 'Finansal Uyarı',
                'desc': item['desc'] ?? '',
                'amount': double.tryParse(item['amount'].toString()) ?? 0.0,
                'icon': Icons.auto_awesome
              });
            }
            if (newInsights.isNotEmpty && mounted) {
              setState(() {
                _aiInsights = newInsights;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isFetchingInsights = false);
    }
  }

  void _showInsightDetails(Map<String, dynamic> insight, Color primaryBlue, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(insight['icon'], color: primaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(insight['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.2))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Yapay Zeka Değerlendirmesi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text(insight['desc'], style: TextStyle(fontSize: 14, color: textColor, height: 1.5)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Tahmini Tasarruf / Kazanç', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700))),
                  Text(_formatCurrency(insight['amount'] as double), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anladım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '₺0';
    bool isNegative = amount < 0;
    String formatted = amount.abs().toStringAsFixed(0);
    String res = '';
    for (int i = 0; i < formatted.length; i++) {
      if (i > 0 && (formatted.length - i) % 3 == 0) {
        res += '.';
      }
      res += formatted[i];
    }
    return isNegative ? '-₺$res' : '₺$res';
  }

  String _formatK(double amount) {
    if (amount >= 1000) {
      return '₺${(amount / 1000).toStringAsFixed(1)}K';
    }
    return _formatCurrency(amount);
  }

  Future<void> _exportToExcel() async {
    if (_docsThisMonth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dışa aktarılacak veri bulunamadı.')));
      return;
    }
    
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Fatura Raporu'];
      excel.setDefaultSheet('Fatura Raporu');

      sheetObject.appendRow([
        TextCellValue('Firma Adı'),
        TextCellValue('Kategori'),
        TextCellValue('Tutar'),
        TextCellValue('Belge Tipi')
      ]);

      for (var doc in _docsThisMonth) {
        final tipi = (doc['belge_tipi'] as String? ?? doc['tipi'] as String? ?? 'gider').toLowerCase();
        sheetObject.appendRow([
          TextCellValue(doc['name']?.toString() ?? ''),
          TextCellValue(doc['category']?.toString() ?? ''),
          DoubleCellValue((doc['amount'] as num?)?.toDouble() ?? 0.0),
          TextCellValue(tipi),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/Aylik_Fatura_Raporu.xlsx';
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        await Share.shareXFiles([XFile(path)], text: 'Aylık Fatura Raporu (Excel)');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dışa aktarım hatası: $e')));
    }
  }

  Future<void> _exportToPdf() async {
    if (_docsThisMonth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dışa aktarılacak veri bulunamadı.')));
      return;
    }
    try {
      await PdfReportService.generateAndShare(
        context: context,
        docs: _docsThisMonth,
        totalIncome: _thisMonthIncome,
        totalExpense: _thisMonthExpense,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF hatası: $e')));
    }
  }

  Widget _buildCategoryPieChart(bool isDark, Color textColor, Color cardColor) {
    if (_docsThisMonth.isEmpty) return const SizedBox.shrink();
    
    Map<String, double> catTotals = {};
    double totalExpense = 0;
    for (var doc in _docsThisMonth) {
      final tipi = (doc['belge_tipi'] as String? ?? doc['tipi'] as String? ?? 'gider').toLowerCase();
      if (tipi != 'gelir') {
        final cat = (doc['category'] as String? ?? 'Diğer');
        catTotals[cat] = (catTotals[cat] ?? 0) + (doc['amount'] as num? ?? 0).toDouble();
        totalExpense += (doc['amount'] as num? ?? 0).toDouble();
      }
    }

    if (catTotals.isEmpty || totalExpense == 0) return const SizedBox.shrink();

    var sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> sections = [];
    final colors = [
      const Color(0xFF0052FF), // Primary Blue
      const Color(0xFF4C7FFF), // Lighter Blue
      const Color(0xFF99B9FF), // Very Light Blue
      const Color(0xFFE5EDFF), // Pale Blue
      const Color(0xFF2E3B5B), // Dark Blue
      const Color(0xFF64748B), // Slate
    ];
    int colorIdx = 0;
    
    for (var cat in sortedCats) {
      final amount = cat.value;
      sections.add(PieChartSectionData(
        color: colors[colorIdx % colors.length],
        value: amount,
        title: '',
        radius: 30,
      ));
      colorIdx++;
    }

    String totalStr = '';
    if (totalExpense >= 1000000) {
      totalStr = '₺${(totalExpense / 1000000).toStringAsFixed(1)}M';
    } else if (totalExpense >= 1000) {
      totalStr = '₺${(totalExpense / 1000).toStringAsFixed(1)}K';
    } else {
      totalStr = _formatCurrency(totalExpense);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 70,
                      sectionsSpace: 0,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TOPLAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(totalStr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Gider Dağılımı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text('Son 30 günlük operasyonel harcama analizi.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          ...List.generate(sortedCats.length, (index) {
            final cat = sortedCats[index];
            final pct = (cat.value / totalExpense) * 100;
            final color = colors[index % colors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(cat.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const Spacer(),
                  Text('%${pct.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryBlue = const Color(0xFF2563EB);

    // Trend hesaplamaları
    double incomeTrend = _lastMonthIncome > 0 ? ((_thisMonthIncome - _lastMonthIncome) / _lastMonthIncome) * 100 : 0;
    double expenseTrend = _lastMonthExpense > 0 ? ((_thisMonthExpense - _lastMonthExpense) / _lastMonthExpense) * 100 : 0;

    String incomeTrendStr = incomeTrend >= 0 ? '+%${incomeTrend.toStringAsFixed(1)}' : '-%${incomeTrend.abs().toStringAsFixed(1)}';
    String expenseTrendStr = expenseTrend >= 0 ? '+%${expenseTrend.toStringAsFixed(1)}' : '-%${expenseTrend.abs().toStringAsFixed(1)}';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Text(
                    'Finansal\nAnaliz &\nUyum',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aylık finansal durumunuz, vergi yükümlülükleriniz, uyum skorunuz ve yapay zeka destekli tasarruf fırsatları.',
                    style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Buttons Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _exportToExcel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.table_chart_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _exportToPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bütçe Takibi Kısayolu
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.purple, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bütçe Takibi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                Text('Kategori limitlerini bel irle ve takip et', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  // Gelir & Gider Analizi Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gelir & Gider Analizi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Icon(Icons.insert_chart_outlined, color: subtitleColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildIncomeExpenseItem(
                          isIncome: true,
                          title: 'Aylık Toplam Gelir (Tahmini)',
                          amount: _formatCurrency(_thisMonthIncome),
                          trend: 'Geçen aya göre $incomeTrendStr',
                          icon: Icons.payments_outlined,
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 20, endIndent: 20),
                        _buildIncomeExpenseItem(
                          isIncome: false,
                          title: 'Aylık Toplam Gider',
                          amount: _formatCurrency(_thisMonthExpense),
                          trend: 'Geçen aya göre $expenseTrendStr',
                          icon: Icons.shopping_cart_outlined,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Kategori Pasta Grafiği
                  _buildCategoryPieChart(isDark, textColor, cardColor),
                  
                  const SizedBox(height: 32),

                  // Tahmini Vergi Yükümlülüğü
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tahmini Vergi\nYükümlülüğü', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, height: 1.2)),
                      Icon(Icons.account_balance_outlined, color: subtitleColor, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTaxCard('KDV (Tahmini)', _formatCurrency(_thisMonthExpense * 0.20), 'Genel %20 Oran', Icons.receipt_long_outlined, Colors.red, cardColor, textColor, isDark),
                  const SizedBox(height: 12),
                  _buildTaxCard('Kurumlar Vergisi', _formatCurrency(_thisMonthExpense * 0.25), 'Aylık Ortalama', Icons.domain, primaryBlue, cardColor, textColor, isDark),
                  const SizedBox(height: 12),
                  _buildTaxCard('SGK Primleri', _formatCurrency(_sgkPrimi), 'Aylık Sabit', Icons.people_outline, Colors.grey.shade600, cardColor, textColor, isDark),
                  const SizedBox(height: 32),

                  // Yapay Zeka Tasarruf Fırsatları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Yapay Zeka\nAnalizleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.2)),
                      GestureDetector(
                        onTap: _isFetchingInsights ? null : _fetchNewInsights,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5EDFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _isFetchingInsights 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Yeni\nÖngörüler', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E3B5B), height: 1.2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_aiInsights.length, (index) {
                    final insight = _aiInsights[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildAiInsightCard(
                        insight,
                        cardColor,
                        textColor,
                        primaryBlue,
                        index == 0,
                        isDark,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  // Uyum Skoru
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (context) {
                          Widget _scoreRow(IconData icon, Color color, String title, int missing, int total, double weight) {
                            final completed = total - missing;
                            final pct = total > 0 ? completed / total : 1.0;
                            final earned = (pct * weight).round();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(icon, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 5,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(pct > 0.7 ? Colors.green : pct > 0.4 ? Colors.orange : Colors.red),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text('$completed / $total belge tamamlandı', style: TextStyle(fontSize: 10, color: subtitleColor)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('$earned/${weight.toInt()}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                      color: pct > 0.7 ? Colors.green : pct > 0.4 ? Colors.orange : Colors.red)),
                                ],
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('Uyum Skoru Detayları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _uyumSkoru >= 80 ? Colors.green.withOpacity(0.1) : _uyumSkoru >= 60 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('$_uyumSkoru / 100',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                                          color: _uyumSkoru >= 80 ? Colors.green : _uyumSkoru >= 60 ? Colors.orange : Colors.red)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('$_totalDocs belge analiz edildi', style: TextStyle(fontSize: 12, color: subtitleColor)),
                                const Divider(height: 24),
                                _scoreRow(Icons.category_outlined, Colors.purple, 'Kategori Tamamlanması', _missingCategoryCount, _totalDocs, 30),
                                _scoreRow(Icons.business_outlined, Colors.blue, 'Firma Adı Eksiksizliği', _missingNameCount, _totalDocs, 25),
                                _scoreRow(Icons.attach_money, Colors.green, 'Tutar Girişi', _missingAmountCount, _totalDocs, 20),
                                _scoreRow(Icons.calendar_today, Colors.orange, 'Tarih Bilgisi', 0, _totalDocs, 15),
                                _scoreRow(Icons.swap_vert, Colors.teal, 'Belge Tipi (Gelir/Gider)', _missingTypeCount, _totalDocs, 10),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0052FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Anladım', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Uyum Skoru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              Icon(Icons.info_outline, color: subtitleColor, size: 20),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: SizedBox(
                              height: 180,
                              width: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value: _uyumSkoru / 100,
                                      strokeWidth: 16,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052FF)),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$_uyumSkoru', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: textColor, height: 1)),
                                      const SizedBox(height: 4),
                                      Text('/ 100', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              _uyumSkoru >= 80 
                                ? 'Mükemmel seviye. Vergi yasalarına ve\nraporlama standartlarına yüksek uyum\ngösteriyorsunuz.'
                                : 'Orta seviye. Fişlerinizin kategorilerini düzenleyerek uyum skorunuzu artırabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : const Color(0xFF475569), height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tedarikçi Verimliliği
                  Text('Tedarikçi Verimliliği', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 16),
                  
                  if (_topSuppliers.isEmpty)
                    Text('Yeterli tedarikçi verisi yok.', style: TextStyle(color: subtitleColor)),
                    
                  if (_topSuppliers.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('TEDARİKÇİ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1))),
                                Expanded(flex: 3, child: Text('HARCAMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1))),
                                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('VERİM\nSKORU', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)))),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                          ...List.generate(_topSuppliers.length, (index) {
                            final sup = _topSuppliers[index];
                            IconData icon; Color iconBg; Color iconColor; Color barColor; double pct;
                            if (index == 0) {
                              icon = Icons.local_shipping_outlined; iconBg = Colors.grey.shade200; iconColor = Colors.grey.shade700; barColor = const Color(0xFF0052FF); pct = 0.8;
                            } else if (index == 1) {
                              icon = Icons.cloud_outlined; iconBg = Colors.grey.shade200; iconColor = Colors.grey.shade700; barColor = const Color(0xFF0052FF); pct = 0.6;
                            } else {
                              icon = Icons.print_outlined; iconBg = Colors.grey.shade200; iconColor = Colors.grey.shade700; barColor = Colors.red.shade600; pct = 0.4;
                            }
                            if (isDark) iconBg = Colors.grey.shade800;
                            return _buildSupplierItem(sup['name'], _formatCurrency(sup['amount']), iconBg, iconColor, icon, pct, barColor, textColor);
                          }),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 80), // Bottom padding for navbar
                ],
              ),
            ),
          ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return names[month - 1];
  }

  Widget _buildIncomeExpenseItem({
    required bool isIncome,
    required String title,
    required String amount,
    required String trend,
    required IconData icon,
    required bool isDark,
  }) {
    final color = isIncome ? Colors.green : Colors.red;
    final trendIcon = trend.contains('+') ? Icons.trending_up : Icons.trending_down;

    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                      Icon(icon, size: 20, color: Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(amount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(trendIcon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(trend, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxCard(String title, String amount, String trend, IconData icon, Color trendColor, Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              Icon(icon, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trend.contains('artı') || trend.contains('+') ? Icons.trending_up : (trend.contains('Sabit') ? Icons.remove : Icons.trending_down), size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(fontSize: 11, color: trendColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(Map<String, dynamic> insight, Color cardColor, Color textColor, Color primaryBlue, bool isPrimary, bool isDark) {
    Color bgColor = isPrimary 
      ? const Color(0xFF0052FF) 
      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    
    Color contentColor = isPrimary ? Colors.white : textColor;
    Color descColor = isPrimary ? Colors.white.withOpacity(0.9) : Colors.grey.shade600;
    
    String title = insight['title'] ?? '';
    String desc = insight['desc'] ?? '';
    IconData icon = insight['icon'] ?? Icons.auto_awesome;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : primaryBlue, size: 28),
          const SizedBox(height: 16),
          if (isPrimary) ...[
            Text(desc.isNotEmpty ? desc : title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: contentColor, height: 1.3)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showInsightDetails(insight, primaryBlue, cardColor, textColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0052FF),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Raporu İncele', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ] else ...[
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: contentColor)),
            const SizedBox(height: 8),
            Text(desc, style: TextStyle(fontSize: 12, color: descColor, height: 1.4)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showInsightDetails(insight, primaryBlue, cardColor, textColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Detaylar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10, color: primaryBlue),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierItem(String name, String amount, Color iconBg, Color iconColor, IconData icon, double percentage, Color barColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(name.replaceAll(' ', '\n'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor, height: 1.2)),
          ),
          Expanded(
            flex: 3,
            child: Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 30,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
