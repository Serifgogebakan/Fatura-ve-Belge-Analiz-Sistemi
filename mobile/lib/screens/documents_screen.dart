import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allDocs = [];
  List<Map<String, dynamic>> _filteredDocs = [];

  String? _selectedCategory;
  String? _selectedFilter; // 'date', 'category', 'type'

  final List<String> _categories = ['Fatura', 'Fiş', 'Sözleşme', 'Sağlık', 'Finans', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_filterDocs);
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
          .select('id, name, file_type, category, amount, payment_status, created_at, cloudinary_secure_url')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _allDocs = List<Map<String, dynamic>>.from(response);
        _filteredDocs = List.from(_allDocs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterDocs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDocs = _allDocs.where((doc) {
        final title = (doc['name'] as String? ?? '').toLowerCase();
        final type = (doc['file_type'] as String? ?? '').toLowerCase();
        final matchesSearch = query.isEmpty || title.contains(query) || type.contains(query);
        final matchesCategory = _selectedCategory == null ||
            (doc['category'] as String? ?? '').toLowerCase() ==
                _selectedCategory!.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _filteredDocs = List.from(_allDocs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hasFilter = _selectedCategory != null || _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    hintText: 'Belge Ara...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // FİLTRELE BAŞLIĞI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtrele',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  if (hasFilter)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Text(
                        'Temizle',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // FİLTRE BUTONLARI
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tarih',
                        selected: _selectedFilter == 'date',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () => setState(() {
                              _selectedFilter =
                                  _selectedFilter == 'date' ? null : 'date';
                            })),
                    const SizedBox(width: 8),
                    _filterChip(
                        icon: Icons.category_outlined,
                        label: 'Kategori',
                        selected: _selectedFilter == 'category',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () => _showCategorySheet(context, isDark, primaryColor)),
                    const SizedBox(width: 8),
                    _filterChip(
                        icon: Icons.description_outlined,
                        label: 'Dosya Tipi',
                        selected: _selectedFilter == 'type',
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () => setState(() {
                              _selectedFilter =
                                  _selectedFilter == 'type' ? null : 'type';
                            })),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SONUÇLAR BAŞLIĞI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sonuçlar',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredDocs.length} Belge',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // BELGE LİSTESİ
        Expanded(
          child: _isLoading
              ? _buildLoadingSkeleton(isDark, cardColor)
              : _filteredDocs.isEmpty
                  ? _buildEmpty(isDark)
                  : RefreshIndicator(
                      onRefresh: _loadDocuments,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: _filteredDocs.length,
                        itemBuilder: (context, index) {
                          return _buildDocItem(
                              _filteredDocs[index], isDark, cardColor, primaryColor);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? primaryColor : (isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategori Seç',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? null : cat;
                      _selectedFilter = isSelected ? null : 'category';
                    });
                    _filterDocs();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87))),
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

  Widget _buildDocItem(
      Map<String, dynamic> doc, bool isDark, Color cardColor, Color primaryColor) {
    final status = (doc['payment_status'] as String?) ?? 'beklemede';
    final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
    final title = (doc['name'] as String?) ?? 'Belge';
    final type = (doc['file_type'] as String?) ?? 'Diğer';
    final createdAt = (doc['created_at'] as String?) ?? '';
    final date = createdAt.isNotEmpty ? _formatDate(createdAt) : '-';

    Color statusColor;
    Color statusBg;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'ödendi':
        statusLabel = 'ÖDENDİ';
        statusColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        statusBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        break;
      case 'incelemede':
        statusLabel = 'İNCELEMEDE';
        statusColor = Colors.orange.shade400;
        statusBg = isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
        break;
      default:
        statusLabel = 'BEKLEMEDE';
        statusColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
        statusBg = isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50;
    }

    IconData icon = Icons.description_outlined;
    Color iconBg = Colors.blue.withOpacity(0.1);
    if (type.toLowerCase().contains('sözleşme') || type.toLowerCase().contains('sozlesme')) {
      icon = Icons.gavel;
      iconBg = Colors.purple.withOpacity(0.1);
    } else if (type.toLowerCase().contains('sağlık') || type.toLowerCase().contains('saglik')) {
      icon = Icons.health_and_safety_outlined;
      iconBg = Colors.green.withOpacity(0.1);
    } else if (type.toLowerCase().contains('finans')) {
      icon = Icons.bar_chart;
      iconBg = Colors.orange.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${type.toUpperCase()} • $date',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
            onPressed: () => _showDocOptions(context, doc, isDark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showDocOptions(
      BuildContext context, Map<String, dynamic> doc, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Görüntüle'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Sil', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(ctx);
                await _supabase
                    .from('documents')
                    .delete()
                    .eq('id', doc['id']);
                _loadDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belge bulunamadı',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirin\nveya yeni belge yükleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}
