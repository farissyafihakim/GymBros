import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'workout_log_screen.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  static const bg = Color(0xFF0D0D0D);
  static const card = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE8FF00);

  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      final response = await Supabase.instance.client
          .from('workout_templates')
          .select()
          .order('is_builtin', ascending: false);

      setState(() {
        _templates = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load templates: $e')));
      }
    }
  }

  void _openLogScreen({Map<String, dynamic>? template}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutLogScreen(template: template)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Choose Workout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              color: accent,
              onRefresh: _fetchTemplates,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TemplateCard(
                    title: 'Freeform',
                    subtitle: 'Log without a template',
                    icon: Icons.edit_note,
                    onTap: () => _openLogScreen(),
                  ),
                  const SizedBox(height: 12),
                  ..._templates.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateCard(
                        title: t['name'] ?? 'Unnamed',
                        subtitle: t['category'] ?? '',
                        icon: Icons.fitness_center,
                        onTap: () => _openLogScreen(template: t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const card = Color(0xFF1A1A1A);
  static const accent = Color(0xFFE8FF00);

  const _TemplateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
