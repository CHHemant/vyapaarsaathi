// frontend/lib/widgets/rupee_button.dart

import 'package:flutter/material.dart';
import '../theme/kirana_colors.dart';

/// A premium action button with fluid animations, 
/// realistic gradients, and sophisticated typography.
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

class _RupeeButtonState extends State<RupeeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
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
    
    final effectiveGradient = widget.gradient ?? KiranaColors.premiumGradient;
    
    final content = widget.isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              if (widget.showRupeePrefix)
                const Text(
                  '₹ ',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.onPressed == null ? null : effectiveGradient,
            color: widget.onPressed == null 
                ? (isDark ? Colors.white10 : Colors.black12) 
                : widget.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (widget.onPressed != null)
                BoxShadow(
                  color: (widget.color ?? KiranaColors.primary).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
