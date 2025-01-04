import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Auth/sign_in.dart'; // Ensure the import path is correct
import '../Home/home.dart'; // Ensure the import path is correct
import '../../data/session.dart'; // Import the session manager

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPage();
}

class _LandingPage extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    // Check user authentication status after a short delay
    Future.delayed(const Duration(seconds: 1), () async {
      // Check if the user is authenticated using SessionManager
      String? userEmail = await SessionManager.getUserSession();

      // Navigate based on authentication status
      if (userEmail != null) {
        // User is authenticated, navigate to Home
        Navigator.of(context).pushReplacement(_createRoute(const Home()));
      } else {
        // User is not authenticated, navigate to Signin
        Navigator.of(context).pushReplacement(_createRoute(const Signin()));
        // Navigator.of(context).pushReplacement(_createRoute(Home()));
      }
    });
  }

  // Create a route with a fade transition
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeIn;

        // Define the animation
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var opacityAnimation = animation.drive(tween);

        // Fade transition
        return FadeTransition(
          opacity: opacityAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F3D0), // Light green background
      body: GestureDetector(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/heart.png', // Replace with your heart icon path
                      width: 94,
                      height: 90,
                    ),
                    Text(
                      'Health+',
                      style: GoogleFonts.poppins(
                        fontSize: 32, // Font size
                        fontWeight: FontWeight.bold, // Font weight
                        height: 1.5, // Line height
                        letterSpacing: -2.2, // Letter spacing
                        color: const Color.fromARGB(255, 44, 68, 34), // Text color
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
