import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'About ENGIVAULT',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy950, AppColors.navy900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.blue600.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: AppColors.blue400, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENGIVAULT',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'KTU Learning. Simplified.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cyan400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'ENGIVAULT is an academic digital vault purpose-built for engineering undergraduates under APJ Abdul Kalam Technological University (KTU), Kerala.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Core Principles
          const Text(
            'Core Principles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 12),

          const GlassCard(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _FeatureRow(
                  icon: Icons.account_tree_outlined,
                  title: 'Academic Hierarchy',
                  description:
                      'Structured according to KTU schemes: Department → Semester → Subject → Module → Topic → Lecture.',
                ),
                Divider(height: 24, color: AppColors.borderLight),
                _FeatureRow(
                  icon: Icons.smart_display_outlined,
                  title: 'YouTube-First Delivery',
                  description:
                      'All lectures feature vetted high-yield video lessons with direct 16:9 responsive playback.',
                ),
                Divider(height: 24, color: AppColors.borderLight),
                _FeatureRow(
                  icon: Icons.menu_book_outlined,
                  title: 'Handwritten Notes & Syllabus',
                  description:
                      'Download lecture slides, module notes, and previous year question papers directly.',
                ),
                Divider(height: 24, color: AppColors.borderLight),
                _FeatureRow(
                  icon: Icons.groups_outlined,
                  title: 'FOLE SPACE Community',
                  description:
                      'Physical co-learning space, technical workshops, hackathons, and industrial cohort programs.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Developed by FOLE
          const Text(
            'The Organization',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 12),
          const GlassCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOLE — Future of Learning & Engineering',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'FOLE is an engineering collective dedicated to bridging the divide between conventional university curricula and real-world engineering craftsmanship.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.blue600, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy950,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
