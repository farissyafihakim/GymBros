import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

enum _PlanType { annual, monthly }

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  _PlanType _selected = _PlanType.annual;

  void _onGetStarted(_PlanType plan) {
    debugPrint('Starting checkout for: $plan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(onClose: () => Navigator.maybePop(context)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlanCard(
                      badgeLabel: 'BEST VALUE',
                      badgeColor: const Color(0xFFC6F135),
                      badgeTextColor: const Color(0xFF0D0D0D),
                      planName: 'Annual',
                      trialLabel: '30-day free trial',
                      priceLine: 'then RM199.90/year',
                      subPriceLine: 'RM16.66/month',
                      bullets: const [
                        '1 Premium account',
                        'Save 45% vs monthly',
                        'Cancel anytime',
                      ],
                      isSelected: _selected == _PlanType.annual,
                      onTap: () => setState(() => _selected = _PlanType.annual),
                      onGetStarted: () => _onGetStarted(_PlanType.annual),
                    ),
                    const SizedBox(height: 20),
                    _PlanCard(
                      badgeLabel: '30-DAY FREE TRIAL',
                      badgeColor: const Color(0xFF2A2A2A),
                      badgeTextColor: const Color(0xFFD0D0D0),
                      planName: 'Monthly',
                      trialLabel: '30-day free trial',
                      priceLine: 'then RM29.90/month',
                      subPriceLine: null,
                      bullets: const [
                        '1 Premium account',
                        'Billed monthly',
                        'Cancel anytime',
                      ],
                      isSelected: _selected == _PlanType.monthly,
                      onTap: () =>
                          setState(() => _selected = _PlanType.monthly),
                      onGetStarted: () => _onGetStarted(_PlanType.monthly),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Free trial for 30 days, then plan price applies. Cancel anytime before the trial ends and you won\'t be charged.',
                      style: TextStyle(
                        color: Color(0xFF5A5A5A),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF9A9A9A),
                    size: 18,
                  ),
                  onPressed: onClose,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC6F135),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF0D0D0D),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GymBros Premium',
                    style: TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Choose your plan',
            style: TextStyle(
              color: Color(0xFFF0F0F0),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Unlock unlimited workouts, tracking and coaching.',
            style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;
  final String planName;
  final String trialLabel;
  final String priceLine;
  final String? subPriceLine;
  final List<String> bullets;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onGetStarted;

  const _PlanCard({
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.planName,
    required this.trialLabel,
    required this.priceLine,
    required this.subPriceLine,
    required this.bullets,
    required this.isSelected,
    required this.onTap,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    const neonColor = Color(0xFFC6F135);
    const inactiveColor = Color(0xFF3A3A3A);

    final Color effectiveColor = isSelected ? neonColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveColor,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? neonColor : Colors.transparent,
                    border: Border.all(color: effectiveColor, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Color(0xFF0D0D0D),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  color: effectiveColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'GymBros Premium',
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              planName,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              priceLine,
              style: const TextStyle(
                color: Color(0xFFD0D0D0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subPriceLine != null) ...[
              const SizedBox(height: 2),
              Text(
                subPriceLine!,
                style: const TextStyle(
                  color: Color(0xFF6A6A6A),
                  fontSize: 12.5,
                ),
              ),
            ],
            const SizedBox(height: 18),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A7A7A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Color(0xFFC0C0C0),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? neonColor : inactiveColor,
                  foregroundColor: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get started',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
