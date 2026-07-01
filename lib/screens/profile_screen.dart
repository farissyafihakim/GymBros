import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:GymBros/screens/login_screen.dart';
import 'package:GymBros/screens/subscription_screen.dart';
import 'package:GymBros/screens/editprofile_screen.dart';
import 'package:GymBros/screens/fitness_goals_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _displayName {
    final meta = _user?.userMetadata;
    if (meta != null) {
      final name = meta['full_name'] ?? meta['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }
    return _user?.email?.split('@').first ?? 'You';
  }

  String get _email => _user?.email ?? '';

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return _displayName.isNotEmpty
        ? _displayName
              .substring(0, _displayName.length.clamp(0, 2))
              .toUpperCase()
        : '?';
  }

  bool _loadingWorkouts = true;
  Set<int> _activeDaysThisMonth = {};
  int _streakDays = 0;
  int _monthlyCount = 0;
  double _monthlyHours = 0;
  int _totalWorkouts = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _subscribeRealtime() {
    final userId = _user?.id;
    if (userId == null) return;

    _channel = Supabase.instance.client
        .channel('workout_sessions_profile')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'workout_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _fetchWorkoutData(silent: true),
        )
        .subscribe();
  }

  Future<void> _fetchWorkoutData({bool silent = false}) async {
    final userId = _user?.id;
    if (userId == null) return;

    if (!silent && mounted) setState(() => _loadingWorkouts = true);

    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);

    try {
      final response = await Supabase.instance.client
          .from('workout_sessions')
          .select('started_at, ended_at')
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      final rows = response as List;

      final completedRows = rows.where((row) => row['ended_at'] != null);

      final allDates = <DateTime>{};
      final activeDaysThisMonth = <int>{};
      double monthlyMinutes = 0;
      int totalCompleted = 0;

      for (final row in completedRows) {
        final started = DateTime.parse(row['started_at']).toLocal();
        final ended = DateTime.parse(row['ended_at']).toLocal();
        final dateOnly = DateTime(started.year, started.month, started.day);
        allDates.add(dateOnly);
        totalCompleted++;

        if (started.year == now.year && started.month == now.month) {
          activeDaysThisMonth.add(started.day);

          final duration = ended.difference(started);
          if (duration.inMinutes > 0) {
            monthlyMinutes += duration.inMinutes;
          }
        }
      }

      int streak = 0;
      DateTime check = DateTime(now.year, now.month, now.day);
      while (allDates.contains(check)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }

      if (mounted) {
        setState(() {
          _activeDaysThisMonth = activeDaysThisMonth;
          _monthlyCount = activeDaysThisMonth.length;
          _monthlyHours = monthlyMinutes / 60;
          _streakDays = streak;
          _totalWorkouts = totalCompleted;
          _loadingWorkouts = false;
        });
      }
    } catch (e) {
      debugPrint('Workout data fetch error: $e');
      if (mounted) setState(() => _loadingWorkouts = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              displayName: _displayName,
              email: _email,
              initials: _initials,
            ),
          ),
          SliverToBoxAdapter(
            child: _StatsStrip(
              loading: _loadingWorkouts,
              totalWorkouts: _totalWorkouts,
              streakDays: _streakDays,
              monthlyHours: _monthlyHours,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _SectionLabel(label: 'MEMBERSHIP')),
          SliverToBoxAdapter(child: _MembershipCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _SectionLabel(label: 'FITNESS GOALS')),
          SliverToBoxAdapter(
            child: FitnessGoalsWidget(
              loading: false,
              activeDaysThisMonth: {},
              streakDays: 0,
              monthlyCount: 0,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _SectionLabel(label: 'ACCOUNT')),
          SliverToBoxAdapter(child: _AccountSettings(onLogout: _logout)),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String initials;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC6F135), Color(0xFF8BB820)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0D0D0D),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFFC6F135),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6F135),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: Color(0xFF0D0D0D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              color: Color(0xFFF0F0F0),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PillTag(icon: Icons.location_on_outlined, label: 'Kuala Lumpur'),
              const SizedBox(width: 8),
              _PillTag(
                icon: Icons.calendar_today_outlined,
                label: 'Since Jan 2024',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF7A7A7A)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final bool loading;
  final int totalWorkouts;
  final int streakDays;
  final double monthlyHours;

  const _StatsStrip({
    required this.loading,
    required this.totalWorkouts,
    required this.streakDays,
    required this.monthlyHours,
  });

  String get _hoursLabel {
    return '2h';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: loading
          ? const SizedBox(
              height: 46,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFC6F135),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                _StatItem(value: '$totalWorkouts', label: 'Workouts'),
                _StatDivider(),
                _StatItem(value: '$streakDays', label: 'Streak'),
                _StatDivider(),
                _StatItem(value: _hoursLabel, label: 'This Month'),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC6F135),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A6A6A),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFF242424));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBERSHIP CARD
// ─────────────────────────────────────────────────────────────────────────────

class _MembershipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2000), Color(0xFF141400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF2E3D00)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6F135),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFF0D0D0D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Elite Membership',
                style: TextStyle(
                  color: Color(0xFFF0F0F0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFC6F135),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MembershipDetail(label: 'Renews', value: 'Dec 15, 2026'),
              const SizedBox(width: 24),
              _MembershipDetail(label: 'Billing', value: 'Monthly'),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Progress to Champion',
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '68%',
                    style: TextStyle(
                      color: Color(0xFFC6F135),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF2A2A1A),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFC6F135)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E2800),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF3A5000)),
                ),
              ),
              child: const Text(
                'Manage Membership',
                style: TextStyle(
                  color: Color(0xFFC6F135),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipDetail extends StatelessWidget {
  final String label;
  final String value;
  const _MembershipDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5A5A5A),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFD0D0D0),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FITNESS GOALS WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class FitnessGoalsWidget extends StatefulWidget {
  final bool loading;
  final Set<int> activeDaysThisMonth;
  final int streakDays;
  final int monthlyCount;

  const FitnessGoalsWidget({
    super.key,
    required this.loading,
    required this.activeDaysThisMonth,
    required this.streakDays,
    required this.monthlyCount,
  });

  @override
  State<FitnessGoalsWidget> createState() => FitnessGoalsWidgetState();
}

class FitnessGoalsWidgetState extends State<FitnessGoalsWidget> {
  final supabase = Supabase.instance.client;

  List<_GoalData> goals = [];
  bool loadingGoals = true;

  @override
  void initState() {
    super.initState();
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('fitness_goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      goals = (data as List).map((e) => _GoalData.fromMap(e)).toList();

      loadingGoals = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (loadingGoals)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            for (final goal in goals) ...[
              _GoalTile(data: goal, onTap: () {}),
              const SizedBox(height: 10),
            ],

          const SizedBox(height: 10),

          _WorkoutCalendar(
            loading: widget.loading,
            activeDays: widget.activeDaysThisMonth,
            streakDays: widget.streakDays,
            monthlyCount: widget.monthlyCount,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _GoalData {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;

  _GoalData({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  factory _GoalData.fromMap(Map<String, dynamic> data) {
    return _GoalData(
      id: data['id'].toString(),
      icon: Icons.fitness_center_rounded,
      title: data['title'] ?? '',
      subtitle: data['target_value'] ?? '',
      progress: (data['progress'] ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL TILE
// ─────────────────────────────────────────────────────────────────────────────

class _GoalTile extends StatelessWidget {
  final _GoalData data;
  final VoidCallback onTap;

  const _GoalTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FitnessGoalsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: const Color(0xFFC6F135), size: 20),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6A6A6A),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF242424),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFC6F135),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(data.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF3A3A3A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// WORKOUT CALENDAR
// ─────────────────────────────────────────────────────────────────────────────

class _WorkoutCalendar extends StatelessWidget {
  final bool loading;
  final Set<int> activeDays;
  final int streakDays;
  final int monthlyCount;

  const _WorkoutCalendar({
    required this.loading,
    required this.activeDays,
    required this.streakDays,
    required this.monthlyCount,
  });

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_monthName(now.month)} ${now.year}';
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final startOffset = DateTime(now.year, now.month, 1).weekday - 1;
    final streakLabel = streakDays >= 7
        ? '${(streakDays / 7).floor()} Week${(streakDays / 7).floor() > 1 ? "s" : ""}'
        : '$streakDays Days';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: loading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFC6F135),
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        color: Color(0xFFF0F0F0),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2E2E2E)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            color: Color(0xFFF0F0F0),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: Color(0xFFF0F0F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _CalStat(label: 'Your Streak', value: streakLabel),
                    const SizedBox(width: 32),
                    _CalStat(
                      label: 'Streak Activities',
                      value: '$monthlyCount',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    _DayHeader('M'),
                    _DayHeader('T'),
                    _DayHeader('W'),
                    _DayHeader('T'),
                    _DayHeader('F'),
                    _DayHeader('S'),
                    _DayHeader('S'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildGrid(daysInMonth, startOffset, now.day),
              ],
            ),
    );
  }

  Widget _buildGrid(int daysInMonth, int startOffset, int today) {
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (_, index) {
        final day = index - startOffset + 1;
        if (index < startOffset || day > daysInMonth) {
          return const SizedBox();
        }
        final isActive = activeDays.contains(day);
        final isToday = day == today;
        final isPast = day < today;

        return _DayCell(
          day: day,
          isActive: isActive,
          isToday: isToday,
          isPast: isPast,
        );
      },
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  const _CalStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6A6A6A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF0F0F0),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isActive;
  final bool isToday;
  final bool isPast;
  const _DayCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    if (isActive) {
      bgColor = Colors.white;
      textColor = Colors.transparent;
    } else if (isToday) {
      bgColor = Colors.transparent;
      textColor = const Color(0xFFF0F0F0);
      border = Border.all(color: const Color(0xFFF0F0F0), width: 1.5);
    } else if (isPast) {
      bgColor = const Color(0xFF1E1E1E);
      textColor = const Color(0xFFB0B0B0);
    } else {
      bgColor = const Color(0xFF1A1A1A);
      textColor = const Color(0xFF5A5A5A);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: isActive
                ? const Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF0D0D0D),
                    size: 16,
                  )
                : Text(
                    '$day',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT SETTINGS
// ─────────────────────────────────────────────────────────────────────────────

class _AccountSettings extends StatelessWidget {
  final VoidCallback onLogout;
  const _AccountSettings({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            isFirst: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _SettingsDivider(),
          _SettingsRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
          ),
          _SettingsDivider(),
          _SettingsRow(
            icon: Icons.lock_outline_rounded,
            label: 'Privacy & Security',
          ),
          _SettingsDivider(),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
          ),
          _SettingsDivider(),
          _SettingsRow(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            isDestructive: true,
            isLast: true,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onPressed;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.isFirst = false,
    this.isLast = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFE05555)
        : const Color(0xFFD0D0D0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF3A3A3A),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 50,
      endIndent: 0,
      color: Color(0xFF1E1E1E),
    );
  }
}
