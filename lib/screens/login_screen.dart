import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // controller to read email and passsword 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; 
  bool _obsecurePassword = true;

  //login button function
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      //supabase checks the email and password
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(), // .trim() to removes accident spaces
        password: _passwordController.text.trim(),
      );

      //mounted checks the screen is still active before navigate
      //in case user left screen while waiting for supabase
      if (mounted) {
        //push replacement removes Login page from history
        // user cannot press back button to return to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      //lofin fail shows error message pop up
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    //get the real screen height of the device
    //to make it responsive
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      //safeArea to keeps content away from notches, status bar
      body: SafeArea(
        //LayoutBuilder gives the real available space
        child: LayoutBuilder(
          builder: (context, constraints) {
            //SingleChildScrollView makes the screen scrollable
            //avoid overflow error
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //app title
                      Text(
                        'GymBros 💪',
                        style: TextStyle(
                          color: Colors.white,
                          //font size 4% of screen height
                          fontSize: screenHeight * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //spacing below title
                      SizedBox(height: screenHeight * 0.08),
                      //email input field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email'),
                      ),
                      const SizedBox(height: 16),
                      //password input field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obsecurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obsecurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obsecurePassword = !_obsecurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      //login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8FF00),
                            foregroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text('Login',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(color: Colors.grey),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
    );
  }
}