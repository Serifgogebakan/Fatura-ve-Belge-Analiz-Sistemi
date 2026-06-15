import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Değişiklikleri Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Hesap bilgilerinizi güncellemek istediğinize emin misiniz?'),
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
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
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

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yeni şifrenizi giriniz:'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Güncelle', style: TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && passwordController.text.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: passwordController.text)
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Şifreniz başarıyla güncellendi.'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Şifre güncellenirken bir hata oluştu.'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
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
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                  ),
                  title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Hesabınızın şifresini hemen güncelleyin.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: _changePassword,
                ),
                Divider(height: 1, indent: 56, color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.mark_email_read_outlined, color: primaryColor, size: 20),
                  ),
                  title: const Text('Şifre Sıfırlama Bağlantısı', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Sistemde kayıtlı e-posta adresinize bağlantı yollar.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () => _resetPassword(context),
                ),
              ],
            ),
          ),
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

// ==========================================
// TEMA AYARLARI EKRANI
// ==========================================
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  Future<void> _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme_mode') ?? 'system';
    });
  }

  Future<void> _changeTheme(String theme) async {
    setState(() {
      _selectedTheme = theme;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme);

    if (theme == 'light') {
      MyApp.themeNotifier.value = ThemeMode.light;
    } else if (theme == 'dark') {
      MyApp.themeNotifier.value = ThemeMode.dark;
    } else {
      MyApp.themeNotifier.value = ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            child: Column(
              children: [
                _buildThemeOption(
                  'Cihaz Teması',
                  'Sistem ayarlarına göre otomatik değişir.',
                  'system',
                  Icons.settings_brightness_outlined,
                  primaryColor,
                  textColor,
                ),
                Divider(height: 1, indent: 56, color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                _buildThemeOption(
                  'Açık Tema',
                  'Aydınlık görünüm.',
                  'light',
                  Icons.light_mode_outlined,
                  primaryColor,
                  textColor,
                ),
                Divider(height: 1, indent: 56, color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                _buildThemeOption(
                  'Koyu Tema',
                  'Göz yormayan karanlık görünüm.',
                  'dark',
                  Icons.dark_mode_outlined,
                  primaryColor,
                  textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    String value,
    IconData icon,
    Color primaryColor,
    Color textColor,
  ) {
    final isSelected = _selectedTheme == value;
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ),
      value: value,
      groupValue: _selectedTheme,
      onChanged: (val) {
        if (val != null) _changeTheme(val);
      },
      activeColor: primaryColor,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
