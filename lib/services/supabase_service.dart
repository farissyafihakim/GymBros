// pacakges to connect with supabase
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  //declare the supabase url and key
  static const String supabaseUrl = 'https://hfbqutctxpkpzrqqeiik.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmYnF1dGN0eHBrcHpycXFlaWlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MDk3MTksImV4cCI6MjA5Njk4NTcxOX0.mMB3a6aRG3o6V9Qsa_ttDG9bIzwPpWHQHfEW1hkX-Zc';

  //initiliaze supabase when app starts
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  //gives access to the database
  static SupabaseClient get client => Supabase.instance.client;
}