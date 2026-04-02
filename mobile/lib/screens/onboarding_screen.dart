import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Güvenli ve Organize",
      "subtitle": "Tüm finansal verileriniz askeri düzeyde şifreleme ile korunur ve her an erişilebilir.",
      "icon": "security"
    },
    {
      "title": "Yapay Zeka ile Analiz",
      "subtitle": "Yüklediğiniz belgeler anında analiz edilir, harcamalarınız kategorize edilir.",
      "icon": "analytics"
    },
    {
      "title": "Belgelerinizi Yükleyin",
      "subtitle": "Fatura ve fişlerinizin fotoğrafını çekin veya galerinizden kolayca yükleyin.",
      "icon": "upload"
    }
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0052FF);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar (Atla veya Logo vb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BillMind',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () {
                        // Son sayfaya atla
                        _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      },
                      child: Text(
                        'Atla',
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // İçerik PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tasarımsal Görsel / İkon Alanı
                        Container(
                          height: 280,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF151C2C) : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              )
                            ]
                          ),
                          child: Center(
                            child: _buildGraphic(index, primaryColor),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          onboardingData[index]["title"]!,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]["subtitle"]!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Alt Kısım (Noktalar ve Buton)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sayfa Adımı (veya Noktalar)
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index, context, primaryColor),
                    ),
                  ),
                  
                  // İleri / Başla Butonu
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 0 ? "Başla" : "İleri",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_currentPage != 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
            if (_currentPage == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  "© 2026 BILLMIND • DİJİTAL KASA GÜVENCESİ",
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, BuildContext context, Color primaryColor) {
    return Container(
      height: 6,
      width: _currentPage == index ? 24 : 6,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: _currentPage == index ? primaryColor : Colors.grey.shade300,
      ),
    );
  }

  // Sadece göstermelik şık grafikler
  Widget _buildGraphic(int index, Color primaryColor) {
    if (index == 0) {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.lock, color: primaryColor, size: 50),
      );
    } else if (index == 1) {
      return Container(
        width: 120, height: 120,
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.insert_chart, color: primaryColor, size: 50),
      );
    } else {
      return Container(
        width: 180, height: 120,
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.document_scanner, color: primaryColor, size: 50),
      );
    }
  }
}
