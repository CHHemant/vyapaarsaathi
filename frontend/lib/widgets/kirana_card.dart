// frontend/lib/widgets/kirana_card.dart

import 'package:flutter/material.dart';
import '../theme/kirana_colors.dart';

/// A sleek, tactile card based on the True Master Dashboard design.
/// Features subtle borders and light shadows for a professional fintech feel.
class KiranaCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;

  const KiranaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.elevation = 2,
    this.borderRadius = 16,
  });

  @override
  State<KiranaCard> createState() => _KiranaCardState();
}

class _KiranaCardState extends State<KiranaCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = widget.color ??
        (isDark
            ? KiranaColors.surfaceContainer
            : KiranaColors.surfaceContainerLowest);
    final borderColor = widget.borderColor ??
        KiranaColors.outlineVariant.withValues(alpha: 0.2);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: widget.margin,
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scaleByDouble(_isPressed ? 0.98 : 1.0, 1.0, 1.0, 1.0),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: borderColor,
              width: widget.borderWidth ?? 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: widget.elevation * 2,
                offset: Offset(0, widget.elevation / 2),
              ),
            ],
          ),
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
