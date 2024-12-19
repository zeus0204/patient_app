import 'dart:io';
import 'package:flutter/material.dart';
import 'package:patient_app/Pages/Home/Profile/EditProfile.dart';  
import '../../../data/db_helper.dart';  
import '../../../data/session.dart';  
import '../../../data/model/User.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {  
  const ProfilePage({super.key});  

  @override  
  State<ProfilePage> createState() => _ProfilePageState();  
}  

class _ProfilePageState extends State<ProfilePage> {  
  User? _user; // Store user details  
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;  

  @override  
  void initState() {  
    super.initState();  
    _loadUserData();  
  }  

  Future<void> _loadUserData() async {  
    try {  
      String? email = await SessionManager.getUserSession();  
      if (email != null) {  
        Map<String, dynamic>? userData = await DBHelper().getUserByEmail(email);  
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
        _isLoading = false;  
      });  
    }  
  }

  Future<void> _pickImage() async {  
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);  
    if (pickedFile != null) {  
      setState(() {  
        _imagePath = pickedFile.path;  
      });  
    }  
  } 

  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Colors.white,
      body: _isLoading  
          ? const Center(child: CircularProgressIndicator())  
          : _user == null  
              ? const Center(child: Text("No user data found"))  
              : Padding(  
                  padding: const EdgeInsets.all(16.0),  
                  child: Column(  
                    children: [  
                      const SizedBox(height: 30),
                      const Text(  
                        'Patient',  
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.w700
                          ),  
                      ), 
                      Center(  
                        child: Stack(  
                          children: [ 
                            Container(  
                              width: 127, 
                              height: 126, 
                              decoration: BoxDecoration(  
                                shape: BoxShape.circle,  
                                image: DecorationImage(  
                                  image: _imagePath != null  
                                      ? FileImage(File(_imagePath!))  
                                      : const AssetImage('assets/images/avatar.png') as ImageProvider,  
                                  fit: BoxFit.cover, 
                                ),  
                              ),  
                            ),
                            Positioned(  
                              bottom: 0,  
                              right: 0,  
                              child: IconButton(  
                                icon: const Icon(Icons.edit, color: Colors.white),  
                                onPressed: _pickImage,  
                              ),  
                            ),  
                          ],  
                        ),  
                      ),  
                      const SizedBox(height: 30),  
                      Column(  
                        children: [
                          const Text(  
                            'Full Name',  
                            style: TextStyle(color: Colors.grey),  
                          ),
                          Text(  
                            _user!.fullName ?? 'Full Name',  
                            style: const TextStyle(  
                              fontSize: 18,  
                              fontWeight: FontWeight.bold,  
                            ),  
                          ),  
                          const SizedBox(height: 4),
                          const Text(  
                            'E-mail Address',  
                            style: TextStyle(color: Colors.grey),  
                          ), 
                          Text(  
                            _user!.email ?? 'E-mail Address',  
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),  
                          ),  
                          const SizedBox(height: 4),
                          const Text(  
                            'Phone Number',  
                            style: TextStyle(color: Colors.grey),  
                          ), 
                          Text(  
                            _user!.phoneNumber ?? 'Phone Number',  
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),  
                          ),  
                        ],  
                      ),  
                      Center(  
                        child: TextButton(  
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfile()),
                            ).then((result) {
                              if(result == true) {
                                _loadUserData();
                              }
                            });
                          },  
                          child: const Text(  
                            'Edit Details',  
                            style: TextStyle(color: Colors.green),  
                          ),  
                        ),  
                      ),
                        
                    ],  
                  ),  
                ),  
    );  
  }  
}
