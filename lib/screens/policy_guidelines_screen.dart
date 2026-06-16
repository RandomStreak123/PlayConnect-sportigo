import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';

class PolicyGuidelinesScreen extends StatelessWidget {
  const PolicyGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTitleColor = isDark ? Colors.white : const Color(0xFF0F1E4A);

    final List<PolicyItem> policies = const [
      PolicyItem(
        number: '1',
        title: 'Account Security & Verification',
        description:
            'To guarantee quick and secure authentication, especially in the event of a forgotten password, all players must register with a valid email. This ensures that your progress, stats, and personal bookings remain secure and recoverable.',
        icon: Icons.verified_user_outlined,
        color: Colors.blue,
      ),
      PolicyItem(
        number: '2',
        title: 'Code of Conduct & Fair Play',
        description:
            'Maintain a respectful, friendly environment during matches. PlayConnect has a zero-tolerance policy for harassment, cheating, or unsportsmanlike behavior. Violation of code of conduct can lead to permanent account suspension.',
        icon: Icons.gavel_rounded,
        color: Colors.redAccent,
      ),
      PolicyItem(
        number: '3',
        title: 'Safety & Safety Policies',
        description:
            'Only verified female players can join matches designated as "Women-Only". PlayConnect is committed to providing a safe, friendly, and inclusive sporting ecosystem for everyone.',
        icon: Icons.health_and_safety_outlined,
        color: Colors.pink,
      ),
      PolicyItem(
        number: '4',
        title: 'Cancellation & Refund Policy',
        description:
            'Full refund is available if a match spot or booking is cancelled at least 24 hours prior to the scheduled start. Cancellations made within 24 hours of the match start time are non-refundable.',
        icon: Icons.currency_exchange_rounded,
        color: Colors.teal,
      ),
      PolicyItem(
        number: '5',
        title: 'Limitation of Liability',
        description:
            'PlayConnect or associated venues are not liable for physical injuries sustained during matches. Players participate at their own risk and are advised to maintain physical fitness and wear proper protective gear.',
        icon: Icons.error_outline_rounded,
        color: Colors.amber,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: headerTitleColor),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              color: Colors.teal,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Policies & Guidelines',
              style: TextStyle(
                color: headerTitleColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFEBEBF0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 4, vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review the official terms, safety standards, and cancellation guidelines for the PlayConnect platform:',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: policies.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final policy = policies[index];
                        return _buildPolicyCard(context, policy, isDark);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, PolicyItem policy, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left border accent color
              Container(
                width: 5,
                color: policy.color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon Circle
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: policy.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              policy.icon,
                              color: policy.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Number & Title
                          Expanded(
                            child: Text(
                              '${policy.number}. ${policy.title}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F1E4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        policy.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PolicyItem {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PolicyItem({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
