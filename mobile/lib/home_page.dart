import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    // Sayfaların Listesi
    final List<Widget> pages = [
      _buildDashboard(isDark, primaryColor, cardColor, textColor),
      Center(child: Text("DOCUMENTS SAYFASI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))),
      Center(child: Text("REPORTS SAYFASI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))),
      Center(child: Text("PROFILE SAYFASI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))),
    ];

    return Scaffold(
      extendBody: true, // Bu ayar BottomAppBar'ın kavisinin tam oturmasını sağlar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: primaryColor),
          onPressed: () {},
        ),
        title: Text(
          'BillMind',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              child: Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          onPressed: () {
            // Belge Yükleme sayfasına git
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Scaffold(
                appBar: AppBar(title: const Text("Dosya Yükle")),
                body: const Center(child: Text("DOSYA EKLEME SAYFASI", style: TextStyle(fontSize: 24))),
              )),
            );
          },
          backgroundColor: primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: cardColor,
        elevation: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_rounded, 'DASHBOARD', 0, isDark),
              _buildNavItem(Icons.document_scanner, 'DOCUMENTS', 1, isDark),
              const SizedBox(width: 48), // Orta UPLOAD butonu için yer açıyoruz
              _buildNavItem(Icons.bar_chart, 'REPORTS', 2, isDark),
              _buildNavItem(Icons.person, 'PROFILE', 3, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // Dashboard Görünümü
  Widget _buildDashboard(bool isDark, Color primaryColor, Color cardColor, Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOPLAM HARCAMA KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF3B82F6), const Color(0xFF1E3A8A)]
                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOPLAM HARCAMA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '₺142.850,00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Geçen aya göre %12 artış',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // HARCAMA ANALİZİ BAŞLIĞI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harcama Analizi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'AYLIK GÖRÜNÜM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CHART KARTI
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4)),
              ]
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: value.toInt() == 2 ? primaryColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              fontSize: 10,
                              fontWeight: value.toInt() == 2 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBar(0, 60, isDark, primaryColor, false),
                  _buildBar(1, 40, isDark, primaryColor, false),
                  _buildBar(2, 85, isDark, primaryColor, true),
                  _buildBar(3, 45, isDark, primaryColor, false),
                  _buildBar(4, 25, isDark, primaryColor, false),
                  _buildBar(5, 30, isDark, primaryColor, false),
                  _buildBar(6, 20, isDark, primaryColor, false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // SON YÜKLENEN BELGELER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Yüklenen Belgeler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'Tümünü Gör',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // LİSTE ELEMANLARI
          _buildDocumentItem(
            title: 'Turkcell A.Ş.',
            subtitle: '12 Haz 2024 • Fatura',
            amount: '₺850,00',
            status: 'ONAYLANDI',
            icon: Icons.description,
            isDark: isDark,
            cardColor: cardColor,
          ),
          _buildDocumentItem(
            title: 'Starbucks Coffee',
            subtitle: '10 Haz 2024 • Fiş',
            amount: '₺185,50',
            status: 'BEKLEMEDE',
            icon: Icons.receipt_long,
            isDark: isDark,
            cardColor: cardColor,
            isPending: true,
          ),
          _buildDocumentItem(
            title: 'Amazon Turkey',
            subtitle: '08 Haz 2024 • Sipariş',
            amount: '₺2.450,00',
            status: 'ONAYLANDI',
            icon: Icons.shopping_bag,
            isDark: isDark,
            cardColor: cardColor,
          ),
          
          const SizedBox(height: 100), // En alt öğenin menü altında kalmaması için
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    bool isSelected = _currentIndex == index;
    final color = isSelected 
        ? (isDark ? Colors.blue.shade400 : Colors.blue.shade700) 
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, bool isDark, Color primaryColor, bool isSelected) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isSelected 
              ? primaryColor 
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 12,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String subtitle,
    required String amount,
    required String status,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    bool isPending = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending 
                      ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                      : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPending
                        ? (isDark ? Colors.grey.shade300 : Colors.grey.shade700)
                        : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
