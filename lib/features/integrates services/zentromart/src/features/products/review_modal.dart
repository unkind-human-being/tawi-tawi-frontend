import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'review_provider.dart';

class LeaveReviewModal extends ConsumerStatefulWidget {
  final String productId;
  const LeaveReviewModal({super.key, required this.productId});

  @override
  ConsumerState<LeaveReviewModal> createState() => _LeaveReviewModalState();
}

class _LeaveReviewModalState extends ConsumerState<LeaveReviewModal> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await ref.read(reviewServiceProvider).submitReview(
            productId: widget.productId,
            rating: _selectedRating,
            comment: _commentController.text.trim(),
          );

      // Invalidate the cache to instantly update the screen below
      ref.invalidate(productReviewsProvider(widget.productId));
      ref.invalidate(ratingSummaryProvider(widget.productId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Review submitted! Thank you! 🎉"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Could not save review: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Share your feedback",
              style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Star Picker Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                iconSize: 36,
                onPressed: () => setState(() => _selectedRating = starValue),
                icon: Icon(
                  Icons.star,
                  color: starValue <= _selectedRating
                      ? Colors.amber
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "What did you like or dislike about this product?",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Review",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
