import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _firmaCtrl = TextEditingController();
  final _tutarCtrl = TextEditingController();
  final _kdvCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  String _belgeTipi = 'gider';
  String _kategori = 'Fatura';
  String _odemeStatus = 'bekliyor';
  DateTime _tarih = DateTime.now();
  bool _isSaving = false;

  static const _kategoriler = ['Fatura', 'Fiş', 'Sözleşme', 'Sağlık', 'Finans', 'Lojistik', 'Personel', 'Vergi', 'Diğer'];
  static const _odemeStatusleri = ['bekliyor', 'ödendi', 'gecikti', 'incelemede'];

  @override
  void dispose() {
    _firmaCtrl.dispose();
    _tutarCtrl.dispose();
    _kdvCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Oturum bulunamadı');

      final tutar = double.tryParse(
        _tutarCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim(),
      ) ?? 0.0;
      
      final kdv = double.tryParse(
        _kdvCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim(),
      ) ?? 0.0;

      // Sadece şemada var olan geçerli sütunları ekliyoruz
      final docResponse = await _supabase.from('documents').insert({
        'user_id': userId,
        'name': _firmaCtrl.text.trim(),
        'amount': tutar,
        'category': _kategori,
        'belge_tipi': _belgeTipi,
        'payment_status': _odemeStatus,
        'status': 'beklemede',
        'file_type': 'Manuel Giriş',
        'created_at': _tarih.toUtc().toIso8601String(),
      }).select().single();

      final documentId = docResponse['id'];

      // Açıklama veya KDV girildiyse ek verileri extracted_data tablosuna yazıyoruz
      if (_aciklamaCtrl.text.trim().isNotEmpty || kdv > 0) {
        final rawText = _aciklamaCtrl.text.trim().isNotEmpty 
            ? _aciklamaCtrl.text.trim() 
            : 'Manuel olarak girildi. KDV: ₺$kdv';

        await _supabase.from('extracted_data').insert({
          'document_id': documentId,
          'vendor_name': _firmaCtrl.text.trim(),
          'invoice_date': _tarih.toUtc().toIso8601String().substring(0, 10),
          'total_amount': tutar,
          'raw_text': rawText,
          'processing_model': 'manual-entry',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Kayıt başarıyla eklendi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0052FF);
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final isGelir = _belgeTipi == 'gelir';
    final accentColor = isGelir ? Colors.green.shade600 : Colors.red.shade500;

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
        title: Text(
          'Manuel Kayıt',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gelir / Gider Seçimi
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _typeTab('Gider', 'gider', Icons.trending_down_rounded, Colors.red.shade500, isDark),
                    _typeTab('Gelir', 'gelir', Icons.trending_up_rounded, Colors.green.shade600, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Büyük Tutar Alanı
              Center(
                child: Column(
                  children: [
                    Text(
                      isGelir ? 'GELİR TUTARI' : 'GİDER TUTARI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('₺', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor)),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            controller: _tutarCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accentColor),
                            decoration: const InputDecoration(
                              hintText: '0,00',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Tutar zorunlu';
                              final parsed = double.tryParse(v.replaceAll(',', '.'));
                              if (parsed == null || parsed <= 0) return 'Geçerli tutar girin';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Container(height: 2, width: 160, color: accentColor.withOpacity(0.3)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Firma Adı
              _sectionLabel('FİRMA / KAYNAK ADI'),
              const SizedBox(height: 8),
              _inputField(
                controller: _firmaCtrl,
                hint: isGelir ? 'Örn: ABC Ltd. (ödeme geldi)' : 'Örn: Vodafone, Elektrik Faturası',
                icon: Icons.business_outlined,
                isDark: isDark, cardColor: cardColor, textColor: textColor,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Firma adı zorunlu' : null,
              ),
              const SizedBox(height: 20),

              // KDV
              _sectionLabel('KDV TUTARI (₺)'),
              const SizedBox(height: 8),
              _inputField(
                controller: _kdvCtrl,
                hint: 'Örn: 18.50',
                icon: Icons.percent_outlined,
                isDark: isDark, cardColor: cardColor, textColor: textColor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),

              // Kategori
              _sectionLabel('KATEGORİ'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kategoriler.map((kat) {
                  final isSelected = _kategori == kat;
                  return GestureDetector(
                    onTap: () => setState(() => _kategori = kat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
                      ),
                      child: Text(
                        kat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Tarih
              _sectionLabel('TARİH'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _tarih,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: isDark ? ColorScheme.dark(primary: primaryColor) : ColorScheme.light(primary: primaryColor),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _tarih = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_tarih.day.toString().padLeft(2, '0')}.${_tarih.month.toString().padLeft(2, '0')}.${_tarih.year}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ödeme Durumu
              _sectionLabel('ÖDEME DURUMU'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _odemeStatus,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                    items: _odemeStatusleri.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    )).toList(),
                    onChanged: (v) => setState(() => _odemeStatus = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Açıklama (opsiyonel)
              _sectionLabel('AÇIKLAMA (OPSİYONEL)'),
              const SizedBox(height: 8),
              _inputField(
                controller: _aciklamaCtrl,
                hint: 'Ek notlarınızı buraya yazabilirsiniz...',
                icon: Icons.notes_outlined,
                isDark: isDark, cardColor: cardColor, textColor: textColor,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isGelir ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isGelir ? 'Geliri Kaydet' : 'Gideri Kaydet',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, String type, IconData icon, Color color, bool isDark) {
    final isSelected = _belgeTipi == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _belgeTipi = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade500, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
