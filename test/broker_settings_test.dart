import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spektranavi/app/broker_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrokerSettings.instance.reset();
  });

  test('parseHost menerima host, skema, dan host:port', () {
    final plain = BrokerSettings.parseHost('192.168.1.17');
    expect(plain.host, '192.168.1.17');
    expect(plain.port, BrokerSettings.defaultPort);

    final withScheme = BrokerSettings.parseHost('mqtt://broker.local:1884');
    expect(withScheme.host, 'broker.local');
    expect(withScheme.port, 1884);

    final withPath = BrokerSettings.parseHost('tcp://192.168.1.17:1883/');
    expect(withPath.host, '192.168.1.17');
    expect(withPath.port, 1883);
  });

  test('save menyimpan host/port yang sudah dirapikan', () async {
    await BrokerSettings.instance.save(host: ' 10.0.2.2 ', port: 1884);

    expect(BrokerSettings.instance.config.value.host, '10.0.2.2');
    expect(BrokerSettings.instance.config.value.port, 1884);

    await BrokerSettings.instance.reset();
    expect(BrokerSettings.instance.config.value.isConfigured, isFalse);
  });

  test('port tidak valid ditolak', () async {
    expect(BrokerSettings.isValidPort(0), isFalse);
    expect(BrokerSettings.isValidPort(65536), isFalse);
    expect(BrokerSettings.isValidPort(1883), isTrue);

    await expectLater(
      BrokerSettings.instance.save(host: 'broker.local', port: 0),
      throwsArgumentError,
    );
  });
}
