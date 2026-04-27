import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// HESAP AYARLARI EKRANI
// ==========================================
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _supabase = Supabase.instance.client;
  
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select('full_name, company_name, tax_id, address')
          .eq('id', user.id)
          .maybeSingle();
      
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['full_name'] ?? user.userMetadata?['full_name'] ?? '';
          _companyController.text = data['company_name'] ?? '';
          _taxIdController.text = data['tax_id'] ?? '';
          _addressController.text = data['address'] ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': _nameController.text.trim(),
          'company_name': _companyController.text.trim(),
          'tax_id': _taxIdController.text.trim(),
          'address': _addressController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil başarıyla güncellendi'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Ayarları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField('Ad Soyad', _nameController, Icons.person_outline, isDark, cardColor),
                  const SizedBox(height: 16),
                  _buildTextField('Şirket Adı', _companyController, Icons.business_outlined, isDark, cardColor),
                  const SizedBox(height: 16),
                  _buildTextField('Vergi / TC Kimlik No', _taxIdController, Icons.numbers, isDark, cardColor),
                  const SizedBox(height: 16),
                  _buildTextField('Adres', _addressController, Icons.location_on_outlined, isDark, cardColor, maxLines: 3),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, Color cardColor, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade500) : null,
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
      ),
    );
  }
}

// ==========================================
// BİLDİRİMLER EKRANI
// ==========================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _weeklyReportEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildToggle(
            'Anlık Bildirimler',
            'Yeni bir belge yüklendiğinde vb. telefonunuza gelen push bildirimler',
            _pushEnabled,
            (val) => setState(() => _pushEnabled = val),
            isDark, cardColor, primaryColor,
          ),
          const SizedBox(height: 16),
          _buildToggle(
            'E-Posta Bildirimleri',
            'Analiz edilen faturalarınız ve özet raporlarınızın e-posta adresinize gönderimi',
            _emailEnabled,
            (val) => setState(() => _emailEnabled = val),
            isDark, cardColor, primaryColor,
          ),
          const SizedBox(height: 16),
          _buildToggle(
            'Haftalık Özet Rapor',
            'Her pazar akşamı haftalık harcama ve belge özet raporu',
            _weeklyReportEnabled,
            (val) => setState(() => _weeklyReportEnabled = val),
            isDark, cardColor, primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged, bool isDark, Color cardColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

// ==========================================
// GÜVENLİK EKRANI
// ==========================================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  Future<void> _resetPassword(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      await supabase.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'),
            backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Güvenlik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.password_rounded, color: primaryColor, size: 20),
              ),
              title: const Text('Şifre Sıfırla', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Sistemde kayıtlı e-posta adresinize bağlantı yollar.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () => _resetPassword(context),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
            ),
            child: SwitchListTile(
              title: const Text('Biyometrik Giriş', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Face ID / Touch ID ile giriş yapın', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              value: true,
              onChanged: (val) {},
              activeColor: primaryColor,
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.fingerprint, color: primaryColor, size: 20),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// DESTEK EKRANI
// ==========================================
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _sendSupportMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mesajınız destek ekibimize ulaştı. Teşekkürler!'),
        backgroundColor: Colors.green.shade600,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destek Talebi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nasıl yardımcı olabiliriz?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Sorun, öneri veya taleplerinizi bize güvenle iletebilirsiniz.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Konu Başlığı',
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Mesajınız',
                alignLabelWithHint: true,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _sendSupportMessage(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Gönder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
