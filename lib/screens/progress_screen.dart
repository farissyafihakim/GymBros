import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE8FF00);

  bool _isLoading = true;

  // Chart Data
  List<double> _weeklyVolume = [0, 0, 0, 0];
  double _maxVolume = 1000; // Default max for chart scaling
  
  List<FlSpot> _strengthSpots = [];
  double _maxStrength = 100; // Default max for chart scaling
  
  List<Map<String, dynamic>> _personalRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Join workout_logs with workout_sessions to get the date of each set
      final response = await Supabase.instance.client
          .from('workout_logs')
          .select('reps, weight, exercise_name, workout_sessions!inner(started_at)')
          .eq('workout_sessions.user_id', userId);

      final logs = List<Map<String, dynamic>>.from(response);

      _processVolumeData(logs);
      _processStrengthData(logs);
      _processPersonalRecords(logs);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load progress: $e')),
        );
      }
    }
  }

  // --- DATA PROCESSING METHODS ---

  void _processVolumeData(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    List<double> volumes = [0, 0, 0, 0];
    double highestVolume = 0;

    for (var log in logs) {
      if (log['reps'] == null || log['weight'] == null) continue;
      
      final date = DateTime.parse(log['workout_sessions']['started_at']);
      final daysAgo = now.difference(date).inDays;
      
      final volume = (log['reps'] as int) * (log['weight'] as num).toDouble();

      // Group into the last 4 weeks (0-6 days ago = W4, 7-13 = W3, etc.)
      if (daysAgo < 7) {
        volumes[3] += volume;
      } else if (daysAgo < 14) {
        volumes[2] += volume;
      } else if (daysAgo < 21) {
        volumes[1] += volume;
      } else if (daysAgo < 28) {
        volumes[0] += volume;
      }
    }

    for (var v in volumes) {
      if (v > highestVolume) highestVolume = v;
    }

    _weeklyVolume = volumes;
    _maxVolume = highestVolume > 0 ? highestVolume * 1.2 : 10000; 
  }

  void _processStrengthData(List<Map<String, dynamic>> logs) {
    // For simplicity, tracking the max weight lifted per month over the last 6 months
    final now = DateTime.now();
    Map<int, double> monthlyMaxes = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double absoluteMax = 0;

    for (var log in logs) {
      if (log['weight'] == null) continue;
      
      final date = DateTime.parse(log['workout_sessions']['started_at']);
      final monthsAgo = (now.year - date.year) * 12 + now.month - date.month;
      final weight = (log['weight'] as num).toDouble();

      if (monthsAgo >= 0 && monthsAgo < 6) {
        final index = 5 - monthsAgo; // 5 is current month, 0 is 5 months ago
        if (weight > (monthlyMaxes[index] ?? 0)) {
          monthlyMaxes[index] = weight;
        }
        if (weight > absoluteMax) absoluteMax = weight;
      }
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < 6; i++) {
      if (monthlyMaxes[i]! > 0) {
        spots.add(FlSpot(i.toDouble(), monthlyMaxes[i]!));
      } else if (spots.isNotEmpty) {
        // Carry over the previous month's max if no lifts were recorded this month
        spots.add(FlSpot(i.toDouble(), spots.last.y));
      } else {
        spots.add(FlSpot(i.toDouble(), 0));
      }
    }

    _strengthSpots = spots;
    _maxStrength = absoluteMax > 0 ? absoluteMax * 1.2 : 100;
  }

  void _processPersonalRecords(List<Map<String, dynamic>> logs) {
    Map<String, Map<String, dynamic>> prMap = {};

    for (var log in logs) {
      if (log['weight'] == null) continue;
      
      final name = log['exercise_name'] as String;
      final weight = (log['weight'] as num).toDouble();
      final date = DateTime.parse(log['workout_sessions']['started_at']);

      if (!prMap.containsKey(name) || weight > prMap[name]!['weight']) {
        prMap[name] = {
          'exercise': name,
          'weight': weight,
          'date': _formatTimeAgo(date),
        };
      }
    }

    // Convert map to list and sort by heaviest weight
    _personalRecords = prMap.values.toList();
    _personalRecords.sort((a, b) => b['weight'].compareTo(a['weight']));
    
    // Only show top 5 PRs to avoid cluttering the screen
    if (_personalRecords.length > 5) {
      _personalRecords = _personalRecords.sublist(0, 5);
    }
  }

  String _formatTimeAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    return '${(days / 30).floor()} months ago';
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        title: const Text(
          'Progress 📈',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              color: accent,
              onRefresh: _fetchProgressData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Strength Graph (Max Lift)'),
                    const SizedBox(height: 16),
                    _buildStrengthChart(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Weekly Volume (kg)'),
                    const SizedBox(height: 16),
                    _buildVolumeChart(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Personal Records'),
                    const SizedBox(height: 16),
                    _personalRecords.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No PRs recorded yet. Go lift!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : _buildPersonalRecords(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStrengthChart() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _maxStrength,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == _maxStrength) return const Text('');
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // Dynamic labels relative to current month
                  final currentMonth = DateTime.now().month;
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  
                  int labelIndex = (currentMonth - 6 + value.toInt()) % 12;
                  if (labelIndex < 0) labelIndex += 12;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[labelIndex],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _strengthSpots,
              isCurved: true,
              color: accent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: accent.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeChart() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: BarChart(
        BarChartData(
          maxY: _maxVolume,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == _maxVolume) return const Text('');
                  return Text(
                    value >= 1000 
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const weeks = ['W-3', 'W-2', 'W-1', 'This Wk'];
                  if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        weeks[value.toInt()],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          barGroups: [
            _buildBarGroup(0, _weeklyVolume[0]),
            _buildBarGroup(1, _weeklyVolume[1]),
            _buildBarGroup(2, _weeklyVolume[2]),
            _buildBarGroup(3, _weeklyVolume[3]),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: accent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxVolume,
            color: const Color(0xFF2A2A2A),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalRecords() {
    return Column(
      children: _personalRecords.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: accent, size: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['exercise'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record['date'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${record['weight']} kg',
                style: const TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
