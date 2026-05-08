import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bildirim Servisi
/// Son ödeme tarihi yaklaşan belgeler için push notification gönderir
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: darwinInit);

    await _notifications.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Belgeleri kontrol et, son ödeme tarihi 3 gün içinde olanlar için bildirim gönder
  static Future<void> checkAndNotifyDueDocs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));

      final response = await Supabase.instance.client
          .from('documents')
          .select('id, name, amount, payment_status, created_at, belge_tipi')
          .eq('user_id', userId)
          .eq('payment_status', 'bekliyor');

      int notifId = 100;
      for (var doc in response) {
        final tipi = (doc['belge_tipi'] as String? ?? 'gider').toLowerCase();
        if (tipi == 'gelir') continue;

        final createdAt = doc['created_at'] as String?;
        if (createdAt == null) continue;

        try {
          final dt = DateTime.parse(createdAt).toLocal();
          // 30 gün sonrasını "son ödeme tarihi" olarak kabul et
          final dueDate = dt.add(const Duration(days: 30));

          if (dueDate.isBefore(threeDaysLater) && dueDate.isAfter(now)) {
            final daysLeft = dueDate.difference(now).inDays;
            final amount = (doc['amount'] as num?)?.toDouble() ?? 0;
            final name = doc['name']?.toString() ?? 'Bilinmeyen Belge';

            await _sendNotification(
              id: notifId++,
              title: '⚠️ Ödeme Yaklaşıyor: $name',
              body: '$daysLeft gün içinde ödenmesi gereken ₺${amount.toStringAsFixed(0)} tutarında bekleyen fatura var.',
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      // Sessizce fail et
    }
  }

  static Future<void> _sendNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'billmind_due_channel',
      'Son Ödeme Tarihi Bildirimleri',
      channelDescription: 'Son ödeme tarihi yaklaşan faturalar için bildirimler',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: darwinDetails);
    await _notifications.show(id, title, body, details);
  }

  /// Test bildirimi gönder
  static Future<void> sendTestNotification() async {
    await _sendNotification(
      id: 1,
      title: '🔔 BillMind Bildirimleri Aktif!',
      body: 'Son ödeme tarihi yaklaşan faturalarınız için bildirim alacaksınız.',
    );
  }
}
