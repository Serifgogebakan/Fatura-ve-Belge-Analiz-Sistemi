import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/documents_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_screen.dart';

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
  List<double> _weeklySpendings = List.filled(7, 0.0);
  List<double> _monthlySpendings = List.filled(12, 0.0);
  double _maxWeeklySpending = 100.0;
  double _maxMonthlySpending = 100.0;
  bool _showMonthly = false;
  List<Map<String, dynamic>> _recentDocs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

      // Toplam harcama
      final docsResponse = await _supabase
          .from('documents')
          .select('amount, payment_status, name, file_type, created_at, belge_tipi')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      double total = 0;
      double thisMonthTotal = 0;
      double lastMonthTotal = 0;
      double pendingTotal = 0;
      int overdueCount = 0;
      List<double> weekly = List.filled(7, 0.0);
      List<double> monthly = List.filled(12, 0.0);
      final now = DateTime.now();
      final currentYear = now.year;
      
      final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
      final firstDayOfLastMonth = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1, 1);

      for (final doc in docsResponse) {
        final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
        final status = doc['payment_status'] as String?;
        final belgeTipi = (doc['belge_tipi'] as String?) ?? 'gider';
        final createdAtStr = doc['created_at'] as String?;

        if (createdAtStr != null) {
          try {
            final dt = DateTime.parse(createdAtStr).toLocal();

            // Kurumsal Nakit Akışı: SADECE BU YIL
            if (dt.year == currentYear && belgeTipi != 'gelir') {
              total += amount;
            }

            if (belgeTipi != 'gelir') {
              if (dt.isAfter(firstDayOfThisMonth) || dt.isAtSameMomentAs(firstDayOfThisMonth)) {
                thisMonthTotal += amount;
              } else if (dt.isAfter(firstDayOfLastMonth) || dt.isAtSameMomentAs(firstDayOfLastMonth)) {
                lastMonthTotal += amount;
              }

              // Haftalık
              final diff = now.difference(dt).inDays;
              if (diff >= 0 && diff <= 7) {
                weekly[dt.weekday - 1] += amount;
              }

              // Aylık (bu yıl)
              if (dt.year == currentYear) {
                monthly[dt.month - 1] += amount;
              }
            }
          } catch (_) {}
        }

        if (status != null && status.toLowerCase() == 'bekliyor' && belgeTipi != 'gelir') {
          pendingTotal += amount;
          overdueCount++;
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
      for (double val in weekly) { if (val > maxWeekly) maxWeekly = val; }
      maxWeekly *= 1.2;

      double maxMonthly = 10;
      for (double val in monthly) { if (val > maxMonthly) maxMonthly = val; }
      maxMonthly *= 1.2;

      final recent = docsResponse.take(3).toList();

      setState(() {
        _totalSpending = total;
        _bekleyenFaturaTutari = pendingTotal;
        _gecikmisFaturaSayisi = overdueCount;
        _monthlyComparison = comparisonStr;
        _isIncrease = increase;
        _weeklySpendings = weekly;
        _monthlySpendings = monthly;
        _maxWeeklySpending = maxWeekly;
        _maxMonthlySpending = maxMonthly;
        _recentDocs = List<Map<String, dynamic>>.from(recent);
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
                        child: Icon(Icons.person, color: primaryColor, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      body: pages[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 56,
        width: 56,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploadScreen()),
            ).then((_) => _loadDashboardData());
          },
          backgroundColor: primaryColor,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: cardColor,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.dashboard_rounded,
                'DASHBOARD',
                0,
                isDark,
                primaryColor,
              ),
              _buildNavItem(
                Icons.description_outlined,
                'BELGELER',
                1,
                isDark,
                primaryColor,
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                Icons.bar_chart_rounded,
                'RAPORLAR',
                2,
                isDark,
                primaryColor,
              ),
              _buildNavItem(
                Icons.person_outline,
                'PROFİL',
                3,
                isDark,
                primaryColor,
              ),
            ],
          ),
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

  Widget _buildDashboard(
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
  ) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KURUMSAL NAKİT AKIŞI KARTI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0052FF), // Resimdeki tam mavi
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0052FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KURUMSAL NAKİT AKIŞI',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? const SizedBox(
                                  height: 42,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : Text(
                                  '₺${_formatAmount(_totalSpending)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Yıllık Ciro Hedefi',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${((_totalSpending / _ciroHedefi) * 100).toInt()}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: ((_totalSpending / _ciroHedefi) * 100).toInt().clamp(0, 100),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (100 - ((_totalSpending / _ciroHedefi) * 100).toInt()).clamp(0, 100),
                          child: const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hedeflenen ciroya ulaşmak için ₺${_formatAmount((_ciroHedefi - _totalSpending).clamp(0, double.infinity))} daha\ngerekli.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // İŞLETME METRİKLERİ
            Text(
              'İşletme Metrikleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _buildMetricCard(
                    title: 'Bekleyen Faturalar',
                    amount: '₺${_formatAmount(_bekleyenFaturaTutari)}',
                    footerText: '$_gecikmisFaturaSayisi Gecikmiş',
                    footerIcon: Icons.warning_amber_rounded,
                    footerColor: _gecikmisFaturaSayisi > 0 ? Colors.red : Colors.green,
                    icon: Icons.assignment_outlined,
                    iconBg: Colors.blue.withOpacity(0.1),
                    iconColor: Colors.blue,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(width: 16),
                  _buildMetricCard(
                    title: 'Vergi Yükü (Tahmini)',
                    amount: '₺${_formatAmount(_totalSpending * 0.20)}', // %20 KDV tahmini
                    footerText: 'Son Tarih: 24 May',
                    footerIcon: Icons.calendar_today_outlined,
                    footerColor: Colors.grey.shade600,
                    icon: Icons.account_balance_wallet_outlined,
                    iconBg: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // HARCAMA ANALİZİ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Harcama Analizi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                GestureDetector(
                  onTap: () => setState(() => _showMonthly = !_showMonthly),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _showMonthly ? 'HAFTALIK GÖRÜNÜM' : 'AYLIK GÖRÜNÜM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BAR CHART KARTI
            Container(
              height: 180,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _showMonthly ? _maxMonthlySpending : _maxWeeklySpending,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        '₺${_formatAmount(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
                            const d = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
                            label = i < d.length ? d[i] : '';
                            isActive = DateTime.now().weekday - 1 == i;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: TextStyle(
                              color: isActive ? primaryColor : Colors.grey.shade500,
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
                  barGroups: _showMonthly
                    ? [for (int i = 0; i < 12; i++) _bar(i, _monthlySpendings[i], isDark, primaryColor, DateTime.now().month - 1 == i)]
                    : [for (int i = 0; i < 7; i++) _bar(i, _weeklySpendings[i], isDark, primaryColor, DateTime.now().weekday - 1 == i)],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SON YÜKLENEN BELGELER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Yüklenen Belgeler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BELGE LİSTESİ
            if (_isLoading)
              _buildLoadingList()
            else if (_recentDocs.isEmpty)
              _buildEmptyState(textColor)
            else
              ..._recentDocs.map(
                (doc) => _buildDocumentItem(doc, isDark, cardColor),
              ),

            const SizedBox(height: 100),
          ],
        ),
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
    double y,
    bool isDark,
    Color primaryColor,
    bool isSelected,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 10,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxWeeklySpending,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
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
}
