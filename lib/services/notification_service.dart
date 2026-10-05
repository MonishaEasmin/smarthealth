import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // নোটিফিকেশন ইঞ্জিন ইনিশিয়ালাইজ করা
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka')); // বাংলাদেশ টাইমজোন

    // 👉 অ্যান্ড্রয়েড নোটিফিকেশন চ্যানেল তৈরি করা (এটি নোটিফিকেশন আসার জন্য ১০০% গ্যারান্টি)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel_id', // এই আইডিটি নিচের zonedSchedule এর সাথে মিল থাকতে হবে
      'Medication Reminders',
      description: 'Channel for medicine intake reminders',
      importance: Importance.max, // সবচেয়ে হাই প্রায়োরিটি যাতে লক স্ক্রিনেও আসে
      playSound: true,
      enableVibration: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // 👉 অ্যান্ড্রয়েড ওএস-এর কাছে চ্যানেলটি রেজিস্টার করা
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  // রানটাইম পারমিশন চাওয়ার মেথড
  static Future<void> requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // পারফেক্ট শিডিউল মেথড
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();

    var scheduleDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel_id', // ওপরে ক্রিয়েট করা চ্যানেলের সাথে হুবহু মিল
          'Medication Reminders',
          channelDescription: 'Channel for medicine intake reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}