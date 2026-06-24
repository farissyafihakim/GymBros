import 'package:flutter/material.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Text('Workout — coming soon',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}