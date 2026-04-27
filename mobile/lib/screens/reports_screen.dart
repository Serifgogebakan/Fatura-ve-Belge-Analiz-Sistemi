import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _totalAmount = 0;
  Map<String, double> _categoryTotals = {};

  bool _isWeekly = true;
  List<Map<String, dynamic>> _targets = [
    {'title': 'Yeni Araba', 'current': 150000.0, 'total': 450000.0},
    {'title': 'Yaz Tatili', 'current': 28500.0, 'total': 35000.0},
  ];

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
          .select('amount, file_type, category')
          .eq('user_id', userId);

      double total = 0;
      final Map<String, double> catMap = {};

      for (final doc in response) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (doc['category'] as String?)?.toUpperCase() ?? 'DİĞER';

        total += amount;
        catMap[type] = (catMap[type] ?? 0) + amount;
      }

      if (mounted) {
        setState(() {
          _totalAmount = total;
          _categoryTotals = catMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB); // Modern blue
    final cardColor = isDark ? const Color(0xFF151C2C) : Colors.white;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Raporlar ve AI İçgörüleri',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'Finansal sağlığınızın detaylı bir analizi.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),

                // AI FİNANSAL ZEKA KARTI
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI FİNANSAL ZEKA',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Harcama alışkanlıklarınıza göre market harcamalarında %15 tasarruf imkanı yakaladınız.',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => _showAiDetails(context, isDark, cardColor, textColor),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Detayları Gör', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // GİDER DAĞILIMI
                _buildSectionCard(
                  title: 'Gider Dağılımı',
                  badgeTitle: 'BU AY',
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _isLoading
                                ? const CircularProgressIndicator()
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 60,
                                      startDegreeOffset: 270,
                                      sections: _buildPieSections(),
                                    ),
                                  ),
                            if (!_isLoading)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₺${_formatAmount(_totalAmount)}',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    'TOPLAM',
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLoading && _categoryTotals.isNotEmpty)
                        Column(
                          children: _categoryTotals.entries.map((e) {
                            final pct = _totalAmount > 0 ? (e.value / _totalAmount * 100) : 0.0;
                            final i = _categoryTotals.keys.toList().indexOf(e.key);
                            return _buildLegendRow(e.key, pct, _getPieColor(i), textColor);
                          }).toList(),
                        ),
                      if (!_isLoading && _categoryTotals.isNotEmpty)
                        const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => _showAllCategories(context, isDark, cardColor, textColor),
                          child: Text('TÜMÜNÜ GÖR >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // BİRİKİM HEDEFLERİ
                _buildSectionCard(
                  title: 'Birikim Hedefleri',
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  child: Column(
                    children: [
                      ..._targets.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildProgressBar(t['title'], t['current'] as double, t['total'] as double, Colors.blue.shade500, textColor),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        onPressed: () => _showAddTarget(context, isDark, cardColor, textColor, primaryColor),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Yeni Hedef Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // HARCAMA EĞİLİMİ
                _buildSectionCard(
                  title: 'Harcama Eğilimi',
                  badgeWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isWeekly = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _isWeekly ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Text('HAFTALIK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _isWeekly ? Colors.white : Colors.grey.shade500)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _isWeekly = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: !_isWeekly ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Text('AYLIK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: !_isWeekly ? Colors.white : Colors.grey.shade500)),
                        ),
                      ),
                    ],
                  ),
                  isDark: isDark,
                  cardColor: cardColor,
                  textColor: textColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Son 6 aylık veri akışı', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 120,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1,
                                  getTitlesWidget: (val, meta) {
                                    const titles = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN'];
                                    if (val.toInt() >= 0 && val.toInt() < titles.length) {
                                      return Text(titles[val.toInt()], style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _isWeekly ? const [
                                  FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.2), FlSpot(5, 4.8),
                                ] : const [
                                  FlSpot(0, 2), FlSpot(1, 5), FlSpot(2, 2.5), FlSpot(3, 6), FlSpot(4, 3.5), FlSpot(5, 7),
                                ],
                                isCurved: true,
                                color: primaryColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: primaryColor.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // DAHA FAZLA İÇGÖRÜ
                Text(
                  'Daha Fazla İçgörü',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 12),
                _buildInsightListTile(
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.blue.shade600,
                  iconBg: Colors.blue.withOpacity(0.15),
                  title: 'Yatırım Potansiyeli',
                  subtitle: 'Cüzdanınızdaki boş duran ₺12.400 için düşük riskli fon önerileri hazır.',
                  textColor: textColor,
                ),
                const SizedBox(height: 12),
                _buildInsightListTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orange.shade600,
                  iconBg: Colors.orange.withOpacity(0.15),
                  title: 'Abonelik Uyarısı',
                  subtitle: 'Son 3 aydır kullanmadığınız "Streaming Plus" üyeliğini fark ettik.',
                  textColor: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? badgeTitle,
    Widget? badgeWidget,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
              if (badgeTitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(badgeTitle, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              if (badgeWidget != null) badgeWidget,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendRow(String title, double pct, Color color, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ],
          ),
          Text('%${pct.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, double current, double total, Color color, Color textColor) {
    final progress = (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            Text('₺${_formatAmount(current)} / ₺${_formatAmount(total)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightListTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    if (_categoryTotals.isEmpty) {
      return [PieChartSectionData(color: Colors.grey.shade300, value: 100, radius: 25, showTitle: false)];
    }
    final List<PieChartSectionData> sections = [];
    int index = 0;
    _categoryTotals.forEach((key, value) {
      sections.add(
        PieChartSectionData(
          color: _getPieColor(index),
          value: value,
          radius: 20,
          showTitle: false,
        ),
      );
      index++;
    });
    return sections;
  }

  Color _getPieColor(int index) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Emerald
    ];
    return colors[index % colors.length];
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0';
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  void _showAiDetails(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Finansal Zeka Detayları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            Text(
              'Son 3 ay içinde yaptığınız temel gıda ve süpermarket alışverişleri incelendi. Aynı sepetteki ürünleri %15 daha uygun fiyata sunan alternatif 3 market zincirine yönelerek aylık ₺1.200 civarında tasarruf sağlayabilirsiniz.\n\nAI sistemimiz gelecek ay için benzer bir tablo çizdi.',
              style: TextStyle(color: Colors.grey.shade500, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anladım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllCategories(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategorilerin Tümü', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            if (_categoryTotals.isEmpty)
              Text('Hiç veri bulunamadı.', style: TextStyle(color: Colors.grey.shade500)),
            ..._categoryTotals.entries.map((e) {
              final pct = _totalAmount > 0 ? (e.value / _totalAmount * 100) : 0.0;
              final i = _categoryTotals.keys.toList().indexOf(e.key);
              return _buildLegendRow(e.key, pct, _getPieColor(i), textColor);
            }).toList(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddTarget(BuildContext context, bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Birikim Hedefi Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Hedef Adı (Örn: Telefon)',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Hedef Tutar (TL)',
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                    final targetTitle = titleCtrl.text;
                    final targetAmount = double.tryParse(amountCtrl.text) ?? 10000;
                    setState(() {
                      _targets.add(
                        {'title': targetTitle, 'current': 0.0, 'total': targetAmount},
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hedefi Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
