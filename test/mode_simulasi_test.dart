import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spektranavi/app/app_colors.dart';
import 'package:spektranavi/app/athlete_store.dart';
import 'package:spektranavi/pages/training/mode_simulasi_page.dart';
import 'package:spektranavi/services/device_services.dart';
import 'package:spektranavi/services/esp32_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  });

  tearDown(() {
    DeviceServices.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('Tombol arah bola hanya biru sesaat lalu kembali', (tester) async {
    DeviceServices.instance.esp32.data.value = const Esp32TelemetryData();

    await tester.pumpWidget(MaterialApp(
      home: ModeSimulasiPage(athlete: Athlete(id: 'Atlet-01', name: 'Andi')),
    ));
    await tester.pump();

    Color? colorOf(String label) {
      final container = tester.widget<Container>(
        find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
      );
      return (container.decoration as BoxDecoration?)?.color;
    }

    // Tidak ada arah yang tersorot sebelum ditekan.
    expect(colorOf('KIRI'), isNot(AppColors.primary));
    expect(colorOf('KANAN'), isNot(AppColors.primary));

    await tester.tap(find.text('KIRI'));
    await tester.pump();
    expect(colorOf('KIRI'), AppColors.primary);

    // Setelah suara selesai (atau batas aman), warna kembali normal.
    await tester.pump(const Duration(milliseconds: 700));
    expect(colorOf('KIRI'), isNot(AppColors.primary));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
