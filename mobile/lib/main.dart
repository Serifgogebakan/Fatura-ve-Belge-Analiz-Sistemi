import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Bildirim servisini başlat
  await NotificationService.init();
  await NotificationService.requestPermission();

  // Tema tercihini yükle
  final prefs = await SharedPreferences.getInstance();
  final themeStr = prefs.getString('theme_mode') ?? 'system';
  ThemeMode mode = ThemeMode.system;
  if (themeStr == 'light') mode = ThemeMode.light;
  if (themeStr == 'dark') mode = ThemeMode.dark;
  MyApp.themeNotifier.value = mode;

  runApp(const MyApp());
}


final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'BillMind',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            primaryColor: const Color(0xFF1D4ED8),
            cardColor: Colors.white,
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D4ED8),
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B1121),
            primaryColor: const Color(0xFF3B82F6),
            cardColor: const Color(0xFF151C2C),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF151C2C),
              onSurface: Color(0xFFF1F5F9),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
