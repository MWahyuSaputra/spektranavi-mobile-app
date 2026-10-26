import 'package:flutter/material.dart';
import '../../app/app_colors.dart';
import '../../app/app_styles.dart';

class DocumentDetailPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String tag;

  const DocumentDetailPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
  });

  bool get _isVideo => tag == "Video Tutorial";

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
                ],
              ),
              const SizedBox(height: 4),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.bigRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview area — placeholder sebelum file/video asli tersambung
                    // lewat backend (Firebase Storage atau tautan eksternal).
                    Container(
                      width: double.infinity,
                      height: _isVideo ? 190 : 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isVideo ? Icons.play_circle_fill : icon,
                              size: 52,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isVideo ? "Pratinjau video belum tersedia" : "Pratinjau dokumen belum tersedia",
                              style: AppStyles.cardSubtitle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF70707A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSoft,
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isVideo
                                    ? "Pemutaran video akan tersambung saat backend siap"
                                    : "Unduh dokumen akan tersambung saat backend siap",
                              ),
                            ),
                          );
                        },
                        icon: Icon(_isVideo ? Icons.play_arrow_rounded : Icons.download_outlined),
                        label: Text(_isVideo ? "Putar Video" : "Unduh Dokumen"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}