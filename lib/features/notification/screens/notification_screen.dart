import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import '../../../core/widgets/liquid_background.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: const Color(0xFF121111),
                size: Theme.of(context).platform == TargetPlatform.iOS ? 18 : 22,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  final hasWrapper = context.findAncestorWidgetOfExactType<MainNavigationWrapper>() != null;
                  if (hasWrapper) {
                    MainNavigationWrapper.activeTabNotifier.value = 0;
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF121111),
            fontSize: 15,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                _showConfirmClearDialog(context, notificationProvider);
              },
              child: Text(
                'Clear All',
                style: GoogleFonts.outfit(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildNotificationsList(notifications, notificationProvider),
    ),
  );
}

  // Exact reproduction of the mock notifications page screenshot
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                size: 72,
                color: Color(0xFFC2C2C2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't gotten any\nnotifications yet!",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121111),
                height: 1.3,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF0066CC),
                decorationThickness: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "We'll alert you when something\ncool happens.",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF888888),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80), // Offset spacing from center bottom
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<NotificationModel> notifications,
    NotificationProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return _buildNotificationCard(notif, provider);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, NotificationProvider provider) {
    // Select icon depending on push type
    List<List<dynamic>> cardIcon;
    Color iconBgColor;
    Color iconColor;

    switch (notif.type) {
      case 'abandoned_cart':
        cardIcon = HugeIcons.strokeRoundedShoppingBag01;
        iconBgColor = const Color(0xFFFFF3CD); // Gold yellow
        iconColor = const Color(0xFF856404);
        break;
      case 'new_drop':
        cardIcon = HugeIcons.strokeRoundedSparkles;
        iconBgColor = const Color(0xFFD4EDDA); // Pastel green
        iconColor = const Color(0xFF155724);
        break;
      case 'payment':
      case 'order_update':
        cardIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
        iconBgColor = const Color(0xFFD1ECF1); // Light cyan
        iconColor = const Color(0xFF0C5460);
        break;
      default:
        cardIcon = HugeIcons.strokeRoundedNotification01;
        iconBgColor = const Color(0xFFE2E3E5); // Muted gray
        iconColor = const Color(0xFF383D41);
        break;
    }

    final formattedTime = _getFormattedTime(notif.timestamp);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.deleteNotification(notif.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification cleared.'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: PressScaleEffect(
          onTap: () {
            // Mark as read
            provider.markAsRead(notif.id);
            // Dynamic routing on tap
            _handleNotificationNavigation(notif.type);
          },
          child: Container(
            decoration: BoxDecoration(
              color: notif.isRead ? Colors.white : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notif.isRead 
                    ? const Color(0xFFF2F2F2) 
                    : const Color(0xFFE2E2E2),
                width: notif.isRead ? 1.0 : 1.2,
              ),
              boxShadow: notif.isRead
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Specific Icon Badge
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: cardIcon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: GoogleFonts.outfit(
                                  fontWeight: notif.isRead 
                                      ? FontWeight.w600 
                                      : FontWeight.w800,
                                  fontSize: 13.5,
                                  color: const Color(0xFF121111),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedTime,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: const Color(0xFF888888),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          notif.body,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                            height: 1.4,
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd MMM').format(time);
    }
  }

  void _handleNotificationNavigation(String type) {
    switch (type) {
      case 'abandoned_cart':
        Navigator.pop(context);
        MainNavigationWrapper.activeTabNotifier.value = 3; // Cart tab
        break;
      case 'new_drop':
        Navigator.pop(context);
        MainNavigationWrapper.activeTabNotifier.value = 2; // New Drops tab
        break;
      case 'payment':
      case 'order_update':
        Navigator.pop(context);
        MainNavigationWrapper.activeTabNotifier.value = 4; // Profile tab
        break;
      default:
        // Regular promotion: just stay here
        break;
    }
  }

  void _showConfirmClearDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Clear Notifications?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to permanently clear all notifications?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                provider.clearAll();
                Navigator.pop(context);
              },
              child: const Text('CLEAR ALL', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}
