import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Home/Home.dart';
import 'SignUp.dart';
import 'package:crypto/crypto.dart';
import '../../data/session.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Signin extends StatefulWidget {  
  const Signin({super.key});  

  @override  
  State<Signin> createState() => _SigninState();  
}  

class _SigninState extends State<Signin> {  
  // This variable keeps track of the selected role
  final GlobalKey<FormState> _signInformkey = GlobalKey<FormState>();
  String? _email;
  String? _password;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _login() async {
    if (_signInformkey.currentState!.validate()) {
      _signInformkey.currentState!.save();

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        await SessionManager.saveUserSession(_email!);
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Successfully')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()), // Replace with your home page
        );

      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        } else {
          errorMessage = 'An error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Colors.white,  
      body: Padding(  
        padding: const EdgeInsets.symmetric(horizontal: 20.0),  
        child: Center(  
          child: SingleChildScrollView(
            child: Form(
              key: _signInformkey,
              child: Column(  
                mainAxisAlignment: MainAxisAlignment.center,  
                children: [  
                  Image.asset(  
                    'assets/images/heart.png', // Replace with your heart icon path  
                    width: 94,  
                    height: 90,  
                  ),  
                  Text(  
                    'Welcome Back!',  
                    style: GoogleFonts.poppins(  
                      fontSize: 20,
                      color: const Color.fromRGBO(10, 62, 29, 1),
                      fontWeight: FontWeight.bold,
                    ),  
                  ),
                  const SizedBox(height: 80),  
                  // Text Fields  
                  TextFormField(
                    decoration: InputDecoration(  
                      labelText: 'Email',  
                      labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)), // Change label color if needed  
                      border: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0), // Use your desired border color  
                      ),  
                      focusedBorder: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10), 
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)), // Border color when focused  
                      ),  
                      enabledBorder: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10),  
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)), // Border color when not focused  
                      ),  
                      fillColor: Colors.white, // Background color of input box  
                      filled: true, // This enables the fill color  
                    ),  
                    style: GoogleFonts.poppins(color: Colors.black), // Change text color here 
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value;
                    },
                    
                  ) ,  
                  const SizedBox(height: 10),  
                  TextFormField(  
                    decoration: InputDecoration(  
                      labelText: 'Passcode',  
                      labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)), // Customize label color  
                      border: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10),  
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0), // Border color  
                      ),  
                      focusedBorder: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10),  
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)), // Border color when focused  
                      ),  
                      enabledBorder: OutlineInputBorder(  
                        borderRadius: BorderRadius.circular(10),  
                        borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)), // Border color when enabled  
                      ),  
                      fillColor: Colors.white, // Background color of the input box  
                      filled: true, // This enables the fill color  
                    ),  
                    style: GoogleFonts.poppins(color: Colors.black), // Color for the input text  
                    obscureText: true, // Makes the input text hidden, for passcode
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value;
                    },
                  ), 
                  Align(  
                    alignment: Alignment.centerRight,  
                    child: TextButton(  
                      onPressed: () {},  
                      child: Text(  
                        'Forget password?',  
                        style: GoogleFonts.poppins(color:  const Color.fromRGBO(33, 158, 80, 1)),  
                      ),
                    ),
                  ),  
                  const SizedBox(height: 20),  
                  // Login Button  
                  SizedBox(  
                    width: 200, // Set the width to 200 pixels  
                    height: 47, // Set the height to 80 pixels  
                    child: ElevatedButton(  
                      style: ElevatedButton.styleFrom(  
                        backgroundColor: const Color.fromRGBO(33, 158, 80, 1), // Login button color  
                        padding: EdgeInsets.zero, // Remove the padding to respect the height set by the Container  
                        shape: RoundedRectangleBorder(  
                          borderRadius: BorderRadius.circular(10),  
                        ),  
                      ),  
                      onPressed: _login,  
                      child: Text('Login', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400)),  
                    ),  
                  ),  
                  Column(  
                    children: [  
                      const SizedBox(height: 20),  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [  
                          const Flexible(  
                            child: SizedBox(  
                              width: 50, // Set the desired width for the left divider  
                              child: Divider(color: Colors.grey),  
                            ),  
                          ),  
                          Padding(  
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),  
                            child: Text(  
                              'or',  
                              style: GoogleFonts.poppins(color: Colors.grey),  
                            ),  
                          ),  
                          const Flexible(  
                            child: SizedBox(  
                              width: 50, // Set the desired width for the right divider  
                              child: Divider(color: Colors.grey),  
                            ),  
                          ),  
                        ],  
                      ),  
                      const SizedBox(height: 20),  
                    ],  
                  ), 
                  Text(  
                    'Sign In with',  
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color.fromRGBO(10, 62, 29, 1)),  
                  ),
                  const SizedBox(height: 20),
                  // Social Sign-In Buttons
                  Row(  
                    mainAxisAlignment: MainAxisAlignment.center,  
                    children: [  
                      IconButton(  
                        onPressed: () {},  
                        icon: Image.asset(  
                          'assets/images/apple.png',  
                          width: 21.57,
                          height: 21.57,
                        ),  
                      ),
                      const SizedBox(width: 10),  
                      IconButton(  
                        onPressed: () {},  
                        icon: Image.asset(  
                          'assets/images/facebook.png',
                          width: 21.57,
                          height: 21.57,
                        ),  
                      ),
                      const SizedBox(width: 10),  
                      IconButton(  
                        onPressed: () {},  
                        icon: Image.asset(  
                          'assets/images/google.png',  
                          width: 21.57,
                          height: 21.57,
                        ),  
                      ),  
                    ],  
                  ),
                  const SizedBox(height: 20),  
                  // Sign Up Link  
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don’t have an account? ",
                          style: GoogleFonts.poppins(
                            color: const Color.fromRGBO(10, 62, 29, 1),
                            fontSize: 16, // You can adjust the size as needed
                          ),
                        ),
                        TextSpan(
                          text: "Sign Up",
                          style: GoogleFonts.poppins(
                            color: const Color.fromRGBO(33, 158, 80, 1),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          // Make the SignUp text clickable
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to the SignUp page when the text is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Signup()),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],  
              ),
            )
          ),  
        ),  
      ),  
    );  
  }  
}