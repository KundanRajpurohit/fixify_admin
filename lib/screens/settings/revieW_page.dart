import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RatingPage extends ConsumerWidget {
  const RatingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = List.generate(
      3,
      (index) => const ReviewModel(
        name: 'Paula Lewis',
        jobType: 'House Cleaning',
        date: '24 Nov, 2025',
        rating: 4.0,
        reviewText: 'Great service! Very professional and quick.',
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFffffff),
      appBar: CustomAppBar(
        title: ref.t('profile.my_rating_reviews'),
        showbackButton: true,
      ), // dark outer background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildSummaryCard(ref),
              const SizedBox(height: 16),
              ...reviews.map((r) => _buildReviewCard(r)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Top summary card ----------
  Widget _buildSummaryCard(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: overall rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '4.5',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 22, color: Color(0xFFFFC107)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '273 ${ref.t('dashboard.reviews')}',
                style:  TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Right: rating distribution bars
          Expanded(
            child: Column(
              children: [
                _buildRatingBarRow(5, 0.95),
                _buildRatingBarRow(4, 0.85),
                _buildRatingBarRow(3, 0.55),
                _buildRatingBarRow(2, 0.25),
                _buildRatingBarRow(1, 0.18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBarRow(int star, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text('$star', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Single review card ----------
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                review.date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.jobType,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Stars + numeric rating
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 18,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${review.rating.toStringAsFixed(1)})',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quoted text inside light blue box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCCE0FF)),
            ),
            child: Text(
              '"${review.reviewText}"',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple model just for this UI
class ReviewModel {
  final String name;
  final String jobType;
  final String date;
  final double rating;
  final String reviewText;

  const ReviewModel({
    required this.name,
    required this.jobType,
    required this.date,
    required this.rating,
    required this.reviewText,
  });
}
