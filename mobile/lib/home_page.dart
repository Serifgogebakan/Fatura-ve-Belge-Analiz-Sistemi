import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _totalSpending = 0;
  String _monthlyComparison = '%0 değişim';
  bool _isIncrease = true;
  
  List<double> _weeklyIncome = List.filled(7, 0.0);
  List<double> _weeklyExpense = List.filled(7, 0.0);
  List<double> _monthlyIncome = List.filled(12, 0.0);
  List<double> _monthlyExpense = List.filled(12, 0.0);

  double _maxWeeklySpending = 100.0;
  double _maxMonthlySpending = 100.0;
  bool _showMonthly = false;
  List<Map<String, dynamic>> _recentDocs = [];
  List<Map<String, dynamic>> _pendingDocs = [];
  
  String _companyName = '';
  String _fullName = '';
  String? _avatarUrl;

  double _aylikGelir = 0.0;
  int _bekleyenFaturaSayisi = 0;
  double _belgeIslemeOrani = 0.0;
  double _toplamBakiye = 0.0;
  double _aylikCiro = 0.0;
  double _vergiYuku = 0.0;
  double _netKarMarji = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Ödeme yaklaşan faturaları kontrol et ve bildir
    NotificationService.checkAndNotifyDueDocs();
  }

  double _ciroHedefi = 1000000; // Varsayılan 1M
  double _bekleyenFaturaTutari = 0;
  int _gecikmisFaturaSayisi = 0;

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _ciroHedefi = prefs.getDouble('ciroHedefi') ?? 1000000.0;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Profil bilgilerini yükle
      String company = '';
      String name = '';
      String? avatar;
      try {
        final profileData = await _supabase
            .from('profiles')
            .select('full_name, company_name, avatar_cloudinary_url')
            .eq('id', userId)
            .maybeSingle();
        if (profileData != null) {
          company = (profileData['company_name'] as String?) ?? '';
          name = (profileData['full_name'] as String?) ?? '';
          avatar = profileData['avatar_cloudinary_url'] as String?;
        }
      } catch (_) {}

      // Toplam harcama
      final docsResponse = await _supabase
          .from('documents')
          .select('id, amount, payment_status, name, file_type, created_at, belge_tipi, category')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      double total = 0;
      double thisMonthTotal = 0;
      double lastMonthTotal = 0;
      double pendingTotal = 0;
      int overdueCount = 0;
      
      List<double> weeklyInc = List.filled(7, 0.0);
      List<double> weeklyExp = List.filled(7, 0.0);
      List<double> monthlyInc = List.filled(12, 0.0);
      List<double> monthlyExp = List.filled(12, 0.0);

      double aylikGelirVal = 0;
      double totalIncome = 0;
      double totalExpense = 0;
      int bekleyenFaturaSayisiVal = 0;
      int processedCount = 0;

      final now = DateTime.now();
      final currentYear = now.year;
      
      final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
      final firstDayOfLastMonth = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, 1);

      for (final doc in docsResponse) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
        final status = doc['payment_status'] as String?;
        final belgeTipi = (doc['belge_tipi'] as String?) ?? 'gider';
        final createdAtStr = doc['created_at'] as String?;

        if (belgeTipi == 'gelir') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }

        if (status != null && status.toLowerCase() != 'bekliyor') {
          processedCount++;
        }

        if (createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();

            // Kurumsal Nakit Akışı: SADECE BU YIL
            if (dt.year == currentYear && belgeTipi != 'gelir') {
              total += amount;
            }

            if (belgeTipi == 'gelir') {
              if (dt.year == now.year && dt.month == now.month) {
                aylikGelirVal += amount;
              }
            } else {
              if (dt.isAfter(firstDayOfThisMonth) || dt.isAtSameMomentAs(firstDayOfThisMonth)) {
                thisMonthTotal += amount;
              } else if (dt.isAfter(firstDayOfLastMonth) || dt.isAtSameMomentAs(firstDayOfLastMonth)) {
                lastMonthTotal += amount;
              }
            }

            // Haftalık
            final diff = now.difference(dt).inDays;
            if (diff >= 0 && diff < 7) {
              final idx = dt.weekday - 1;
              if (belgeTipi == 'gelir') {
                weeklyInc[idx] += amount;
              } else {
                weeklyExp[idx] += amount;
              }
            }

            // Aylık (bu yıl)
            if (dt.year == currentYear) {
              final idx = dt.month - 1;
              if (belgeTipi == 'gelir') {
                monthlyInc[idx] += amount;
              } else {
                monthlyExp[idx] += amount;
              }
            }
          } catch (_) {}
        }

        if (status != null && belgeTipi != 'gelir') {
          final s = status.toLowerCase();
          if (s == 'bekliyor' || s == 'gecikti') {
            pendingTotal += amount;
            bekleyenFaturaSayisiVal++;
          }
          if (s == 'gecikti') {
            overdueCount++;
          }
        }
      }

      // Filtrelenmiş bekleyen onaylar
      List<Map<String, dynamic>> pending = [];
      for (final doc in docsResponse) {
        final status = doc['payment_status'] as String?;
        final belgeTipi = (doc['belge_tipi'] as String?) ?? 'gider';
        if (status != null && belgeTipi != 'gelir') {
          final s = status.toLowerCase();
          if (s == 'bekliyor' || s == 'beklemede' || s == 'gecikti') {
            pending.add(doc);
          }
        }
      }

      String comparisonStr = '%0 değişim';
      bool increase = true;
      if (lastMonthTotal > 0) {
        double change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
        increase = change >= 0;
        comparisonStr = 'Geçen aya göre %${change.abs().toStringAsFixed(1)} ${increase ? 'artış' : 'düşüş'}';
      } else if (thisMonthTotal > 0) {
        comparisonStr = 'Geçen aya göre %100 artış';
      }

      double maxWeekly = 10;
      for (int i = 0; i < 7; i++) {
        final sum = weeklyInc[i] + weeklyExp[i];
        if (sum > maxWeekly) maxWeekly = sum;
      }
      maxWeekly *= 1.2;

      double maxMonthly = 10;
      for (int i = 0; i < 12; i++) {
        final sum = monthlyInc[i] + monthlyExp[i];
        if (sum > maxMonthly) maxMonthly = sum;
      }
      maxMonthly *= 1.2;

      final recent = docsResponse.take(3).toList();

      setState(() {
        _totalSpending = total;
        _bekleyenFaturaTutari = pendingTotal;
        _gecikmisFaturaSayisi = overdueCount;
        _monthlyComparison = comparisonStr;
        _isIncrease = increase;
        _weeklyIncome = weeklyInc;
        _weeklyExpense = weeklyExp;
        _monthlyIncome = monthlyInc;
        _monthlyExpense = monthlyExp;
        _maxWeeklySpending = maxWeekly;
        _maxMonthlySpending = maxMonthly;
        _recentDocs = List<Map<String, dynamic>>.from(recent);
        _pendingDocs = pending;
        _companyName = company;
        _fullName = name;
        _avatarUrl = avatar;
        
        _aylikGelir = aylikGelirVal;
        _bekleyenFaturaSayisi = bekleyenFaturaSayisiVal;
        _belgeIslemeOrani = docsResponse.isEmpty ? 0.0 : (processedCount / docsResponse.length * 100);

        _toplamBakiye = totalIncome - totalExpense;
        _aylikCiro = aylikGelirVal;
        _vergiYuku = totalExpense * 0.20;
        
        if (totalIncome > 0) {
          _netKarMarji = ((totalIncome - totalExpense) / totalIncome) * 100;
        } else {
          _netKarMarji = 0.0;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF3B82F6)
        : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final List<Widget> pages = [
      _buildDashboard(isDark, primaryColor, cardColor, textColor),
      const DocumentsScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: (_currentIndex == 2 || _currentIndex == 3)
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildAppBarTitle(_currentIndex, textColor, primaryColor),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 3),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor.withOpacity(0.15),
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? null
                            : (_getInitials(_companyName.isNotEmpty ? _companyName : _fullName).isNotEmpty
                                ? Text(
                                    _getInitials(_companyName.isNotEmpty ? _companyName : _fullName),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  )
                                : Icon(Icons.person, color: primaryColor, size: 20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      body: pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withOpacity(0.85) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLiquidNavItem(0, Icons.grid_view_rounded, 'Panel', isDark, primaryColor, textColor),
                _buildLiquidNavItem(1, Icons.receipt_long_rounded, 'Belgeler', isDark, primaryColor, textColor),
                // Static ADD Button in the center
                GestureDetector(
                  onTap: () => _showAddOptions(context, primaryColor, isDark),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                _buildLiquidNavItem(2, Icons.analytics_outlined, 'Raporlar', isDark, primaryColor, textColor),
                _buildLiquidNavItem(3, Icons.person_rounded, 'Profil', isDark, primaryColor, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidNavItem(
    int index,
    IconData icon,
    String label,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : (isDark ? Colors.white60 : Colors.black45),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(int index, Color textColor, Color primaryColor) {
    final titles = ['BillMind', 'Belgelerim', 'BillMind', 'Profil'];
    bool showBadge = index == 0;

    if (showBadge) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'BillMind',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      );
    }
    return Text(
      titles[index],
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  void _showAddOptions(BuildContext context, Color primaryColor, bool isDark) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Kayıt Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text('Belge yükle veya manuel kayıt gir', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            _addOptionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Fotoğraf / Tarama',
              subtitle: 'Fatura veya belge tarayıp yükle',
              color: primaryColor,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()))
                    .then((_) => _loadDashboardData());
              },
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _addOptionTile(
              icon: Icons.edit_note_rounded,
              title: 'Manuel Giriş',
              subtitle: 'Fotoğraf olmadan gelir/gider kaydet',
              color: Colors.green.shade600,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntryScreen()))
                    .then((_) => _loadDashboardData());
              },
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _addOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Bütçe Takibi',
              subtitle: 'Kategori bazında bütçe limiti belirle',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen()));
              },
              isDark: isDark,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _addOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
  ) {
    final nameParts = _fullName.trim().split(' ');
    final firstName = nameParts.isNotEmpty && nameParts[0].isNotEmpty ? nameParts[0] : 'Kullanıcı';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOPLAM BAKİYE KARTI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF0052FF)).withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam Bakiye',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₺${_formatAmount(_toplamBakiye)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.12), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AYLIK CİRO',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+₺${_formatAmount(_aylikCiro)}',
                              style: const TextStyle(
                                color: Color(0xFF4ADE80),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERGİ YÜKÜ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${_formatAmount(_vergiYuku)}',
                              style: const TextStyle(
                                color: Color(0xFFF87171),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KART SAHİBİ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fullName.isNotEmpty ? _fullName.toUpperCase() : 'AD SOYAD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. FİNANSAL TRENDLER KARTI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Finansal Trendler',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      // Segmented Control (Toggle)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showMonthly = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !_showMonthly
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_showMonthly
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]
                                      : [],
                                ),
                                child: Text(
                                  'Günlük',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: !_showMonthly ? primaryColor : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showMonthly = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _showMonthly
                                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _showMonthly
                                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]
                                      : [],
                                ),
                                child: Text(
                                  'Aylık',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _showMonthly ? primaryColor : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _showMonthly ? _maxMonthlySpending : _maxWeeklySpending,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final double incomeY = _showMonthly ? _monthlyIncome[groupIndex] : _weeklyIncome[groupIndex];
                              final double expenseY = _showMonthly ? _monthlyExpense[groupIndex] : _weeklyExpense[groupIndex];
                              return BarTooltipItem(
                                'Gelir: ₺${_formatAmount(incomeY)}\nGider: ₺${_formatAmount(expenseY)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                String label;
                                bool isActive;
                                if (_showMonthly) {
                                  const m = ['O','Ş','M','N','M','H','T','A','E','E','K','A'];
                                  label = i < m.length ? m[i] : '';
                                  isActive = DateTime.now().month - 1 == i;
                                } else {
                                  const d = ['PZT','SAL','ÇAR','PER','CUM','CMT','PAZ'];
                                  label = i < d.length ? d[i] : '';
                                  isActive = DateTime.now().weekday - 1 == i;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(label, style: TextStyle(
                                    color: isActive ? const Color(0xFF0052FF) : Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  )),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < (_showMonthly ? 12 : 7); i++)
                            _bar(i, isDark, primaryColor, (_showMonthly ? DateTime.now().month - 1 : DateTime.now().weekday - 1) == i)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. DİKEY METRİK KARTLARI
            _buildVerticalMetricCard(
              title: 'Bekleyen Faturalar',
              value: '$_bekleyenFaturaSayisi Adet',
              icon: Icons.assignment_outlined,
              iconColor: Colors.orange.shade700,
              iconBg: Colors.orange.withOpacity(0.12),
              cardColor: cardColor,
              textColor: textColor,
              isDark: isDark,
              onInfoTap: () => _showMetricInfoDialog(
                title: 'Bekleyen Faturalar',
                desc: 'Ödenmemiş veya vadesi geçmiş gider belgelerinizin toplam adedini gösterir.',
                formula: 'Supabase veritabanındaki "payment_status" değeri "bekliyor" veya "gecikti" olan faturalar filtrelenerek hesaplanır.',
                tip: 'Faturalarınızı zamanında ödeyip durumlarını "Ödendi" olarak güncelleyerek bu sayıyı azaltabilir, gecikme faizlerinden kaçınabilirsiniz.',
                iconColor: Colors.orange.shade700,
                icon: Icons.assignment_outlined,
              ),
            ),
            _buildVerticalMetricCard(
              title: 'Tahmini Vergi Yükü',
              value: '₺${_formatAmount(_vergiYuku)}',
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFF0052FF),
              iconBg: const Color(0xFF0052FF).withOpacity(0.12),
              cardColor: cardColor,
              textColor: textColor,
              isDark: isDark,
              onInfoTap: () => _showMetricInfoDialog(
                title: 'Tahmini Vergi Yükü',
                desc: 'Mevcut toplam giderlerinizin tahmini %20\'si (ortalama KDV oranı) hesaplanarak öngörülen vergi yükünü belirtir.',
                formula: 'Toplam Gider Tutarı x 0.20 (KDV Tahmini Oranı)',
                tip: 'Vergi muafiyeti olan resmi gider belgelerinizi düzenli olarak sisteme yükleyip gider göstererek dönem sonu vergi matrahınızı optimize edebilirsiniz.',
                iconColor: const Color(0xFF0052FF),
                icon: Icons.account_balance_outlined,
              ),
            ),
            _buildVerticalMetricCard(
              title: 'Net Kar Marjı',
              value: '%${_netKarMarji.toStringAsFixed(1)}',
              icon: Icons.trending_up,
              iconColor: Colors.green,
              iconBg: Colors.green.withOpacity(0.12),
              cardColor: cardColor,
              textColor: textColor,
              isDark: isDark,
              onInfoTap: () => _showMetricInfoDialog(
                title: 'Net Kar Marjı',
                desc: 'Şirketinizin elde ettiği toplam gelirin yüzde kaçının net kâra dönüştüğünü gösteren temel karlılık göstergesidir.',
                formula: '((Toplam Gelir - Toplam Gider) / Toplam Gelir) x 100',
                tip: 'Gereksiz gider kalemlerini analiz edip kısarak veya satış gelirlerinizi artırarak net kâr marjınızı daha yukarılara taşıyabilirsiniz.',
                iconColor: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(height: 20),

            // 4. HIZLI İŞLEMLER
            _buildQuickActionsGrid(isDark, cardColor, textColor),
            const SizedBox(height: 24),

            // 5. YAPAY ZEKA ANALİZİ
            _buildAiAssistantCard(isDark, cardColor, textColor, firstName),
            const SizedBox(height: 24),

            // 6. SON İŞLEMLER
            _buildRecentTransactionsCard(isDark, cardColor, textColor, primaryColor),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _openAiChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          bakiye: _toplamBakiye,
          ciro: _aylikCiro,
          vergiYuku: _vergiYuku,
          karMarji: _netKarMarji,
          userName: _fullName.isNotEmpty ? _fullName : 'Kullanıcı',
        ),
      ),
    );
  }

  void _showMetricInfoDialog({
    required String title,
    required String desc,
    required String formula,
    required String tip,
    required Color iconColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nasıl Hesaplanır?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formula,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Anladım',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
    VoidCallback? onInfoTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (onInfoTap != null)
            GestureDetector(
              onTap: onInfoTap,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantCard(bool isDark, Color cardColor, Color textColor, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yapay Zeka Analizi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openAiChat,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF0052FF).withOpacity(0.12),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF0052FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BillMind AI Asistan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          const SizedBox(height: 2),
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
                                '• Çevrimiçi',
                                style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                  ),
                  child: Text(
                    'Merhaba $firstName! Finansal verilerini analiz ettim. Harcama optimizasyonu hakkında ne sormak istersin?',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI ile sohbete başla...',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0052FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isDark, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _quickGridItem(
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFF0052FF),
              title: 'Fiş Tara',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()))
                  .then((_) => _loadDashboardData()),
              cardColor: cardColor,
              textColor: textColor,
            ),
            _quickGridItem(
              icon: Icons.psychology_outlined,
              iconColor: const Color(0xFF0052FF),
              title: 'Yapay Zeka Analizi',
              onTap: () => setState(() => _currentIndex = 2),
              cardColor: cardColor,
              textColor: textColor,
            ),
            _quickGridItem(
              icon: Icons.list_alt_outlined,
              iconColor: const Color(0xFF0052FF),
              title: 'Fatura Listesi',
              onTap: () => setState(() => _currentIndex = 1),
              cardColor: cardColor,
              textColor: textColor,
            ),
            _quickGridItem(
              icon: Icons.bar_chart_outlined,
              iconColor: Colors.orange.shade600,
              title: 'Raporlar',
              onTap: () => setState(() => _currentIndex = 2),
              cardColor: cardColor,
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnalysisCard(bool isDark, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yapay Zeka Analizi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A8A).withOpacity(0.4), const Color(0xFF0F172A)]
                  : [const Color(0xFFEFF6FF), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF3B82F6).withOpacity(0.3) : const Color(0xFFBFDBFE),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Harcama Optimizasyonu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Son 30 gündeki bulut hizmeti harcamalarınızda normalden %12\'lik bir artış tespit edildi. Rezerve kapasite kullanarak yıllık bazda ₺14.500 tasarruf edebilirsiniz.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0052FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Detaylı Analizi Gör',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard(bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    if (_recentDocs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son İşlemler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Kayıtlı Belge Bulunmuyor',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Eklediğiniz fatura ve makbuzlar burada listelenir.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ],
      );
    }

    final displayList = _recentDocs.map((doc) {
      final belgeTipi = doc['belge_tipi'] as String? ?? 'gider';
      final status = (doc['payment_status'] as String?)?.toUpperCase() ?? 'ONAYLANDI';
      final amount = doc['amount'] as double? ?? 0.0;
      final date = _formatDate(doc['created_at'] ?? '');
      
      Color statColor = const Color(0xFF0052FF);
      if (status == 'ÖDENDİ' || status == 'ONAYLANDI') {
        statColor = Colors.green;
      } else if (status == 'BEKLİYOR' || status == 'İNCELENİYOR' || status == 'BEKLEMEDE') {
        statColor = Colors.orange;
      }

      IconData icon = Icons.description_outlined;
      if (belgeTipi == 'gelir') {
        icon = Icons.monetization_on_outlined;
      } else if (doc['name']?.toLowerCase().contains('coffee') ?? false) {
        icon = Icons.local_cafe_outlined;
      }

      return {
        'name': doc['name'] ?? 'Bilinmeyen',
        'subtitle': '${belgeTipi == 'gelir' ? 'Gelir' : 'Gider'} • $date',
        'amount': '${belgeTipi == 'gelir' ? '+' : '-'}₺${_formatAmount(amount)}',
        'status': status,
        'statusColor': statColor,
        'icon': icon,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Son İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Text(
                'Tümünü Gör',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              for (int i = 0; i < displayList.length; i++) ...[
                _transactionItem(
                  name: displayList[i]['name'] as String,
                  subtitle: displayList[i]['subtitle'] as String,
                  amount: displayList[i]['amount'] as String,
                  status: displayList[i]['status'] as String,
                  statusColor: displayList[i]['statusColor'] as Color,
                  icon: displayList[i]['icon'] as IconData,
                  isDark: isDark,
                  textColor: textColor,
                ),
                if (i < displayList.length - 1)
                  Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _transactionItem({
    required String name,
    required String subtitle,
    required String amount,
    required String status,
    required Color statusColor,
    required IconData icon,
    required bool isDark,
    required Color textColor,
  }) {
    final isIncome = amount.startsWith('+');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDark ? Colors.white70 : Colors.black87, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 76,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Henüz belge yüklenmedi',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(
    Map<String, dynamic> doc,
    bool isDark,
    Color cardColor,
  ) {
    final status = (doc['payment_status'] as String?) ?? 'beklemede';
    final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
    final title = (doc['name'] as String?) ?? 'Belge';
    final type = (doc['file_type'] as String?) ?? 'Diğer';
    final createdAt = doc['created_at'] as String?;
    final date = createdAt != null ? _formatDate(createdAt) : '-';

    String statusLabel;
    Color statusColor;
    Color statusBg;

    switch (status.toLowerCase()) {
      case 'ödendi':
        statusLabel = 'ÖDENDİ';
        statusColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        statusBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        break;
      case 'incelemede':
        statusLabel = 'İNCELEMEDE';
        statusColor = Colors.orange.shade400;
        statusBg = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;
        break;
      default:
        statusLabel = 'BEKLEMEDE';
        statusColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
        statusBg = isDark
            ? Colors.amber.withOpacity(0.15)
            : Colors.amber.shade50;
    }

    IconData icon = Icons.description_outlined;
    if (type.toLowerCase().contains('fatura')) icon = Icons.receipt_long;
    if (type.toLowerCase().contains('fiş') ||
        type.toLowerCase().contains('fis'))
      icon = Icons.receipt;
    if (type.toLowerCase().contains('sipariş') ||
        type.toLowerCase().contains('siparis'))
      icon = Icons.shopping_bag_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade500, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$date • $type',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${_formatAmount(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    bool isDark,
    Color primaryColor,
  ) {
    bool isSelected = _currentIndex == index;
    final color = isSelected
        ? primaryColor
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(
    int x,
    bool isDark,
    Color primaryColor,
    bool isSelected,
  ) {
    final double incomeY = _showMonthly ? _monthlyIncome[x] : _weeklyIncome[x];
    final double expenseY = _showMonthly ? _monthlyExpense[x] : _weeklyExpense[x];

    final double maxY = _showMonthly ? _maxMonthlySpending : _maxWeeklySpending;
    


    final Color incomeColor = isSelected ? const Color(0xFF2E4CB9) : const Color(0xFF0052FF);
    final Color expenseColor = isDark 
        ? (isSelected ? const Color(0xFF475569) : const Color(0xFF334155))
        : (isSelected ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    final double renderIncomeY = incomeY == 0 ? maxY * 0.06 : incomeY;
    final double renderExpenseY = expenseY == 0 ? maxY * 0.06 : expenseY;

    final Color incomeRodColor = incomeY == 0
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
        : incomeColor;

    final Color expenseRodColor = expenseY == 0
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
        : expenseColor;

    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
          toY: renderIncomeY,
          color: incomeRodColor,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: renderExpenseY,
          color: expenseRodColor,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '0,00';
    final str = amount.toStringAsFixed(2).replaceAll('.', ',');
    final parts = str.split(',');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()},$decPart';
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String footerText,
    required IconData footerIcon,
    required Color footerColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(footerIcon, size: 12, color: footerColor),
              const SizedBox(width: 4),
              Text(footerText, style: TextStyle(fontSize: 10, color: footerColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    List<String> words = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    if (words.isNotEmpty && words[0].isNotEmpty) {
      initials += words[0][0].toUpperCase();
    }
    if (words.length > 1 && words[1].isNotEmpty) {
      initials += words[1][0].toUpperCase();
    }
    return initials;
  }

  Widget _buildQuickActions(bool isDark, Color primaryColor, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _quickActionItem(
                icon: Icons.add_circle,
                iconColor: Colors.blue.shade600,
                title: 'Yeni Fatura',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()))
                    .then((_) => _loadDashboardData()),
                isDark: isDark,
                textColor: textColor,
              ),
              Divider(height: 20, color: isDark ? Colors.white10 : Colors.grey.shade100),
              _quickActionItem(
                icon: Icons.bar_chart,
                iconColor: Colors.orange.shade600,
                title: 'Raporlar',
                onTap: () => setState(() => _currentIndex = 2),
                isDark: isDark,
                textColor: textColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
               ),
             ),
             Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
           ],
         ),
       ),
     );
   }

   void _showSuppliersBottomSheet(bool isDark, Color cardColor, Color textColor) {
     showModalBottomSheet(
       context: context,
       backgroundColor: cardColor,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
       builder: (ctx) {
         return Padding(
           padding: const EdgeInsets.all(24),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text('Tedarikçilerim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
               const SizedBox(height: 6),
               Text('En çok işlem yaptığınız iş ortaklarınız', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
               const SizedBox(height: 20),
               _supplierTile('TechCorp IT Hizmetleri', 'Altyapı & Donanım', isDark, textColor),
               const SizedBox(height: 12),
               _supplierTile('Global Lojistik A.Ş.', 'Taşıma & Kargo', isDark, textColor),
               const SizedBox(height: 12),
               _supplierTile('Mega Ofis Kırtasiye', 'Ofis Malzemeleri', isDark, textColor),
               const SizedBox(height: 12),
               _supplierTile('EnerjiTürk Elektrik', 'Kamu Hizmetleri', isDark, textColor),
               const SizedBox(height: 16),
             ],
           ),
         );
       },
     );
   }

   Widget _supplierTile(String name, String sector, bool isDark, Color textColor) {
     return Container(
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
         color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.grey.withOpacity(0.1)),
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
             child: const Icon(Icons.business, color: Colors.blue, size: 20),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                 Text(sector, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
               ],
             ),
           ),
           Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
         ],
       ),
     );
   }

  Widget _buildPendingApprovals(bool isDark, Color primaryColor, Color cardColor, Color textColor) {
    if (_pendingDocs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bekleyen Onaylar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_pendingDocs.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._pendingDocs.map((doc) {
          final isMock = doc['is_mock'] == true;
          final docId = doc['id'];
          final name = doc['name'] ?? 'Bilinmeyen';
          final category = doc['category'] ?? 'Genel';
          final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${_formatAmount(amount)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _approveDocument(docId, name, isMock),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Onayla',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _approveDocument(dynamic id, String name, bool isMock) async {
    try {
      if (isMock) {
        setState(() {
          _pendingDocs.removeWhere((doc) => doc['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name faturası onaylandı.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        await _supabase
            .from('documents')
            .update({'payment_status': 'ödendi'})
            .eq('id', id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name faturası onaylandı.'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura onaylanırken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
