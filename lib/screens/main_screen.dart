import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'gym_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isInsideGym = false;
  Map<String, dynamic>? _activeGym;
  Map<String, dynamic>? _viewingGym;

  @override
  void initState() {
    super.initState();
    _checkIfInsideGym();
  }

  Future<void> _checkIfInsideGym() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('gym_sessions')
          .select('*, gyms(*)')
          .eq('user_id', userId)
          .isFilter('exited_at', null)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isInsideGym = true;
          _activeGym = response['gyms'];
        });
      } else {
        setState(() {
          _isInsideGym = false;
          _activeGym = null;
        });
      }
    } catch (e) {
      print('Check session error: $e');
    }
  }

  void _onGymStatusChanged(bool isInside, [Map<String, dynamic>? gym]) {
    setState(() {
      _isInsideGym = isInside;
      _activeGym = isInside ? gym : null;
    });
  }

  void _openGymDetail(Map<String, dynamic> gym) {
    setState(() {
      _viewingGym = gym;
    });
  }

  void _closeGymDetail() {
    setState(() {
      _viewingGym = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _viewingGym != null
          ? GymDetailScreen(
              gym: _viewingGym!,
              onGymStatusChanged: _onGymStatusChanged,
              onBack: _closeGymDetail,
            )
          : IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onGymStatusChanged: _onGymStatusChanged,
                  onGymTapped: _openGymDetail,
                ),
                const WorkoutScreen(),
                const ProgressScreen(),
                const ProfileScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFE8FF00),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0 && _isInsideGym && _activeGym != null) {
            _openGymDetail(_activeGym!);
            return;
          }
          setState(() {
            _currentIndex = index;
            _viewingGym = null;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: _isInsideGym ? Colors.red : Colors.grey,
            ),
            activeIcon: Icon(
              Icons.home,
              color: _isInsideGym ? Colors.red : const Color(0xFFE8FF00),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}