import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanagement/models/task_model.dart';
import 'package:permission_handler/permission_handler.dart';

const String _sendDueDatePrefKey = 'notif_send_due_date';
const String _pendingTaskIdPrefKey = 'pending_notification_task_id';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  static const String channelId = 'task_reminders_channel';
  static const String channelName = 'Nhắc nhở công việc';
  static const String channelDescription =
      'Kênh thông báo cho các nhắc nhở công việc và hạn chót';
  static const String pendingTaskIdPrefKey = _pendingTaskIdPrefKey;

  Future<void> init() async {
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    final fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
    debugPrint("NotificationService Đã khởi tạo (chưa yêu cầu quyền)");
  }

  Future<bool> requestPermissions() async {
    bool notificationGranted = false;

    PermissionStatus notificationStatus =
        await Permission.notification.request();
    debugPrint(
      "Trạng thái quyền Notification sau khi yêu cầu: $notificationStatus",
    );
    notificationGranted = notificationStatus.isGranted;

    if (!notificationGranted) {
      debugPrint("Quyền thông báo không được cấp.");
    }

    PermissionStatus exactAlarmStatus =
        await Permission.scheduleExactAlarm.status;
    debugPrint(
      "Trạng thái quyền ScheduleExactAlarm ban đầu: $exactAlarmStatus",
    );
    if (!exactAlarmStatus.isGranted) {
      debugPrint(
        "Quyền ScheduleExactAlarm chưa được cấp. ViewModel sẽ xử lý việc hiển thị hướng dẫn.",
      );
    }

    debugPrint(
      "Kết quả yêu cầu quyền (chỉ kiểm tra Notification cơ bản): Notification=$notificationGranted",
    );
    return notificationGranted;
  }

  static Future<void> _handleNotificationResponse(
    fln.NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('PAYLOAD THÔNG BÁO (Task ID): $payload');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(pendingTaskIdPrefKey, payload);
        debugPrint('Đã lưu task ID đang chờ xử lý: $payload');
      } catch (e) {
        debugPrint("Lỗi lưu task ID đang chờ vào SharedPreferences: $e");
      }
    } else {
      debugPrint('Thông báo được nhấn không có payload.');
    }
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(
    fln.NotificationResponse notificationResponse,
  ) {
    debugPrint(
      'Thông báo (${notificationResponse.id}) action nhấn trong background/terminated: '
      '${notificationResponse.actionId} với'
      ' payload: ${notificationResponse.payload}',
    );
    if (notificationResponse.input?.isNotEmpty ?? false) {
      debugPrint(
        'Action thông báo được nhấn với input: ${notificationResponse.input}',
      );
    }

    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Cố gắng lưu Task ID từ background callback: $payload');
      _savePendingTaskFromBackground(payload);
    }
  }

  static Future<void> _savePendingTaskFromBackground(String taskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingTaskIdPrefKey, taskId);
      debugPrint('Đã lưu task ID đang chờ xử lý từ background: $taskId');
    } catch (e) {
      debugPrint("Lỗi lưu task ID đang chờ từ background: $e");
    }
  }

  int _createUniqueId(String taskId, Duration offset) {
    final int taskIdHash = taskId.hashCode;
    final int offsetHash = offset.inSeconds.hashCode;
    return (taskIdHash ^ offsetHash) & 0x7FFFFFFF;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    bool hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      debugPrint("Bỏ qua lên lịch thông báo ID $id do thiếu quyền.");
      return;
    }

    if (scheduledTime.isBefore(
      DateTime.now().add(const Duration(seconds: 5)),
    )) {
      debugPrint(
        "Bỏ qua lên lịch thông báo cho thời gian đã qua hoặc quá gần: $scheduledTime (ID: $id)",
      );
      return;
    }

    try {
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      if (scheduledTZTime.isBefore(
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
      )) {
        debugPrint(
          "Bỏ qua lên lịch TZDateTime đã qua: $scheduledTZTime (ID: $id)",
        );
        return;
      }

      const fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
          fln.AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            ticker: 'ticker',
          );
      const fln.DarwinNotificationDetails iOSPlatformChannelSpecifics =
          fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
      const fln.NotificationDetails platformChannelSpecifics =
          fln.NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics,
          );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZTime,
        platformChannelSpecifics,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        // Đã xóa tham số uiLocalNotificationDateInterpretation gây lỗi
        payload: payload,
      );
      debugPrint(
        "Đã lên lịch thông báo ID $id lúc $scheduledTZTime cho payload $payload",
      );
    } catch (e, s) {
      debugPrint("Lỗi nghiêm trọng khi lên lịch thông báo ID $id: $e\n$s");
    }
  }

  Future<void> scheduleTaskReminders(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final bool sendDueDateEnabled = prefs.getBool(_sendDueDatePrefKey) ?? true;

    bool hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      debugPrint(
        "[scheduleTaskReminders] Không có quyền thông báo, bỏ qua lên lịch cho task ${task.id}",
      );
      await cancelNotificationsForTask(task.id);
      return;
    }

    if (!sendDueDateEnabled || task.dueDate == null || task.isDone) {
      debugPrint(
        "[scheduleTaskReminders] Bỏ qua lên lịch cho task ${task.id} do cài đặt hoặc trạng thái task.",
      );
      await cancelNotificationsForTask(task.id);
      return;
    }

    final DateTime dueDate = task.dueDate!;
    final TimeOfDay dueTime =
        task.dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final DateTime dueDateTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTime.hour,
      dueTime.minute,
    );

    await cancelNotificationsForTask(task.id);

    final List<Duration> reminderOffsets = [
      const Duration(hours: 1),
      const Duration(minutes: 30),
      Duration.zero,
    ];
    final String notificationPayload = task.id;

    for (var offset in reminderOffsets) {
      final scheduledTime = dueDateTime.subtract(offset);
      final uniqueId = _createUniqueId(task.id, offset);

      await scheduleNotification(
        id: uniqueId,
        title: "Nhắc nhở: ${task.title}",
        body: _getReminderBody(task.title, offset),
        scheduledTime: scheduledTime,
        payload: notificationPayload,
      );
    }
  }

  String _getReminderBody(String taskTitle, Duration offset) {
    if (offset == Duration.zero) {
      return 'Công việc "$taskTitle" đã đến hạn!';
    } else if (offset == const Duration(minutes: 30)) {
      return 'Còn 30 phút: $taskTitle';
    } else if (offset == const Duration(hours: 1)) {
      return 'Còn 1 giờ: $taskTitle';
    }
    int minutes = offset.inMinutes;
    if (minutes < 60) return 'Còn $minutes phút: $taskTitle';
    int hours = offset.inHours;
    return 'Còn $hours giờ: $taskTitle';
  }

  Future<void> cancelNotificationsForTask(String taskId) async {
    debugPrint(
      "[cancelNotificationsForTask] Đang hủy các thông báo tiềm năng cho task ID: $taskId",
    );
    final List<Duration> reminderOffsets = [
      const Duration(hours: 1),
      const Duration(minutes: 30),
      Duration.zero,
    ];
    int cancelCount = 0;
    for (var offset in reminderOffsets) {
      final uniqueId = _createUniqueId(taskId, offset);
      try {
        await flutterLocalNotificationsPlugin.cancel(uniqueId);
        cancelCount++;
      } catch (e) {
        debugPrint(
          "[cancelNotificationsForTask] Lỗi hủy thông báo ID $uniqueId: $e",
        );
      }
    }
    debugPrint(
      "[cancelNotificationsForTask] Đã thử hủy $cancelCount thông báo tiềm năng cho task ID: $taskId",
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("Đã hủy tất cả thông báo.");
  }
}
