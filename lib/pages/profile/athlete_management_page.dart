import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';
import '../../app/athlete_store.dart';

class AthleteManagementPage extends StatefulWidget {
  const AthleteManagementPage({super.key});

  @override
  State<AthleteManagementPage> createState() => _AthleteManagementPageState();
}

class _AthleteManagementPageState extends State<AthleteManagementPage> {
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

  void _openAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Tambah Atlet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Nama lengkap atlet",
              filled: true,
              fillColor: const Color(0xFFF2F2F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                AthleteStore.instance.addAthlete(controller.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text("Tambah"),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemove(Athlete athlete) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Hapus Atlet?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            "${athlete.name} akan dihapus dari daftar atlet. Riwayat sesi latihan sebelumnya tidak akan terhapus.",
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                AthleteStore.instance.removeAthlete(athlete.id);
                Navigator.pop(ctx);
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final athletes = AthleteStore.instance.athletes;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
                    "Kelola Atlet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: athletes.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada atlet.\nTap tombol + untuk menambah.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: athletes.length,
                        itemBuilder: (context, index) {
                          final a = athletes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppStyles.cardRadius,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    a.initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name, style: AppStyles.cardTitle),
                                      const SizedBox(height: 2),
                                      Text(a.id, style: AppStyles.cardSubtitle),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _confirmRemove(a),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Tambah Atlet",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.buttonRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}