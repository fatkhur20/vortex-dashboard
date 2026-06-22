import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { arrival, departure, groupJoin, groupLeave, lowBattery }

class TrackerNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  TrackerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type.name, 'title': title, 'body': body,
    'timestamp': timestamp.toIso8601String(), 'read': read,
  };

  factory TrackerNotification.fromJson(Map<String, dynamic> j) => TrackerNotification(
    id: j['id'] as String,
    type: NotificationType.values.firstWhere((e) => e.name == j['type']),
    title: j['title'] as String,
    body: j['body'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    read: j['read'] as bool? ?? false,
  );

  TrackerNotification copyWith({bool? read}) => TrackerNotification(
    id: id, type: type, title: title, body: body, timestamp: timestamp,
    read: read ?? this.read,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final List<TrackerNotification> _notifications = [];
  final ValueNotifier<List<TrackerNotification>> notifier = ValueNotifier([]);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _notifications.addAll(list.map(TrackerNotification.fromJson));
      notifier.value = List.from(_notifications);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
  }

  Future<void> add(TrackerNotification n) async {
    _notifications.insert(0, n);
    notifier.value = List.from(_notifications);
    await _save();
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      notifier.value = List.from(_notifications);
      await _save();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifier.value = [];
    await _save();
  }

  void addArrival(String person, String place) {
    add(TrackerNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.arrival,
      title: '$person arrived at $place',
      body: 'Arrival at $place',
      timestamp: DateTime.now(),
    ));
  }

  void addDeparture(String person, String place) {
    add(TrackerNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.departure,
      title: '$person left $place',
      body: 'Departure from $place',
      timestamp: DateTime.now(),
    ));
  }

  void addGroupJoin(String person, String group) {
    add(TrackerNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.groupJoin,
      title: '$person joined $group',
      body: 'Group join',
      timestamp: DateTime.now(),
    ));
  }

  void addGroupLeave(String person, String group) {
    add(TrackerNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.groupLeave,
      title: '$person left $group',
      body: 'Group leave',
      timestamp: DateTime.now(),
    ));
  }
}

final NotificationService notificationService = NotificationService();
