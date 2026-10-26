import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spektranavi/app/app_config.dart';
import 'package:spektranavi/app/athlete_store.dart';
import 'package:spektranavi/app/field_position.dart';
import 'package:spektranavi/pages/training/mode_lari_page.dart';
import 'package:spektranavi/services/device_services.dart';
import 'package:spektranavi/services/esp32_service.dart';
import 'package:spektranavi/widgets/field_map_card.dart';
import 'package:spektranavi/widgets/telemetry_metric_cards.dart';
import 'package:spektranavi/widgets/training_metric_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const origin = FieldProjection(AppConfig.sampleLatitude, AppConfig.sampleLongitude);
  const validData = Esp32TelemetryData(
    connected: true,
    gpsValid: true,
    latitude: AppConfig.sampleLatitude,
    longitude: AppConfig.sampleLongitude,
    satellites: 7,
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
    DeviceServices.instance.esp32.data.value = const Esp32TelemetryData();
  });

  tearDown(() {
    DeviceServices.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  test('Projection keeps a fixed origin and preserves out-of-field positions', () {
    final center = origin.project(origin.latitude, origin.longitude)!;
    expect(center.x, closeTo(0.5, 1e-8));
    expect(center.y, closeTo(0.5, 1e-8));
    final northEast = origin.project(origin.latitude + 0.00001, origin.longitude + 0.00001)!;
    expect(northEast.x, greaterThan(center.x));
    expect(northEast.y, lessThan(center.y));
    expect(northEast.isInside, isTrue);
    expect(origin.project(origin.latitude + 0.01, origin.longitude)!.isInside, isFalse);
    expect(origin.project(double.nan, origin.longitude), isNull);
    expect(origin.project(91, origin.longitude), isNull);
  });

  testWidgets('Target toggles map below GNSS; marker tracks valid telemetry only', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: ModeLariPage(athlete: Athlete(id: 'Atlet-01', name: 'Andi')),
    ));
    final toggle = find.byKey(const ValueKey('gnss-map-toggle'));
    final map = find.byType(FieldMapCard);
    final marker = find.byKey(const ValueKey('athlete-map-marker'));
    expect(map, findsNothing);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    expect(map, findsOneWidget);
    expect(marker, findsNothing);
    expect(tester.getTopLeft(map).dy,
        greaterThan(tester.getBottomLeft(find.text('GNSS / NAVIGASI LINTASAN')).dy));

    DeviceServices.instance.esp32.data.value = validData;
    await tester.pump();
    expect(marker, findsOneWidget);
    final initial = tester.widget<FieldMapCard>(map).position!;
    DeviceServices.instance.esp32.data.value = validData.copyWith(
      latitude: validData.latitude + 0.00001,
      longitude: validData.longitude + 0.00001,
    );
    await tester.pump();
    final moved = tester.widget<FieldMapCard>(map).position!;
    expect(moved.x, greaterThan(initial.x));
    expect(moved.y, lessThan(initial.y));

    DeviceServices.instance.esp32.data.value = validData.copyWith(gpsValid: false);
    await tester.pump();
    expect(marker, findsNothing);
    DeviceServices.instance.esp32.data.value = validData.copyWith(connected: false);
    await tester.pump();
    expect(marker, findsNothing);
    DeviceServices.instance.esp32.data.value = validData.copyWith(latitude: double.nan);
    await tester.pump();
    expect(marker, findsNothing);
    DeviceServices.instance.esp32.data.value = validData.copyWith(latitude: origin.latitude + 0.01);
    await tester.pump();
    expect(marker, findsNothing);
    expect(find.text('Posisi atlet di luar area lapangan'), findsOneWidget);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    expect(map, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Raw ECG never becomes an invented BPM value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: HeartRateTelemetryCard(data: Esp32TelemetryData(connected: true, ecgRaw: 2100)),
    )));
    final card = tester.widget<TrainingMetricCard>(find.byType(TrainingMetricCard));
    expect(card.value, '--');
  });
}
