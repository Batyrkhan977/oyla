import 'package:flutter/services.dart';

class ReminderService {
  static const _channel = MethodChannel('oyla/reminders');

  Future<bool?> exactAlarmsEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('exactAlarmsEnabled');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> openExactAlarmSettings() =>
      _channel.invokeMethod<void>('openExactAlarmSettings');

  Future<bool?> notificationsEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsEnabled');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> openNotificationSettings() async {
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<void> scheduleActivities(List<Map<String, dynamic>> items) async {
    try {
      await _channel.invokeMethod<void>('scheduleActivities', {'items': items});
    } on MissingPluginException {
      /* Platform unavailable. */
    } on PlatformException {
      /* Permission status is handled by settings. */
    }
  }

  Future<void> cancelActivities() => scheduleActivities([]);
  Future<List<Map<String, dynamic>>> pendingActions() async {
    try {
      final rows =
          await _channel.invokeListMethod<dynamic>('pendingActions') ?? [];
      return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } on MissingPluginException {
      return [];
    } on PlatformException {
      return [];
    }
  }

  Future<void> acknowledge(String id) async {
    try {
      await _channel.invokeMethod<void>('acknowledge', {'id': id});
    } on MissingPluginException {
      /* Platform unavailable. */
    }
  }

  Future<bool> apply({
    required bool enabled,
    required int hour,
    List<int?>? weekdayHours,
    int quietStartHour = 21,
    int quietEndHour = 8,
    String languageCode = 'en',
  }) async {
    try {
      if (enabled) {
        await _channel.invokeMethod<void>('schedule', {
          'hour': hour,
          'weekdayHours': weekdayHours ?? List<int?>.filled(7, hour),
          'quietStartHour': quietStartHour,
          'quietEndHour': quietEndHour,
          'languageCode': languageCode,
        });
      } else {
        await _channel.invokeMethod<void>('cancel');
      }
      return true;
    } on MissingPluginException {
      // Tests and unsupported platforms do not provide a reminder channel.
      return false;
    } on PlatformException {
      // A denied notification permission or native scheduling failure must not
      // leave the setting claiming that reminders are active.
      return false;
    }
  }

  Future<void> skipToday(
    int hour, {
    List<int?>? weekdayHours,
    int quietStartHour = 21,
    int quietEndHour = 8,
    String languageCode = 'en',
  }) async {
    try {
      await _channel.invokeMethod<void>('skipToday', {
        'hour': hour,
        'weekdayHours': weekdayHours ?? List<int?>.filled(7, hour),
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
        'languageCode': languageCode,
      });
    } on MissingPluginException {
      // Tests and unsupported platforms do not provide the Android channel.
    }
  }
}
