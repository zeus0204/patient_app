import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:patient_app/data/db_helper.dart';
import 'package:patient_app/data/model/User.dart';
import 'package:patient_app/data/session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/sign_in.dart';
import '../Home/Profile/profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? _user;
  bool _isLoading = true;
  // Profile data
  Map<String, String> profile = {
    'name':  '',
    'position': 'Pediatrician',
  };
  void initState() {  
    super.initState();  
    _loadUserData();  
  }  

  Future<void> _loadUserData() async {  
    try {  
      String? email = await SessionManager.getUserSession(); 
      
      if (email != null) {  
        Map<String, dynamic>? userData = await DBHelper().getPatientsByEmail(email);
        
        if (userData != null) {  
          setState(() {  
            _user = User.fromMap(userData);  
          });  
        }  
      }  
    } catch (e) {  
      // It's good practice to handle the error, e.g. log it or show feedback  
    } finally {  
      setState(() {
        profile['name'] = _user!.fullName!;  
        _isLoading = false;  
      });  
    }  
  }
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken'); // Remove the stored token

    // Show a snackbar to indicate logout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have logged out')),
    );

    // Navigate to SignIn page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Signin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading  
          ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set loading indicator color to white
                    ),
                  )  
          : Padding(
        padding: const EdgeInsets.only(top: 50.0, right: 30, left: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings header
            Center(
              child: Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromRGBO(33, 158, 80, 1),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Info Section with Divider
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      AssetImage('assets/images/avatar.png'), // Replace with your image asset
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, ${profile['name']}', // Using profile data
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(33, 158, 80, 1),
                      ),
                    ),
                    Text(
                      profile['position']!, // Using profile data
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey[300]), // Divider after user info
            const SizedBox(height: 10),

            // Settings Options
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SettingsOption(
                    icon: Icons.edit,
                    text: 'Edit Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()), // Navigate to Profile page
                      );
                    },
                  ),
                  SettingsOption(
                    icon: Icons.lock,
                    text: 'Change Password',
                    onTap: () {
                      // Handle Change Password action
                    },
                  ),
                  Divider(color: Colors.grey[300]), // Divider between options
                  SettingsOption(
                    icon: Icons.document_scanner,
                    text: 'Terms & Condition',
                    onTap: () {
                      // Handle Terms & Condition action
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Center(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Background color of the button
                        borderRadius: BorderRadius.circular(8), // Making borders rounded
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26, // Color of the shadow
                            blurRadius: 8, // Softness of the shadow
                            spreadRadius: 1, // How much the shadow spreads
                            offset: const Offset(0, 4), // Position of the shadow
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Button background color
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Button padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Matching the container's border radius
                            side: const BorderSide(color: Colors.white), // Border color
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
                        ), // Set text color to red
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Spacer between Logout button and footer

            // Footer
            Center(
              child: Text(
                '© 2024 Health+ • v2.1.6. All rights reserved.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const SettingsOption({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            // Container for icon with specified background color
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(226, 248, 227, 1), // Background color for the icon
                borderRadius: BorderRadius.circular(8), // Rounded corners for the background
              ),
              padding: const EdgeInsets.all(8.0), // Add padding around the icon
              child: Icon(icon, color: const Color.fromRGBO(33, 158, 80, 1)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color.fromRGBO(10, 62, 29, 1),
                ), // Setting text color
              ),
            ),
            Transform.rotate(
              angle: 0, // Correcting the arrow icon orientation
              child: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
