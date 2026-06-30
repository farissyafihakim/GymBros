import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'workout_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'gym_detail_screen.dart';

// this screen holds the bottom navigation bar and decides what to show
// either one of the 4 tabs, or a gym detail screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // which tab is currently selected (0 = home, 1 = workout, etc.)
  int _currentIndex = 0;

  // check is the user in the gym
  bool _isInsideGym = false;

  // the gym the user is currently checked into
  // home tab redirects to if they try to leave while inside
  Map<String, dynamic>? _activeGym;

  // the gym currently being shown in the detail screen
  // separate from _activeGym because user can view a gym's detail
  // without actually being checked into it
  Map<String, dynamic>? _viewingGym;

  @override
  void initState() {
    super.initState();
    // as soon as this screen loads, check if the user is already
    // inside a gym from a previous session (in case app closed)
    _checkIfInsideGym();
  }

  // checks supabase to see if there's an active session
  // for this user, and if so, fetches that gym's full data too
  Future<void> _checkIfInsideGym() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // this joins gym_sessions with the gyms table
      // so we get the gym's full info in one query
      final response = await Supabase.instance.client
          .from('gym_sessions')
          .select('*, gyms(*)')
          .eq('user_id', userId)
          .isFilter('exited_at', null)
          .maybeSingle();

      if (response != null) {
        // found an active session — user is inside a gym
        setState(() {
          _isInsideGym = true;
          _activeGym = response['gyms'];
        });
      } else {
        // no active session — user is not inside any gym
        setState(() {
          _isInsideGym = false;
          _activeGym = null;
        });
      }
    } catch (e) {
      print('Check session error: $e');
    }
  }

  // called by GymDetailScreen whenever the user enters or exits a gym
  // this keeps MainScreen updated so the bottom nav can react accordingly
  void _onGymStatusChanged(bool isInside, [Map<String, dynamic>? gym]) {
    setState(() {
      _isInsideGym = isInside;
      // only keep the gym if entering, clear it if exiting
      _activeGym = isInside ? gym : null;
    });
  }

  // opens a gym's detail screen inside the body
  // without losing the bottom navigation bar
  void _openGymDetail(Map<String, dynamic> gym) {
    setState(() {
      _viewingGym = gym;
    });
  }

  // closes the gym detail screen and goes back to whichever tab was active
  void _closeGymDetail() {
    setState(() {
      _viewingGym = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // if we're currently viewing a gym, show its detail screen
      // otherwise show whichever tab is selected
      body: _viewingGym != null
          ? GymDetailScreen(
              gym: _viewingGym!,
              onGymStatusChanged: _onGymStatusChanged,
              onBack: _closeGymDetail,
            )
          // IndexedStack keeps all 4 tabs alive in memory at once
          // so switching tabs doesn't reset their state
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
          // if user taps Home while inside a gym, don't show the gym list —
          // redirect them straight back to the gym they're checked into
          if (index == 0 && _isInsideGym && _activeGym != null) {
            _openGymDetail(_activeGym!);
            return;
          }
          setState(() {
            _currentIndex = index;
            // make sure leaving to another tab clears any gym detail view
            _viewingGym = null;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              // home icon turns red as a visual warning when locked
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