import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'abandoned_cart', 'payment', 'new_drop', 'promo', etc.
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? 'promo',
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static const String _storageKey = 'user_received_notifications';

  NotificationProvider() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null) {
        final List<dynamic> decodedList = jsonDecode(savedStr);
        _notifications = decodedList
            .map((item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        // Sort notifications to show newest first
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading cached notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final newNotif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
    );

    _notifications.insert(0, newNotif);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, dataStr);
    } catch (e) {
      debugPrint('Error saving notifications to cache: $e');
    }
  }
}
