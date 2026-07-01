import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Make sure to run: flutter pub add fl_chart

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Progress 📈',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. STRENGTH GRAPH SECTION (Line Chart)
            _buildSectionTitle('Strength Graph (1RM)'),
            const SizedBox(height: 16),
            _buildStrengthChart(),
            const SizedBox(height: 32),

            // 2. VOLUME GRAPH SECTION (Bar Chart)
            _buildSectionTitle('Weekly Volume (kg)'),
            const SizedBox(height: 16),
            _buildVolumeChart(),
            const SizedBox(height: 32),

            // 3. PERSONAL RECORDS SECTION
            _buildSectionTitle('Personal Records'),
            const SizedBox(height: 16),
            _buildPersonalRecords(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Reusable widget for section titles
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

  // --- STRENGTH LINE CHART ---
  Widget _buildStrengthChart() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false), // Clean look without grid lines
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
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
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        months[value.toInt()],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              // Fake stats for Deadlift 1RM progression over 6 months
              spots: const [
                FlSpot(0, 140),
                FlSpot(1, 145),
                FlSpot(2, 150),
                FlSpot(3, 165),
                FlSpot(4, 170),
                FlSpot(5, 180),
              ],
              isCurved: true,
              color: const Color(0xFFE8FF00),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true), // Show dots on data points
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE8FF00).withOpacity(0.15), // Faded yellow gradient below line
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VOLUME BAR CHART ---
  Widget _buildVolumeChart() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: BarChart(
        BarChartData(
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
                  if (value == 0) return const Text('');
                  return Text(
                    '${(value / 1000).toStringAsFixed(1)}k',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const weeks = ['W1', 'W2', 'W3', 'W4'];
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
            // Fake stats for Weekly Volume (Total weight lifted)
            _buildBarGroup(0, 12500),
            _buildBarGroup(1, 14200),
            _buildBarGroup(2, 13800),
            _buildBarGroup(3, 16500),
          ],
        ),
      ),
    );
  }

  // Helper function to build individual bars for the volume chart
  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFE8FF00),
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20000, // Max volume background bar
            color: const Color(0xFF2A2A2A),
          ),
        ),
      ],
    );
  }

  // --- PERSONAL RECORDS ---
  Widget _buildPersonalRecords() {
    final records = [
      {'exercise': 'Deadlift', 'weight': '180 kg', 'date': '2 days ago'},
      {'exercise': 'Squat', 'weight': '140 kg', 'date': '1 week ago'},
      {'exercise': 'Bench Press', 'weight': '100 kg', 'date': '2 weeks ago'},
      {'exercise': 'Overhead Press', 'weight': '65 kg', 'date': '1 month ago'},
    ];

    return Column(
      children: records.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFE8FF00), size: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['exercise']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record['date']!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                record['weight']!,
                style: const TextStyle(
                  color: Color(0xFFE8FF00),
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
