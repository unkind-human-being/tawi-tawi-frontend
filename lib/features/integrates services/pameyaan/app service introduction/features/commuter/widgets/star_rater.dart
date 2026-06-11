import 'package:flutter/material.dart';

class StarRater extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;

  const StarRater({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 MAGIC FIX 1: FittedBox scales the stars down so they never overflow the screen!
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starValue = index + 1;
          
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              onRatingChanged(starValue);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0), 
              child: Icon(
                starValue <= rating ? Icons.star : Icons.star_border,
                color: starValue <= rating ? Colors.amber : Colors.grey.shade400,
                size: starSize, // This stays big, but FittedBox will protect it!
              ),
            ),
          );
        }),
      ),
    );
  }
}
