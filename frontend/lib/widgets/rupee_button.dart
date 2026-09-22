// frontend/lib/widgets/rupee_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/kirana_colors.dart';

/// A sleek action button based on the True Master Dashboard design.
/// Uses high-contrast typography and tactile feedback.
class RupeeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showRupeePrefix;
  final bool isLoading;
  final bool fullWidth;
  final Color? color;
  final Gradient? gradient;

  const RupeeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.showRupeePrefix = true,
    this.isLoading = false,
    this.fullWidth = false,
    this.color,
    this.gradient,
  });

  @override
  State<RupeeButton> createState() => _RupeeButtonState();
}

class _RupeeButtonState extends State<RupeeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = widget.color ?? KiranaColors.secondaryContainer;
    final onBackgroundColor = KiranaColors.onSecondaryContainer;

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(onBackgroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showRupeePrefix)
                Text(
                  '₹ ',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: onBackgroundColor,
                  ),
                ),
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    color: onBackgroundColor,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, color: onBackgroundColor, size: 20),
              ],
            ],
          );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.onPressed == null ? null : widget.gradient,
            color: widget.onPressed == null
                ? (isDark ? Colors.white10 : Colors.black12)
                : (widget.gradient == null ? backgroundColor : null),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              if (widget.onPressed != null)
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: widget.fullWidth
              ? SizedBox(width: double.infinity, child: content)
              : content,
        ),
      ),
    );
  }
}
