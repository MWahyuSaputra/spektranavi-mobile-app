import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spektranavi/app/app_theme.dart';
import 'firebase_options.dart';
import 'pages/auth/login_page.dart';
import 'pages/main/main_navigation_page.dart';
import 'pages/esp32_diagnostic_page.dart';
import 'app/app_config.dart';
import 'app/broker_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Host/port broker MQTT dibaca dari pengaturan yang diisi pengguna di
  // Profile > Integrasi Perangkat (bukan lagi dari --dart-define).
  try {
    await BrokerSettings.instance.load();
  } catch (e) {
    debugPrint('[Config] Gagal memuat pengaturan broker: $e');
  }

  runApp(const SpektraNaviApp());
}

class SpektraNaviApp extends StatelessWidget {
  const SpektraNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spektra Navi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AppConfig.esp32Diagnostic
          ? const Esp32DiagnosticPage()
          : const AuthGate(),
    );
  }
}

/// Menentukan halaman awal berdasarkan status login.
/// Kalau pengguna sudah pernah login sebelumnya (sesi masih aktif),
/// langsung diarahkan ke halaman utama tanpa perlu login ulang.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainNavigationPage();
        }
        return const LoginPage();
      },
    );
  }
}
