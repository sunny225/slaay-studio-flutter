import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../models/order.dart';
import '../../../services/order_service.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final history = await _orderService.getOrders();
      setState(() {
        _orders = history;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: isDarkMode ? Colors.white : AppColors.primary,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'MY ORDERS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchOrders,
          color: AppColors.primary,
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: OrderHistorySkeleton(),
                )
              : _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedShoppingBag01,
                                  size: 48,
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Orders Found",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                child: Text(
                                  "You haven't placed any orders yet. Explore our latest drops and find your perfect fit!",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final formattedDate = DateFormat('dd MMM yyyy').format(order.date);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderTrackingScreen(orderId: order.id),
                                ),
                              ).then((_) => _fetchOrders());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order ID: ${order.id}',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Placed on: $formattedDate',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: order.status == OrderStatus.delivered
                                                ? AppColors.success.withValues(alpha: 0.1)
                                                : AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            order.status.name.toUpperCase(),
                                            style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: order.status == OrderStatus.delivered
                                                  ? AppColors.success
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${order.totalAmount.toInt()}',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Track',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedArrowRight01,
                                            size: 14,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
