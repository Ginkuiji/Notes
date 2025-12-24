import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/note.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'notes_channel_id';
  static const String _channelName = 'Напоминания заметок';
  static const String _channelDescription =
      'Уведомления о напоминаниях из заметок';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // ---------- TIMEZONE (стабильно через UTC) ----------
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    // ---------- ANDROID CHANNEL ----------
    await _createNotificationChannel();

    // ---------- PERMISSIONS ----------
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestPermissions() async {
    // Android 13+
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  int _noteId(Note note) {
    final key = note.key;
    if (key is int) return key;
    return key.hashCode.abs();
  }

  // --------------------------------------------------
  // TEST: мгновенное уведомление
  // --------------------------------------------------
  Future<void> testNow() async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      1,
      'Тест уведомления',
      'Если ты это видишь — уведомления работают',
      details,
      payload: 'test_now',
    );
  }

  // --------------------------------------------------
  // TEST: отложенное уведомление (5 секунд)
  // --------------------------------------------------
  Future<void> testNotification() async {
    await init();

    final scheduled =
    tz.TZDateTime.now(tz.UTC).add(const Duration(seconds: 5));

    print('Scheduling test notification at $scheduled');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      999999,
      'Тест отложенного уведомления',
      'Если пришло — zonedSchedule работает',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test_scheduled',
    );
  }

  // --------------------------------------------------
  // НАПОМИНАНИЕ ДЛЯ ЗАМЕТКИ
  // --------------------------------------------------
  Future<void> scheduleReminder(Note note) async {
    if (note.reminderDate == null) return;
    await init();

    final scheduled =
    tz.TZDateTime.from(note.reminderDate!, tz.UTC);

    if (scheduled.isBefore(tz.TZDateTime.now(tz.UTC))) {
      print('Reminder date is in the past');
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _noteId(note),
      note.title.isEmpty ? 'Напоминание' : note.title,
      note.text.isEmpty ? 'Откройте заметку' : note.text,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: note.key.toString(),
    );
  }

  Future<void> cancelReminder(Note note) async {
    await init();
    await _plugin.cancel(_noteId(note));
  }

  Future<void> cancelAllReminders() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> debugPendingNotifications() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (final p in pending) {
      print('ID=${p.id}, title=${p.title}');
    }
  }
}