import 'package:flutter_test/flutter_test.dart';
import 'package:spektranavi/app/app_config.dart';
import 'package:spektranavi/app/athlete_store.dart';
import 'package:spektranavi/app/field_position.dart';
import 'package:spektranavi/app/session_metrics.dart';
import 'package:spektranavi/app/session_store.dart';
import 'package:spektranavi/services/esp32_service.dart';
import 'package:spektranavi/services/mqtt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Real profile starts without fabricated sensor measurements', () {
    final source = Esp32Service();
    final metrics = SessionMetrics();
    expect(source.data.value.connected, isFalse);
    expect(source.data.value.gpsValid, isFalse);
    expect(source.data.value.heartRateBpm, isNull);
    expect(source.data.value.speedMetersPerSecond, isNull);
    metrics.record(const Esp32TelemetryData(connected: true, heartRateBpm: 110, reactionMs: 600));
    expect(metrics.averageHeart, 0);
    expect(metrics.bestReactionMs, isNull);
    source.dispose();
  }, skip: AppConfig.esp32Mock);

  testWidgets('Active source moves within the field and stops on disconnect', (tester) async {
    final source = Esp32Service();
    final vision = MqttService();
    await source.connect();
    await vision.connect();
    final initial = source.data.value;
    expect(initial.connected, isTrue);
    expect(initial.heartRateBpm, isNotNull);
    expect(vision.data.value.piOnline, isTrue);
    const projection = FieldProjection(AppConfig.sampleLatitude, AppConfig.sampleLongitude);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final data = source.data.value;
      expect(projection.project(data.latitude, data.longitude)!.isInside, isTrue);
    }
    expect(source.data.value.longitude, isNot(initial.longitude));
    source.disconnect();
    vision.disconnect();
    await tester.pump(const Duration(seconds: 2));
    expect(source.data.value.connected, isFalse);
    expect(source.data.value.gpsValid, isFalse);
    expect(vision.data.value.piOnline, isFalse);
    source.dispose();
    vision.dispose();
  }, skip: !AppConfig.esp32Mock || !AppConfig.visionMock);

  test('Active profile keeps athletes and sessions local without Firebase', () async {
    final athletes = AthleteStore.instance;
    final sessions = SessionStore.instance;
    athletes.reset();
    sessions.reset();
    await athletes.load();
    await sessions.load();
    expect(athletes.athletes.length, 3);
    expect(sessions.sessions.length, 3);
    await athletes.addAthlete('Andi');
    expect(athletes.athletes.last.name, 'Andi');
    await sessions.addSession(sessions.sessions.first);
    expect(sessions.sessions.length, 4);
    athletes.reset();
    sessions.reset();
  }, skip: !AppConfig.useSampleData);
}
