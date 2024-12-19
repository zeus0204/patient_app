import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Store the user data in SharedPreferences
  static Future<void> saveUserSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  // Get the user session (email in this case)
  static Future<String?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // Clear the session data (logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userEmail');
  }
}
