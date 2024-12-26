import 'package:patient_app/data/db_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SignIn.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Signup extends StatefulWidget {  
  const Signup({super.key});  

  @override  
  State<Signup> createState() => _SignupState();  
}  

class _SignupState extends State<Signup> {  
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();
  final TextEditingController _passwordcontroller = TextEditingController();
  String? _fullName;
  String? _phoneNumber;
  String? _email;
  String? _password;

  Future<void> _submitForm() async {
    if (_signupFormKey.currentState!.validate()) {
      _signupFormKey.currentState!.save();
      try {
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email!,
            password: _password!,
          );
          final patientData = {
            'fullName': _fullName,
            'email': _email,
            'password': _password,
            'phoneNumber': _phoneNumber,
          };

          await DBHelper().insertPatients(patientData);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User signed up successfully!')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Signin()),
          );
      } on FirebaseAuthException catch (e) {
          debugPrint("FirebaseAuthException: ${e.message}");
          String errorMessage;
          if (e.code == 'email-already-in-use') {
            errorMessage = 'This email is already in use.';
          } else if (e.code == 'weak-password') {
            errorMessage = 'The password provided is too weak.';
          } else {
            errorMessage = 'An error occurred: ${e.message ?? 'Unknown error'}';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
          debugPrint("Unexpected error: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unexpected error occurred. Try again.")));
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
              key: _signupFormKey,
              child: Column(  
                mainAxisAlignment: MainAxisAlignment.center,  
                children: [  
                  Image.asset(  
                    'assets/images/heart.png', // Replace with your heart icon path  
                    width: 94,  
                    height: 90,  
                  ),  
                  Text(  
                    'Get Started',  
                    style: GoogleFonts.poppins(  
                      fontSize: 20,
                      color: const Color.fromRGBO(10, 62, 29, 1),
                      fontWeight: FontWeight.bold,
                    ),  
                  ),
                  Text(  
                    'Create account as',  
                    style: GoogleFonts.poppins(  
                      fontSize: 14,
                      color: const Color.fromRGBO(10, 62, 29, 1),
                    ),  
                  ),
                  const SizedBox(height: 80),  
                  // Role Selection as Radio Buttons  
                  // Text Fields  
                  TextFormField(  
                    decoration: InputDecoration(  
                      labelText: 'Full name',  
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
                    onSaved: (value) => _fullName = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                    style: GoogleFonts.poppins(color: Colors.black), // Change text color here  
                  ),  
                  const SizedBox(height: 10),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phoneNumber = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input your phone number';
                      }
                      return null;
                    },
                    decoration: InputDecoration(  
                      labelText: 'Phone number',  
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
                  ),  
                  const SizedBox(height: 10),
                  TextFormField(
                    onSaved: (value) => _email = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input your User ID';
                      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) 
                      {
                        return 'Please enter a valid email';
                      }
                      return null;
                    }, 
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
                  ),  
                  const SizedBox(height: 10),  
                  TextFormField(
                    onSaved: (value) => _password = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please input your passcode';
                      }
                      else if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    controller: _passwordcontroller,
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
                  ),
                  const SizedBox(height: 10),  
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != _passwordcontroller.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(  
                      labelText: 'Confirm Passcode',  
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
                      onPressed: _submitForm,  
                      child: Text('Sign Up', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400)),  
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
                    'Sign Up with',  
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
                          text: "Already have an account? ",  
                          style: GoogleFonts.poppins(  
                            color: const Color.fromRGBO(10, 62, 29, 1), 
                            fontSize: 16, // You can adjust the size as needed  
                          ),  
                        ),  
                        TextSpan(  
                          text: "Login",  
                          style: GoogleFonts.poppins(  
                            color: const Color.fromRGBO(33, 158, 80, 1), 
                            fontSize: 16, // Same size as above  
                            fontWeight: FontWeight.bold, // Make it bold if needed  
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Navigate to the SignUp page when the text is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Signin()),
                            );
                          },  
                        ),  
                      ],  
                    ),  
                  ),
                ],  
              ),
            ),  
          ),  
        ),  
      ),  
    );  
  }  
}