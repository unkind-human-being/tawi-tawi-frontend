import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted-glass surface: blurs whatever sits behind it and overlays a
/// translucent, hair-line-bordered panel. Add [onTap] for a ripple.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final bool strong;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<BoxShadow>? shadow;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.blur = 18,
    this.strong = false,
    this.color,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    final fill = color ?? (strong ? decor.glassFillStrong : decor.glassFill);
    final br = BorderRadius.circular(radius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow ?? decor.softShadow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null ? fill : null,
              gradient: gradient,
              borderRadius: br,
              border: border ?? Border.all(color: decor.glassBorder, width: 1),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: br,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary call-to-action with the brand gradient and a colored glow.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;
  final double radius;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 54,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    final enabled = onPressed != null && !loading;
    final br = BorderRadius.circular(radius);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: decor.brand,
          borderRadius: br,
          boxShadow: enabled ? decor.glow(0.42) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: br,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
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
}

/// A small rounded gradient icon badge (used on cards, tiles, headers).
class GradientIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 50,
    this.iconSize = 26,
    this.radius = 16,
    this.gradient,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? decor.brand,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? decor.glow(0.30),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// An extended floating action button painted with the brand gradient + glow.
class GradientFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const GradientFab({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: decor.brand,
        borderRadius: BorderRadius.circular(18),
        boxShadow: decor.glow(0.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A translucent capsule label, e.g. a role/status pill on gradient surfaces.
class GlassPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;

  const GlassPill({
    super.key,
    required this.text,
    this.icon,
    this.background = const Color(0x33FFFFFF),
    this.foreground = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
