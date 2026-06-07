import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../services/api_client.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<dynamic> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiClient.get('/public/coupons');
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _coupons = body['data'];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
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
            'COUPONS & OFFERS',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchCoupons,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _coupons.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedTicket01,
                                size: 48,
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Active Coupons",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Check back later for exciting offers and deals!",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                      itemCount: _coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = _coupons[index];
                        final expires = DateTime.parse(coupon['expiresAt']);
                        final expiryStr = DateFormat('dd MMM yyyy').format(expires);
                        final code = coupon['code'] ?? 'SLAAY';
                        final double value = (coupon['value'] as num?)?.toDouble() ?? 0.0;
                        final isPercent = coupon['discountType'] == 'percent';
                        final double minOrder = (coupon['minOrderAmount'] as num?)?.toDouble() ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CustomPaint(
                            painter: TicketPainter(
                              color: isDarkMode ? Colors.black26 : Colors.grey.withValues(alpha: 0.04),
                              strokeColor: Colors.transparent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                code,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  letterSpacing: 1.5,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: code));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Coupon code "$code" copied to clipboard!'),
                                                    backgroundColor: AppColors.success,
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isPercent
                                              ? 'Get ${value.toInt()}% OFF on your order'
                                              : 'Get Flat ₹${value.toInt()} OFF on your order',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Minimum order value: ₹${minOrder.toInt()}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Valid till: $expiryStr',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: isDarkMode ? Colors.white38 : Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedTicket01,
                                        size: 36,
                                        color: AppColors.primary.withValues(alpha: 0.3),
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

class TicketPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  TicketPainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.4)
      ..arcToPoint(
        Offset(0, size.height * 0.6),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.6)
      ..arcToPoint(
        Offset(size.width, size.height * 0.4),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
