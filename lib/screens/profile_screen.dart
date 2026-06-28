import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'register_card_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // fetch the logged-in user's profile data from supabase
  Future<void> _fetchProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        _profile = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Fetch profile error: $e');
    }
  }

  // logs the user out and clears all navigation history
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8FF00)),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // avatar placeholder
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF1A1A1A),
                    child: Icon(Icons.person, color: Colors.grey, size: 40),
                  ),
                  const SizedBox(height: 16),

                  // user's full name
                  Text(
                    _profile?['full_name'] ?? 'No name set',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // user's email
                  Text(
                    _profile?['email'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // nfc card registration status
                  Text(
                    _profile?['nfc_card_id'] != null
                        ? '✅ NFC card registered'
                        : '⚠️ No NFC card registered',
                    style: TextStyle(
                      color: _profile?['nfc_card_id'] != null
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // button to register or re-register nfc card
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterCardScreen()),
                        );
                        // refresh profile after returning
                        _fetchProfile();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE8FF00),
                        side: const BorderSide(color: Color(0xFFE8FF00)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Register NFC Card'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}