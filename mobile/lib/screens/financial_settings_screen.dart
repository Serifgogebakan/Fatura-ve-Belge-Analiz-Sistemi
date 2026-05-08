import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinancialSettingsScreen extends StatefulWidget {
  const FinancialSettingsScreen({super.key});

  @override
  State<FinancialSettingsScreen> createState() => _FinancialSettingsScreenState();
}

class _FinancialSettingsScreenState extends State<FinancialSettingsScreen> {
  final _ciroHedefiController = TextEditingController();
  final _aylikGelirController = TextEditingController();
  final _sgkPrimiController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ciroHedefiController.text = (prefs.getDouble('ciroHedefi') ?? 1000000).toString();
      _aylikGelirController.text = (prefs.getDouble('aylikGelir') ?? 50000).toString();
      _sgkPrimiController.text = (prefs.getDouble('sgkPrimi') ?? 15000).toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Değişiklikleri Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Finansal ayarları kaydetmek istediğinize emin misiniz? Bu işlem dashboard ve raporlamaları etkileyecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Kaydet', style: TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    
    final ciro = double.tryParse(_ciroHedefiController.text) ?? 1000000;
    final gelir = double.tryParse(_aylikGelirController.text) ?? 50000;
    final sgk = double.tryParse(_sgkPrimiController.text) ?? 15000;

    await prefs.setDouble('ciroHedefi', ciro);
    await prefs.setDouble('aylikGelir', gelir);
    await prefs.setDouble('sgkPrimi', sgk);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Finansal ayarlar başarıyla kaydedildi!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ciroHedefiController.dispose();
    _aylikGelirController.dispose();
    _sgkPrimiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finansal Ayarlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Raporlamalar ve Kurumsal Nakit Akışı hedefleriniz için işletmenizin temel finansal verilerini girin.', 
                  style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
                const SizedBox(height: 24),

                _buildTextField('Yıllık Ciro Hedefi (₺)', _ciroHedefiController, isDark),
                const SizedBox(height: 16),
                _buildTextField('Aylık Sabit Gelir (₺)', _aylikGelirController, isDark),
                const SizedBox(height: 16),
                _buildTextField('Aylık Sabit SGK vb. Prim Gideri (₺)', _sgkPrimiController, isDark),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Kaydet ve Uygula', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
