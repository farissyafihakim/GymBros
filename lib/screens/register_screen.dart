import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

// RegisterScreen is a StatefulWidget because it needs to manage
// changing data like loading state and text input
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // controllers read whatever the user types into each field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // tracks whether registration is currently in progress
  // used to show a spinner and disable the button while waiting
  bool _isLoading = false;

  // this function runs when the user taps the Register button
  Future<void> _register() async {
    // turn on loading state — disables button, shows spinner
    setState(() => _isLoading = true);

    try {
      // create a new user account in supabase auth
      // .trim() removes accidental spaces before/after the text
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        // data stores extra info alongside the account
        // supabase saves this inside raw_user_meta_data
        data: {'full_name': _nameController.text.trim()},
      );

      // mounted checks the screen is still active before navigating
      // (in case the user left the screen while waiting for supabase)
      if (mounted) {
        // show a small popup confirming success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please login.')),
        );

        // pushReplacement removes RegisterScreen from history
        // so the user can't press back to return to it
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      // if registration fails (email already used, weak password, etc.)
      // show the error message in a small popup at the bottom
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register failed: $e')),
        );
      }
    }

    // turn off loading state whether registration succeeded or failed
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // get the real screen height of the device
    // used to scale spacing properly on different phone sizes
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // dark background

      // appBar only has a back button, no title
      // transparent background blends with the screen behind it
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white), // white back arrow
      ),

      // SafeArea keeps content away from notches and curved edges
      body: SafeArea(
        // LayoutBuilder gives us the real available space (constraints)
        child: LayoutBuilder(
          builder: (context, constraints) {
            // SingleChildScrollView makes the form scrollable
            // prevents overflow errors when the keyboard pops up
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              // ConstrainedBox + IntrinsicHeight let the Column
              // still fill the full screen height even while scrollable
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    // centers all children vertically when there's extra space
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // screen title
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenHeight * 0.035, // scales with screen size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05), // spacing below title

                      // full name input field
                      TextField(
                        controller: _nameController, // reads what user types
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Full Name'), // styling from function below
                      ),
                      const SizedBox(height: 16),

                      // email input field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email'),
                      ),
                      const SizedBox(height: 16),

                      // password input field
                      TextField(
                        controller: _passwordController,
                        obscureText: true, // hides password characters with dots
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Password'),
                      ),
                      const SizedBox(height: 24),

                      // register button
                      SizedBox(
                        width: double.infinity, // stretches full width
                        child: ElevatedButton(
                          // disables button (greyed out, untappable) while loading
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8FF00), // yellow
                            foregroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          // shows spinner while loading, otherwise shows text
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text('Register',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // reusable styling for all three text fields
  // avoids repeating the same decoration code three times
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label, // floating label text e.g "Full Name"
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1A1A), // dark grey field background
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)), // border color when not focused
      ),
    );
  }
}