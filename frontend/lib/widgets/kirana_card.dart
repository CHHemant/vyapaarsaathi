// frontend/lib/widgets/kirana_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/kirana_colors.dart';

/// A realistic premium card with subtle glassmorphic effects, 
/// soft multi-layered shadows, and smooth interactions.
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
  final bool useGlass;

  const KiranaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.elevation = 4,
    this.borderRadius = 20,
    this.useGlass = false,
  });

  @override
  State<KiranaCard> createState() => _KiranaCardState();
}

class _KiranaCardState extends State<KiranaCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = widget.color ?? (isDark ? KiranaColors.surfaceDark : KiranaColors.surfaceLight);
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.indigo.withOpacity(0.08);

    Widget content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.useGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -2.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.useGlass 
              ? (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7))
              : baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? (isDark ? Colors.white10 : Colors.indigo.withOpacity(0.05)),
            width: widget.borderWidth ?? 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: KiranaColors.primary.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }
}
