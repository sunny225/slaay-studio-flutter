import 'package:flutter/material.dart';
import '../constants/colors.dart';

class LiquidBackground extends StatefulWidget {
  final Widget? child;
  const LiquidBackground({super.key, this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget baseBg;
    if (AppColors.usePremiumTheme) {
      baseBg = Container(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      );
    } else {
      baseBg = Container(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF),
      );
    }

    return Stack(
      children: [
        baseBg,
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
