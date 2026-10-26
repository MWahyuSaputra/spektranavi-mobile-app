import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';
import '../../app/session_store.dart';
import '../../services/firebase_service.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifSesiSelesai = true;
  bool _notifBaterai = true;
  String _satuan = "Meter";

  Future<void> _logout() async {
    await AuthService.instance.logout();
    // Bersihkan data akun sebelumnya dari memori supaya tidak bocor
    // ke sesi login berikutnya.
    AthleteStore.instance.reset();
    SessionStore.instance.reset();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openEditProfilDialog() {
    final user = AuthService.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Profil", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        filled: true,
                        fillColor: const Color(0xFFF2F2F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Email: ${user?.email ?? '-'}",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Ubah email belum didukung pada versi ini.",
                      style: TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Batal", style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await AuthService.instance
                                .updateDisplayName(nameController.text.trim());
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            setState(() {}); // refresh nama di halaman ini kalau ditampilkan
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profil berhasil diperbarui"),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthService.instance.readableError(e)),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Ubah Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Password Saat Ini",
                        filled: true,
                        fillColor: const Color(0xFFF2F2F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        filled: true,
                        fillColor: const Color(0xFFF2F2F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password Baru",
                        filled: true,
                        fillColor: const Color(0xFFF2F2F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v != newController.text) return 'Password tidak sama';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text("Batal", style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await AuthService.instance.changePassword(
                              currentPassword: currentController.text,
                              newPassword: newController.text,
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password berhasil diubah"),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthService.instance.readableError(e)),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Pengaturan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _sectionCard(
                title: "AKUN",
                children: [
                  _actionRow(
                    icon: Icons.edit_outlined,
                    label: "Edit Profil",
                    onTap: _openEditProfilDialog,
                  ),
                  _actionRow(
                    icon: Icons.lock_outline,
                    label: "Ubah Password",
                    onTap: _openChangePasswordDialog,
                    showDivider: false,
                  ),
                ],
              ),

              _sectionCard(
                title: "NOTIFIKASI",
                children: [
                  _switchRow(
                    label: "Sesi latihan selesai",
                    value: _notifSesiSelesai,
                    onChanged: (v) => setState(() => _notifSesiSelesai = v),
                  ),
                  _switchRow(
                    label: "Peringatan baterai perangkat",
                    value: _notifBaterai,
                    onChanged: (v) => setState(() => _notifBaterai = v),
                    showDivider: false,
                  ),
                ],
              ),

              _sectionCard(
                title: "SATUAN",
                children: [
                  _dropdownRow(
                    label: "Satuan Jarak",
                    value: _satuan,
                    options: const ["Meter", "Feet"],
                    onChanged: (v) => setState(() => _satuan = v ?? _satuan),
                    showDivider: false,
                  ),
                ],
              ),

              _sectionCard(
                title: "LAINNYA",
                children: [
                  _actionRow(
                    icon: Icons.info_outline,
                    label: "Tentang Aplikasi",
                    trailing: const Text("v1.0.0", style: AppStyles.cardSubtitle),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "Spektra Navi",
                        applicationVersion: "1.0.0",
                        applicationLegalese: "Goalball Coach App",
                      );
                    },
                  ),
                  _actionRow(
                    icon: Icons.description_outlined,
                    label: "Kebijakan Privasi",
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.red),
                  label: const Text(
                    "Keluar",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.sectionLabelDark),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black54),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: AppStyles.cardTitle)),
                if (trailing != null) trailing,
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
              ],
            ),
            if (showDivider) const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Divider(height: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppStyles.cardTitle)),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.green,
              ),
            ],
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppStyles.cardTitle)),
              DropdownButton<String>(
                value: value,
                underline: const SizedBox(),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: onChanged,
              ),
            ],
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}