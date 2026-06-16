import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The **TDLF-Educ** brand logo — a gradient "graduation" badge, with an
/// optional wordmark. Vector-drawn so it stays crisp at any size. Used on the
/// login header and the embedded welcome screen.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const AppLogo({super.key, this.size = 96, this.showWordmark = false});

  @override
  Widget build(BuildContext context) {
    final decor = AppDecoration.of(context);

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: decor.brand,
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: decor.glow(0.42),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft top-left highlight for depth.
          Positioned(
            top: size * 0.1,
            left: size * 0.1,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Icon(Icons.school_rounded, size: size * 0.54, color: Colors.white),
        ],
      ),
    );

    if (!showWordmark) return badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        SizedBox(height: size * 0.2),
        ShaderMask(
          shaderCallback: (r) => decor.brand.createShader(r),
          child: Text(
            'TDLF-Educ',
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: size * 0.04),
        Text(
          'Learn. Read. Grow.',
          style: TextStyle(
            fontSize: size * 0.12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
