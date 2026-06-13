import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class DriverFeedbackTab extends StatelessWidget {
  const DriverFeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response>(
      // Tell it to hit the new endpoint we just made
      future: ApiClient.instance.get('/drivers/me/ratings'), 
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error State
        if (snapshot.hasError) {
          return const Center(child: Text("Could not load feedback."));
        }

        // 3. Success State - Extract Data
        final List<dynamic> ratings = snapshot.data?.data ?? [];

        // 4. Empty State (If they truly have no text reviews)
        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "No feedback yet.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Keep driving safely to earn ratings!",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 5. Build the List of Reviews!
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: ratings.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final review = ratings[index];
            final int stars = review['rating_value'] ?? 0;
            final String text = review['review_text'] ?? '';
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.person_outline, color: Colors.blue),
              ),
              title: Row(
                children: [
                  // Draw the mini stars
                  ...List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < stars ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                  const Spacer(),
                  // Show the date
                  Text(
                    review['date'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              subtitle: text.isNotEmpty 
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  )
                : null,
            );
          },
        );
      },
    );
  }
}
