import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A soft, animated "aurora" backdrop: a tinted base with several large,
/// blurred colored glows drifting behind the content. Use as the bottom of a
/// [Stack] (or simply wrap a screen's body).
class AuroraBackground extends StatefulWidget {
  final Widget child;

  /// When false the glows hold still (cheaper, e.g. behind scrolling lists).
  final bool animate;

  const AuroraBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decor = AppDecoration.of(context);
    final colors = decor.auroraColors;
    final dark = cs.brightness == Brightness.dark;
    final blobOpacity = dark ? 0.42 : 0.32;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: cs.surface)),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_c.value);
            return Stack(
              children: [
                _blob(
                  align: Alignment(-1.1 + 0.15 * t, -1.0),
                  size: 360,
                  color: colors[0],
                  opacity: blobOpacity,
                ),
                _blob(
                  align: Alignment(1.2 - 0.2 * t, -0.6 + 0.2 * t),
                  size: 320,
                  color: colors[1],
                  opacity: blobOpacity,
                ),
                _blob(
                  align: Alignment(-0.9, 1.0 - 0.15 * t),
                  size: 300,
                  color: colors[2],
                  opacity: blobOpacity * 0.85,
                ),
                _blob(
                  align: Alignment(1.0, 1.1 - 0.2 * t),
                  size: 280,
                  color: colors[3],
                  opacity: blobOpacity * 0.8,
                ),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }

  Widget _blob({
    required Alignment align,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Align(
      alignment: align,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
