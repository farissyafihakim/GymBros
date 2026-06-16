// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'gym_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{

  List<Map<String, dynamic>> _gyms = [];

  bool _isLoading = true;

  @override
  void initState(){
    super.initState();
    _fetchGyms();
  }

  //async works waiting for supabase
  Future<void> _fetchGyms() async {
    try {
      final response = await Supabase.instance.client
      .from("gyms")
      .select()
      .order("name", ascending: true);

    setState((){
      _gyms = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
      });
    }catch (e){
      setState(() => _isLoading = false);
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load gyms: $e")),
        );
      }
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'GymBros 💪',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF00)))
          : _gyms.isEmpty
              ? const Center(
                  child: Text('No gyms found', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _gyms.length,
                  itemBuilder: (context, index) {
                    final gym = _gyms[index];
                    return _buildGymCard(gym);
                  },
                ),
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym) {
    final occupancy = gym['current_occupancy'] as int? ?? 0;
    final capacity = gym['max_capacity'] as int? ?? 50;
    final percentage = occupancy / capacity;

    Color occupancyColor;
    if (percentage < 0.5) {
      occupancyColor = Colors.green;
    } else if (percentage < 0.8) {
      occupancyColor = Colors.orange;
    } else {
      occupancyColor = Colors.red;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GymDetailScreen(gym: gym),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // gym image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: gym['image_url'] != null
                  ? Image.network(
                      gym['image_url'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.fitness_center, color: Colors.grey, size: 48),
                    ),
            ),
            // gym info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym['name'] ?? 'Unknown Gym',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gym['location'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // occupancy bar
                  Row(
                    children: [
                      Icon(Icons.people, color: occupancyColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$occupancy / $capacity people',
                        style: TextStyle(color: occupancyColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: occupancyColor,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}