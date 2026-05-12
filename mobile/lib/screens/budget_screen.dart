import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  final Map<String, double> _limits = {};
  final Map<String, double> _spendings = {};

  static const _kategoriler = [
    'Fatura', 'Fiş', 'Sözleşme', 'Sağlık', 'Finans',
    'Lojistik', 'Personel', 'Vergi', 'Diğer'
  ];
  static const _defaultLimits = {
    'Fatura': 10000.0, 'Fiş': 5000.0, 'Sözleşme': 8000.0,
    'Sağlık': 3000.0, 'Finans': 15000.0, 'Lojistik': 12000.0,
    'Personel': 50000.0, 'Vergi': 20000.0, 'Diğer': 5000.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toUtc().toIso8601String();

      final response = await _supabase
          .from('documents')
          .select('category, amount, belge_tipi')
          .eq('user_id', userId)
          .gte('created_at', firstDay);

      final Map<String, double> spendings = {};
      for (var doc in response) {
        final tipi = (doc['belge_tipi'] as String? ?? 'gider').toLowerCase();
        if (tipi == 'gelir') continue;
        final cat = (doc['category'] as String? ?? 'Diğer');
        spendings[cat] = (spendings[cat] ?? 0) + (doc['amount'] as num? ?? 0).toDouble();
      }

      setState(() {
        for (var kat in _kategoriler) {
          _limits[kat] = prefs.getDouble('limit_$kat') ?? _defaultLimits[kat] ?? 5000.0;
          _spendings[kat] = spendings[kat] ?? 0.0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLimit(String kategori, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('limit_$kategori', value);
    setState(() => _limits[kategori] = value);
  }

  void _showEditLimit(String kategori, bool isDark, Color primaryColor, Color cardColor, Color textColor) {
    final ctrl = TextEditingController(text: _limits[kategori]?.toStringAsFixed(0) ?? '5000');
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$kategori Bütçe Limiti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text('Bu ay için $kategori kategorisinde harcama limitini belirleyin.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₺ ',
                prefixStyle: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  if (val != null && val > 0) {
                    _saveLimit(kategori, val);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0052FF);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    double totalLimit = _limits.values.fold(0, (a, b) => a + b);
    double totalSpending = _spendings.values.fold(0, (a, b) => a + b);
    double totalPct = totalLimit > 0 ? (totalSpending / totalLimit).clamp(0.0, 1.0) : 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Bütçe Takibi', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genel Özet Kartı
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: totalPct > 0.9
                              ? [Colors.red.shade700, Colors.red.shade500]
                              : totalPct > 0.7
                                  ? [Colors.orange.shade700, Colors.orange.shade500]
                                  : [const Color(0xFF0052FF), const Color(0xFF4C7FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AYLIK GENEL BÜTÇE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₺${_fmt(totalSpending)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                                  Text('/ ₺${_fmt(totalLimit)} limit', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '%${(totalPct * 100).toInt()}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalPct,
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalPct > 0.9 ? '⚠️ Bütçe limitine yaklaştınız!' : '₺${_fmt(totalLimit - totalSpending)} kalan',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kategori Bütçeleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        Text('${DateTime.now().month}/${DateTime.now().year}', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ..._kategoriler.map((kat) {
                      final limit = _limits[kat] ?? 5000;
                      final spent = _spendings[kat] ?? 0;
                      final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                      final isOver = pct >= 0.9;
                      final barColor = pct >= 0.9 ? Colors.red.shade500 : pct >= 0.7 ? Colors.orange.shade500 : primaryColor;

                      return GestureDetector(
                        onTap: () => _showEditLimit(kat, isDark, primaryColor, cardColor, textColor),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isOver ? Colors.red.withOpacity(0.3) : Colors.transparent),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(kat, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                  if (isOver) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade500),
                                  ],
                                  const Spacer(),
                                  Text(
                                    '₺${_fmt(spent)} / ₺${_fmt(limit)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade400),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isOver ? 'Limit aşıldı!' : '₺${_fmt(limit - spent)} kalan',
                                    style: TextStyle(fontSize: 11, color: isOver ? Colors.red : Colors.grey.shade500),
                                  ),
                                  Text('%${(pct * 100).toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
