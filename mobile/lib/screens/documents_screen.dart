import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allDocs = [];
  String _activeTab = 'all'; // 'all', 'gelir', 'gider'
  String? _selectedCategory;

  final List<String> _categories = ['Fatura', 'Fiş', 'Sözleşme', 'Sağlık', 'Finans', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await _supabase
          .from('documents')
          .select('id, name, file_type, category, amount, payment_status, created_at, cloudinary_secure_url, belge_tipi')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _allDocs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDocs {
    final query = _searchController.text.toLowerCase();
    return _allDocs.where((doc) {
      final title = (doc['name'] as String? ?? '').toLowerCase();
      final belge = (doc['belge_tipi'] as String?) ?? 'gider';
      final cat = (doc['category'] as String? ?? '').toLowerCase();
      final matchSearch = query.isEmpty || title.contains(query);
      final matchTab = _activeTab == 'all' || belge == _activeTab;
      final matchCat = _selectedCategory == null || cat == _selectedCategory!.toLowerCase();
      return matchSearch && matchTab && matchCat;
    }).toList();
  }

  // Ay başlıklarına göre grupla
  Map<String, List<Map<String, dynamic>>> get _groupedByMonth {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final doc in _filteredDocs) {
      final dt = _parseDate(doc['created_at'] as String? ?? '');
      final key = dt != null ? _monthLabel(dt) : 'Bilinmeyen';
      groups.putIfAbsent(key, () => []).add(doc);
    }
    return groups;
  }

  DateTime? _parseDate(String s) {
    try { return DateTime.parse(s).toLocal(); } catch (_) { return null; }
  }

  String _monthLabel(DateTime dt) {
    const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    return '${months[dt.month - 1].toUpperCase()} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final grouped = _groupedByMonth;
    final monthKeys = grouped.keys.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              // SEARCH BAR
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Fatura no, şirket veya tutar ara...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    suffixIcon: Icon(Icons.mic_none, color: Colors.grey.shade500, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // GELİR / GİDER TABS
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _tab('Tümü', 'all', Icons.apps, primaryColor, isDark),
                    _tab('Gelir', 'gelir', Icons.arrow_downward_rounded, Colors.green.shade600, isDark),
                    _tab('Gider', 'gider', Icons.arrow_upward_rounded, Colors.red.shade600, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // KATEGORİ + BELGE SAYISI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showCategorySheet(context, isDark, primaryColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedCategory != null ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: _selectedCategory != null ? Colors.white : Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(_selectedCategory ?? 'Kategori',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _selectedCategory != null ? Colors.white : Colors.grey.shade500)),
                          if (_selectedCategory != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = null),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_filteredDocs.length} Belge',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? _buildSkeleton(isDark, cardColor)
              : _filteredDocs.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: monthKeys.length,
                        itemBuilder: (context, i) {
                          final monthDocs = grouped[monthKeys[i]]!;
                          return _buildMonthGroup(monthKeys[i], monthDocs, isDark, cardColor, primaryColor, textColor);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _tab(String label, String key, IconData icon, Color color, bool isDark) {
    final selected = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey.shade500,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGroup(String month, List<Map<String, dynamic>> docs,
      bool isDark, Color cardColor, Color primaryColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF0052FF), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(month, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
            ],
          ),
        ),
        ...docs.map((doc) => _buildDocItem(doc, isDark, cardColor, primaryColor)),
      ],
    );
  }

  Widget _buildDocItem(Map<String, dynamic> doc, bool isDark, Color cardColor, Color primaryColor) {
    final status = (doc['payment_status'] as String?) ?? 'beklemede';
    final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
    final title = (doc['name'] as String?) ?? 'Belge';
    final category = (doc['category'] as String?) ?? 'Diğer';
    final fileType = (doc['file_type'] as String?) ?? 'image';
    final belge = (doc['belge_tipi'] as String?) ?? 'gider';
    final isGelir = belge == 'gelir';

    Color statusColor; String statusLabel;
    switch (status.toLowerCase()) {
      case 'ödendi': statusLabel = 'ÖDENDİ'; statusColor = Colors.blue.shade600; break;
      case 'gecikti': statusLabel = 'GECİKTİ'; statusColor = Colors.red.shade600; break;
      case 'incelemede': statusLabel = 'İNCELEMEDE'; statusColor = Colors.orange.shade500; break;
      default: statusLabel = 'BEKLİYOR'; statusColor = Colors.amber.shade700;
    }

    // Sol kenarlık rengi - gecikti ise kırmızı
    final borderColor = status.toLowerCase() == 'gecikti' ? Colors.red.shade400 : Colors.transparent;

    return GestureDetector(
      onTap: () => _showEditDocDialog(context, doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Sol renkli şerit (gecikti ise kırmızı)
              if (status.toLowerCase() == 'gecikti')
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isGelir ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isGelir ? Icons.receipt_outlined : Icons.description_outlined,
                          color: isGelir ? Colors.green.shade600 : Colors.blue.shade500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(
                              '${category.toUpperCase()} (${isGelir ? "GELİR" : "GİDER"})',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isGelir ? "+" : ""}₺${_fmt(amount)}',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,
                              color: isGelir ? Colors.green.shade600 : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusLabel,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                        onPressed: () => _showDocOptions(context, doc, isDark),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final buf = StringBuffer();
    for (int i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write('.');
      buf.write(parts[0][i]);
    }
    return '${buf.toString()},${parts[1]}';
  }

  void _showCategorySheet(BuildContext context, bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _categories.map((cat) {
                final sel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = sel ? null : cat);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDocDialog(BuildContext context, Map<String, dynamic> doc) {
    final nameCtrl = TextEditingController(text: doc['name'] ?? '');
    final amountCtrl = TextEditingController(text: doc['amount']?.toString() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Belgeyi Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Firma / Başlık', filled: true, fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Tutar (örn: 1000.50)', filled: true, fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              String tAmount = amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
              double? parsed = double.tryParse(tAmount);
              await _supabase.from('documents').update({'name': nameCtrl.text.trim(), if (parsed != null) 'amount': parsed}).eq('id', doc['id']);
              Navigator.pop(ctx);
              _loadDocuments();
            },
            child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDocOptions(BuildContext context, Map<String, dynamic> doc, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('Görüntüle'), onTap: () { Navigator.pop(ctx); _showDocumentImage(context, doc); }),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Sil', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Emin misiniz?'),
                    content: const Text('Bu belgeyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400), child: const Text('Sil', style: TextStyle(color: Colors.white))),
                    ],
                  ),
                );
                if (ok == true) { await _supabase.from('documents').delete().eq('id', doc['id']); _loadDocuments(); }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentImage(BuildContext context, Map<String, dynamic> doc) {
    final imageUrl = doc['cloudinary_secure_url'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görsel bulunamadı.'))); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(doc['name'] ?? 'Belge', style: const TextStyle(fontSize: 16))),
      body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl, errorBuilder: (_, __, ___) => const Center(child: Text('Görsel yüklenemedi', style: TextStyle(color: Colors.white)))))),
    )));
  }

  Widget _buildSkeleton(bool isDark, Color cardColor) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
    itemCount: 5,
    itemBuilder: (_, __) => Container(margin: const EdgeInsets.only(bottom: 10), height: 72, decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100, borderRadius: BorderRadius.circular(16))),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text('Belge bulunamadı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      const SizedBox(height: 8),
      Text('Yeni belge yükleyin veya filtreyi değiştirin.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
    ]),
  );
}
