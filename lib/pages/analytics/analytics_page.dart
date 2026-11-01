import 'package:flutter/material.dart';
import '../../app/session_store.dart';
import '../../widgets/analytics_session_card.dart';
import '../../widgets/page_shell.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    SessionStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    SessionStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  IconData _iconForMode(String mode) {
    switch (mode) {
      case "Mode Tanding":
        return Icons.shield_outlined;
      case "Mode Simulasi":
        return Icons.volume_up_outlined;
      case "Mode Lari":
      default:
        return Icons.directions_run;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = SessionStore.instance.sessions;

    return PageShell(
      title: "Analytics",
      child: sessions.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  "Belum ada sesi latihan.\nMulai sesi di halaman Training.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          : Column(
              children: sessions.map((s) {
                return AnalyticsSessionCard(
                  icon: _iconForMode(s.mode),
                  mode: s.mode,
                  athlete: s.athlete,
                  date: s.dateLabel,
                  duration: s.durationLabel,
                  leftValue: "${s.avgHeart}",
                  leftSub: "Max: ${s.peakHeart}",
                  midValue: s.midValue,
                  midSub: s.midSub,
                );
              }).toList(),
            ),
    );
  }
}