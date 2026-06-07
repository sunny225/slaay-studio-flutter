import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/cms_service.dart';
import '../models/cms_layout_component.dart';

class CmsProvider extends ChangeNotifier {
  final CmsService _cmsService = CmsService();

  List<CmsLayoutComponent> _layoutComponents = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isApiPreloaded = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<CmsLayoutComponent> get layoutComponents => _layoutComponents;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isPreloaded => _isApiPreloaded || _layoutComponents.isNotEmpty;
  String? get errorMessage => _errorMessage;

  CmsProvider() {
    _initCacheAndFetch();
  }

  Future<void> _initCacheAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_home_layout');
      if (cachedStr != null) {
        final List<dynamic> data = jsonDecode(cachedStr);
        _layoutComponents = data.map((item) {
          if (item is Map) {
            return CmsLayoutComponent.fromJson(Map<String, dynamic>.from(item));
          }
          return CmsLayoutComponent(type: 'unknown', items: []);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached home layout: $e');
    }

    _isInitialized = true;
    notifyListeners();

    // Fetch fresh home layout in the background
    await fetchHomeLayout();

    // Setup periodic polling timer for background layout updates (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      fetchHomeLayout();
    });
  }

  Future<void> fetchHomeLayout() async {
    final hasCache = _layoutComponents.isNotEmpty;
    if (!hasCache) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final freshComponents = await _cmsService.getHomeLayout();
      if (freshComponents.isNotEmpty) {
        _layoutComponents = freshComponents;
        
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = jsonEncode(_layoutComponents.map((e) => e.toJson()).toList());
        await prefs.setString('cached_home_layout', jsonStr);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      _isApiPreloaded = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
