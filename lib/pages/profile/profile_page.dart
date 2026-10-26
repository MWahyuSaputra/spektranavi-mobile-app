import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../services/firebase_service.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/profile_action_tile.dart';
import '../../widgets/profile_athlete_tile.dart';
import '../../widgets/profile_info_row.dart';
import '../auth/login_page.dart';
import '../settings/settings_page.dart';
import 'athlete_management_page.dart';
import 'device_integration_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    AthleteStore.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    AthleteStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    AthleteStore.instance.reset();
    SessionStore.instance.reset();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final athletes = AthleteStore.instance.athletes;
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName ?? "Pelatih";
    final email = user?.email ?? "-";

    return PageShell(
      title: "Profile",
      child: Column(
        children: [
          const SizedBox(height: 6),

          CircleAvatar(
            radius: 58,
            backgroundColor: Colors.white,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pelatih Goalball",
            style: TextStyle(
              color: Color(0xFFEAEAF2),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white54, width: 1),
            ),
            child: const Text(
              "Coach",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppStyles.cardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INFORMASI AKUN", style: AppStyles.sectionLabelDark),
                const SizedBox(height: 14),

                ProfileInfoRow(
                  icon: Icons.person_outline,
                  label: "Nama",
                  value: displayName,
                ),
                ProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: email,
                ),
                const ProfileInfoRow(
                  icon: Icons.groups_2_outlined,
                  label: "Role",
                  value: "Coach / Admin",
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppStyles.cardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DAFTAR ATLET", style: AppStyles.sectionLabelDark),
                const SizedBox(height: 14),

                if (athletes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Belum ada atlet terdaftar.",
                      style: AppStyles.cardSubtitle,
                    ),
                  )
                else
                  ...athletes.map(
                    (a) => ProfileAthleteTile(
                      initial: a.initial,
                      name: a.name,
                      id: a.id,
                    ),
                  ),

                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AthleteManagementPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                    label: const Text(
                      "Kelola Atlet",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          ProfileActionTile(
            icon: Icons.cable_outlined,
            title: "Integrasi Perangkat",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceIntegrationPage()),
              );
            },
          ),
          ProfileActionTile(
            icon: Icons.settings_outlined,
            title: "Pengaturan",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          const ProfileActionTile(
            icon: Icons.help_outline,
            title: "Bantuan",
          ),
          ProfileActionTile(
            icon: Icons.logout,
            title: "Keluar",
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}