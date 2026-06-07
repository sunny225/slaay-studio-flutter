import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../models/order.dart';
import '../../../services/order_service.dart';
import '../../../core/widgets/skeleton_loader.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _loadOrder();
      }
    });
  }

  Future<void> _loadOrder() async {
    try {
      final orders = await _orderService.getOrders();
      final matched = orders.firstWhere((o) => o.id == widget.orderId);
      setState(() {
        _order = matched;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Diagnostic helper to demo tracking changes
  void _advanceOrderStatus() async {
    if (_order == null) return;
    
    OrderStatus nextStatus;
    switch (_order!.status) {
      case OrderStatus.placed:
        nextStatus = OrderStatus.packed;
        break;
      case OrderStatus.packed:
        nextStatus = OrderStatus.shipped;
        break;
      case OrderStatus.shipped:
        nextStatus = OrderStatus.outForDelivery;
        break;
      case OrderStatus.outForDelivery:
        nextStatus = OrderStatus.delivered;
        break;
      default:
        nextStatus = OrderStatus.placed;
    }

    await _orderService.updateLocalOrderStatus(_order!.id, nextStatus);
    _loadOrder(); // Reload state
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order advanced to: ${nextStatus.name.toUpperCase()}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: OrderTrackingSkeleton(),
        ),
      );
    }

    if (_order == null) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Track Order')),
          body: const Center(child: Text('Order history record not found.')),
        ),
      );
    }

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'TRACK ORDER',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Itemized list card
            Text(
              'Items Ordered',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildOrderedItemsList(),
            const SizedBox(height: 24),

            // Order details summary card
            _buildOrderDetailsHeader(),
            const SizedBox(height: 24),

            // Stepper timeline
            Text(
              'Delivery Status',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatusTimeline(),
            const SizedBox(height: 24),

            // Shipping Address Card
            _buildShippingAddressSection(),
            const SizedBox(height: 32),

            // Quick back button and diagnostic simulator button
            ElevatedButton(
              onPressed: () {
                // Return to catalog home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('CONTINUE SHOPPING'),
            ),
            const SizedBox(height: 12),
            
            // Diagnostic status simulator button
            OutlinedButton.icon(
              onPressed: _advanceOrderStatus,
              icon: const Icon(Icons.speed, size: 18),
              label: const Text('DEMO: ADVANCE ORDER STEP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildOrderDetailsHeader() {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(_order!.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER ID', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_order!.id, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL VALUE', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('₹${_order!.totalAmount.toInt()}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Placed: $dateStr', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight)),
              Text('Method: ${_order!.paymentMethod}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    // Return tracking step indices
    int getStepIndex() {
      switch (_order!.status) {
        case OrderStatus.placed:
          return 0;
        case OrderStatus.packed:
          return 1;
        case OrderStatus.shipped:
          return 2;
        case OrderStatus.outForDelivery:
          return 3;
        case OrderStatus.delivered:
          return 4;
        case OrderStatus.cancelled:
          return -1;
      }
    }

    final activeStep = getStepIndex();

    Widget stepNode(int stepNum, String title, String subtitle, IconData icon) {
      final isCompleted = activeStep >= stepNum;
      final isActive = activeStep == stepNum;
      
      final Color stateColor = isCompleted
          ? (stepNum == 4 ? AppColors.success : AppColors.primary)
          : AppColors.borderLight;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic node containing vertical line and circles
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? stateColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? stateColor : AppColors.borderLight,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.check : icon,
                  color: isCompleted ? Colors.white : AppColors.textSecondaryLight,
                  size: 14,
                ),
              ),
              // Connecting line
              if (stepNum < 4)
                Container(
                  width: 2,
                  height: 45,
                  color: activeStep > stepNum ? stateColor : AppColors.borderLight,
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Texts
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_order!.status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: AppColors.error),
            const SizedBox(width: 12),
            Text('This order has been cancelled.', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: [
        stepNode(0, 'Order Placed', 'We have received your order.', Icons.shopping_cart_outlined),
        stepNode(1, 'Order Packed', 'Your clothes are packed and quality-checked.', Icons.inventory_2_outlined),
        stepNode(2, 'Shipped', 'Handed over to our courier partner.', Icons.local_shipping_outlined),
        stepNode(3, 'Out For Delivery', 'Delivering to your address today.', Icons.directions_run_outlined),
        stepNode(4, 'Delivered', 'Order successfully received.', Icons.done_all_outlined),
      ],
    );
  }

  Widget _buildShippingAddressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Delivery Address', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order!.address.fullName,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _order!.address.fullAddressString,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${_order!.address.phoneNumber}',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _order!.items.length,
      itemBuilder: (context, index) {
        final item = _order!.items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.product.images.isNotEmpty 
                      ? item.product.images[0] 
                      : 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=500',
                  height: 60,
                  width: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Size: ${item.size}  x  Qty: ${item.quantity}', style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              Text(
                '₹${item.totalPrice.toInt()}',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
