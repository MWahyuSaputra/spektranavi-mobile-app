import 'package:flutter/material.dart';
import '../../app/app_styles.dart';
import '../../widgets/catalog_doc_card.dart';
import '../../widgets/page_shell.dart';
import 'document_detail_page.dart';

class _CatalogDoc {
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final bool external;

  const _CatalogDoc({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    this.external = false,
  });
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  int _selectedFilter = 0;

  static const _filters = ["Semua", "Buku Manual", "Keselamatan"];

  static const _allDocs = [
    _CatalogDoc(
      icon: Icons.menu_book_outlined,
      title: "Buku Manual SPEKTRA-NAVI",
      description: "Panduan lengkap penggunaan sistem, setup perangkat, dan konfigurasi awal.",
      tag: "Buku Manual",
      external: true,
    ),
    _CatalogDoc(
      icon: Icons.shield_outlined,
      title: "Panduan Keselamatan Atlet",
      description: "Prosedur keamanan, batas BPM, dan protokol emergency stop.",
      tag: "Keselamatan",
    ),
    _CatalogDoc(
      icon: Icons.description_outlined,
      title: "Dokumen Kalibrasi Sensor",
      description: "Langkah-langkah kalibrasi IMU, kamera edge AI, dan Heart Rate Sensor.",
      tag: "Buku Manual",
    ),
    _CatalogDoc(
      icon: Icons.shield_outlined,
      title: "Panduan Troubleshooting Koneksi",
      description: "Solusi masalah BLE pairing, ESP-NOW disconnect, dan latency tinggi.",
      tag: "Keselamatan",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CatalogDoc> get _filteredDocs {
    final query = _query.trim().toLowerCase();
    final selectedTag = _filters[_selectedFilter];

    return _allDocs.where((doc) {
      final matchesTag = selectedTag == "Semua" || doc.tag == selectedTag;
      final matchesQuery = query.isEmpty || doc.title.toLowerCase().contains(query);
      return matchesTag && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredDocs;

    return PageShell(
      title: "",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Katalog & Dokumentasi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pusat edukasi, manual, dan panduan keselamatan sistem SPEKTRA-NAVI.",
            style: TextStyle(
              color: Color(0xFFE7E7EF),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppStyles.cardRadius,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Cari dokumen atau tutorial",
                hintStyle: const TextStyle(
                  color: Color(0xFF9A9AA3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9A9AA3)),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF9A9AA3)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = "");
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_filters.length, (index) {
                final selected = index == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: Padding(
                    padding: EdgeInsets.only(right: index == _filters.length - 1 ? 0 : 8),
                    child: _FilterChip(label: _filters[index], selected: selected),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? "Tidak ada dokumen di kategori ini."
                      : "Tidak ditemukan dokumen untuk \"$_query\".",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            )
          else
            ...docs.map(
              (doc) => CatalogDocCard(
                icon: doc.icon,
                title: doc.title,
                description: doc.description,
                tag: doc.tag,
                external: doc.external,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentDetailPage(
                        icon: doc.icon,
                        title: doc.title,
                        description: doc.description,
                        tag: doc.tag,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF355D6E) : const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.white70 : Colors.transparent,
          width: selected ? 0.7 : 0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF8A8A96),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}