import 'package:flutter/material.dart';

class NotificationIllustration extends StatelessWidget {
  const NotificationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Aesthetic Color Palette
    final phoneBodyColor = isDark ? const Color(0xFF5A4C5D) : const Color(0xFF333333);
    final phoneScreenColor = isDark ? const Color(0xFF1F1722) : const Color(0xFFFFFFFF);
    final toggleTrackColor = const Color(0xFFC59F4E); // Elegant Golden-Brown
    final placeholderColor = isDark ? const Color(0xFF322835) : const Color(0xFFECEFF1);
    final stemColor = isDark ? Colors.white12 : Colors.black12;
    final dotColor = isDark ? Colors.white12 : Colors.black12;
    final bodyLineColor = isDark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);
    final shirtColor = isDark ? const Color(0xFFB0A0B3) : const Color(0xFFE0E0E0);
    final pantsColor = isDark ? const Color(0xFF3A2F3D) : const Color(0xFF424242);
    final hairColor = isDark ? const Color(0xFF221A24) : const Color(0xFF212121);
    final skinColor = const Color(0xFFFCD0A1);

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Background Ground Line
          Positioned(
            bottom: 25,
            left: 40,
            right: 40,
            child: Container(
              height: 1.2,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),

          // 2. Decorative Dots (Background accents)
          Positioned(
            left: 80,
            top: 40,
            child: _buildDot(8, dotColor),
          ),
          Positioned(
            left: 200,
            top: 35,
            child: _buildDot(6, dotColor),
          ),
          Positioned(
            left: 115,
            bottom: 70,
            child: _buildDot(10, dotColor),
          ),
          Positioned(
            right: 100,
            bottom: 60,
            child: _buildDot(8, dotColor),
          ),

          // 3. Foliage / Stems (Left and Right background plants)
          Positioned(
            left: 120,
            bottom: 25,
            child: CustomPaint(
              size: const Size(45, 55),
              painter: _FoliagePainter(stemColor),
            ),
          ),
          Positioned(
            right: 85,
            bottom: 25,
            child: CustomPaint(
              size: const Size(25, 40),
              painter: _FoliagePainter(stemColor),
            ),
          ),

          // 4. Phone Mockup (Tilted slightly to the left)
          Positioned(
            left: 110,
            top: 25,
            child: Transform.rotate(
              angle: -0.12, // Subtle leftward tilt
              child: Container(
                width: 78,
                height: 140,
                decoration: BoxDecoration(
                  color: phoneBodyColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(-2, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4.5),
                child: Container(
                  decoration: BoxDecoration(
                    color: phoneScreenColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Camera Notch
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 24,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: phoneBodyColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      // Screen Contents: Toggle Box
                      Positioned(
                        top: 20,
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: toggleTrackColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Mock Switch Track
                              Positioned(
                                right: 8,
                                child: Container(
                                  width: 26,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                              // Mock Switch Thumb (Toggled ON / Right aligned)
                              Positioned(
                                right: 6,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Screen Contents: Placeholder card below toggle
                      Positioned(
                        top: 66,
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: placeholderColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      // Screen Contents: Placeholder lines
                      Positioned(
                        top: 100,
                        left: 10,
                        child: Container(
                          width: 28,
                          height: 4,
                          decoration: BoxDecoration(
                            color: placeholderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Minimalist Standing Character (Right side)
          Positioned(
            right: 125,
            bottom: 25,
            child: SizedBox(
              width: 50,
              height: 145,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Hair Bun
                  Positioned(
                    top: 18,
                    right: 8,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: hairColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Head (Skin & Hair)
                  Positioned(
                    top: 25,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: skinColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 23,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 20,
                        height: 10,
                        decoration: BoxDecoration(
                          color: hairColor,
                        ),
                      ),
                    ),
                  ),

                  // Neck
                  Positioned(
                    top: 42,
                    child: Container(
                      width: 5,
                      height: 8,
                      decoration: BoxDecoration(
                        color: skinColor,
                      ),
                    ),
                  ),

                  // Torso (Shirt)
                  Positioned(
                    top: 48,
                    child: Container(
                      width: 18,
                      height: 42,
                      decoration: BoxDecoration(
                        color: shirtColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Legs/Pants
                  Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Leg (Stepping back slightly)
                        Transform.rotate(
                          angle: 0.1,
                          origin: const Offset(0, -20),
                          child: Container(
                            width: 6,
                            height: 54,
                            decoration: BoxDecoration(
                              color: pantsColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Leg (Standing straight)
                        Transform.rotate(
                          angle: -0.1,
                          origin: const Offset(0, -20),
                          child: Container(
                            width: 6,
                            height: 54,
                            decoration: BoxDecoration(
                              color: pantsColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Left Arm (Gesturing towards the phone)
                  Positioned(
                    top: 50,
                    left: 2,
                    child: Transform.rotate(
                      angle: -0.8,
                      origin: const Offset(0, -10),
                      child: Container(
                        width: 5,
                        height: 28,
                        decoration: BoxDecoration(
                          color: shirtColor,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),

                  // Left hand (Skin)
                  Positioned(
                    top: 44,
                    left: -2,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: skinColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FoliagePainter extends CustomPainter {
  final Color stemColor;
  _FoliagePainter(this.stemColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stemColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.fill;

    // Draw main stem
    final path = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.1,
      );
    canvas.drawPath(path, paint);

    // Draw small leaves along stem
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.65),
        width: 7,
        height: 4,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.45),
        width: 8,
        height: 5,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.1),
        width: 9,
        height: 6,
      ),
      leafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
