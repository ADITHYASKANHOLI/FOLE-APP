import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final uri =
        Uri.parse('mailto:support@engivault.app?subject=ENGIVAULT%20Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact email: support@engivault.app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Contact & Support',
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'We are here to help',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Have questions about notes, missed a lecture, or need support with FOLE SPACE passes? Reach out anytime.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.email_outlined,
                  title: 'Support Email',
                  detail: 'support@engivault.app',
                  actionLabel: 'Send Email',
                  onTap: () => _sendEmail(context),
                ),
                const Divider(height: 24, color: AppColors.borderLight),
                _ContactTile(
                  icon: Icons.place_outlined,
                  title: 'Physical Co-Learning Space',
                  detail: 'FOLE SPACE, Kerala, India',
                  actionLabel: 'View Details',
                  onTap: () {},
                ),
                const Divider(height: 24, color: AppColors.borderLight),
                _ContactTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report Content Discrepancy',
                  detail: 'Flag broken video links or inaccurate KTU notes',
                  actionLabel: 'Report',
                  onTap: () => _sendEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Operating Hours Card
          const GlassCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOLE SPACE Walk-in Hours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Monday – Saturday: 09:00 AM – 06:00 PM IST\nSunday: Special Cohorts & Hackathons only',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onTap,
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
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
