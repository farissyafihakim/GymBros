import 'package:GymBros/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //make sure flutter engine is ready before start

  // connect app to supabase using url and anonkey
  await Supabase.initialize(
    url:'https://hfbqutctxpkpzrqqeiik.supabase.co', 
    anonKey:'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmYnF1dGN0eHBrcHpycXFlaWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MDk3MTksImV4cCI6MjA5Njk4NTcxOX0.mMB3a6aRG3o6V9Qsa_ttDG9bIzwPpWHQHfEW1hkX-Zc',
  );

  //this launch app and put myApp on the screen
  runApp(const GymBros());
}

class GymBros extends StatelessWidget{
  const GymBros({super.key});

  @override
  Widget build(BuildContext context){

    //checks if user already logged in.  
    //If the user logged in before and didn't log out : session = value if not = null
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title : "GymBros",
      debugShowCheckedModeBanner : false,
      
      //check if there a session go to home screen
      //if no session go to login screen
      home: session != null ? const MainScreen() : const LoginScreen(),
    );
  }
}