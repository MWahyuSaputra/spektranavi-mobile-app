import '../../services/device_services.dart';
import 'package:flutter/material.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../analytics/analytics_page.dart';
import '../catalog/catalog_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../training/training_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Muat data atlet & histori sesi dari Firestore begitu pengguna
    // berhasil login dan masuk ke halaman utama.
    AthleteStore.instance.load();
    SessionStore.instance.load();
    DeviceServices.instance.start();
  }

  @override
  void dispose() {
    DeviceServices.instance.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onStartTraining: () => _goToTab(1)),
      const TrainingPage(),
      const CatalogPage(),
      const AnalyticsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}