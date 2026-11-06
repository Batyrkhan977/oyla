import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('oyla/reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('enabled reminders schedule at the selected hour', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    final applied = await ReminderService().apply(enabled: true, hour: 14);

    expect(applied, isTrue);
    expect(received?.method, 'schedule');
    expect(received?.arguments, {
      'hour': 14,
      'weekdayHours': [14, 14, 14, 14, 14, 14, 14],
      'quietStartHour': 21,
      'quietEndHour': 8,
      'languageCode': 'en',
    });
  });

  test('disabled reminders cancel native notifications', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    final applied = await ReminderService().apply(enabled: false, hour: 9);

    expect(applied, isTrue);
    expect(received?.method, 'cancel');
  });

  test('skip today preserves the selected reminder hour', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return null;
    });

    await ReminderService().skipToday(8);

    expect(received?.method, 'skipToday');
    expect(received?.arguments, {
      'hour': 8,
      'weekdayHours': [8, 8, 8, 8, 8, 8, 8],
      'quietStartHour': 21,
      'quietEndHour': 8,
      'languageCode': 'en',
    });
  });

  test('permission denial reports that reminders were not applied', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'notification_denied');
    });

    expect(await ReminderService().apply(enabled: true, hour: 9), isFalse);
  });

  test(
    'an unsupported platform reports that reminders were not applied',
    () async {
      expect(await ReminderService().apply(enabled: true, hour: 9), isFalse);
    },
  );
}
