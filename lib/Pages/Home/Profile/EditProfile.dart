import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/session.dart';
import '../../../data/db_helper.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _phoneNumber;
  String? _address;
  String? _contact;
  String? _dateOfBirth;
  File? _imageFile;

  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  List<Map<String, dynamic>> _medicalHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      String? email = await SessionManager.getUserSession();
      if (email != null) {
        Map<String, dynamic>? userData = await DBHelper().getPatientsByEmail(email);
        if (userData != null) {
          Map<String, dynamic>? userInfo =
              await DBHelper().getPatientsInfoByEmail(email);

          setState(() {
            _fullName = userData['fullName'];
            _phoneNumber = userData['phoneNumber'];
            _address = userInfo?['address'];
            _contact = userInfo?['contact'];
            _dateOfBirth = userInfo?['birthday'];

            _fullNameController.text = _fullName ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
            _addressController.text = _address ?? '';
            _contactController.text = _contact ?? '';
            _dateOfBirthController.text = _dateOfBirth ?? '';
          });
          _loadMedicalHistory(email);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _loadMedicalHistory(email) async {
    try {
      final records = await DBHelper().getMedicalHistoryByEmail(email);
      setState(() {
        _medicalHistory = records;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your profile lacks medical history. Please add it.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        String? email = await SessionManager.getUserSession();
        if (email != null) {
          Map<String, dynamic>? userData = await DBHelper().getPatientsByEmail(email);
          if (userData != null) {
            await DBHelper().updatePatients(
              email: email,
              fullName: _fullName,
              phoneNumber: _phoneNumber,
            );

            await DBHelper().updatePatientsInfo(
              email: email,
              address: _address,
              contact: _contact,
              birthday: _dateOfBirth != null
                  ? DateTime.parse(_dateOfBirth!)
                  : null,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color.fromRGBO(10, 62, 29, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromRGBO(10, 62, 29, 1),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : const AssetImage('assets/images/avatar.png')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 190, 188, 190),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              color: Color.fromRGBO(10, 62, 29, 1)),
                          SizedBox(width: 8),
                          Text(
                            'Change Profile Picture',
                            style: TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Full Name', _fullNameController, (value) {
                _fullName = value;
              }),
              _buildTextField('Phone Number', _phoneNumberController, (value) {
                _phoneNumber = value;
              }),
              _buildTextField('Address', _addressController, (value) {
                _address = value;
              }),
              _buildTextField('Contact', _contactController, (value) {
                _contact = value;
              }),
              _buildDatePickerField('Date of Birth', _dateOfBirthController),
              const SizedBox(height: 20),
              _buildMedicalHistoryList(),
              Center(  
                  child: TextButton(  
                    onPressed: () {
                      _showAddMedicalHistoryModal(context);
                    },  
                    child: const Text(  
                      'Add Section',  
                      style: TextStyle(color: Colors.green),  
                    ),  
                  ),  
                ),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 158, 80, 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
        decoration: InputDecoration(  
          labelText: label,  
          labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
          border: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
          ),  
          focusedBorder: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
          ),  
          enabledBorder: OutlineInputBorder(  
            borderRadius: BorderRadius.circular(10),  
            borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
          ),  
                    fillColor: Colors.white,  
          filled: true,  
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            String formattedDate = "${pickedDate.toLocal()}".split(' ')[0];
            setState(() {
              controller.text = formattedDate;
              _dateOfBirth = formattedDate;
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMedicalHistoryList() {
    if (_medicalHistory.isEmpty) {
      return const Center(child: Text('No medical history available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _medicalHistory.length,
      itemBuilder: (context, index) {
        final record = _medicalHistory[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record['title'] ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(10, 62, 29, 1),
                      ),
                    ),
                    IconButton(  
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        _showAddMedicalHistoryModal(context, record: record);
                      },  
                    ),
                  ]
                ),
                const SizedBox(height: 4),
                Text(
                  record['subtitle'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMedicalHistoryModal(BuildContext context, {Map<String, dynamic>? record}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController subtitleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    if (record != null) {
      titleController.text = record['title'] ?? '';
      subtitleController.text = record['subtitle'] ?? '';
      descriptionController.text = record['description'] ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(record == null ? "Add Medical History" : "Edit Medical History", style: const TextStyle(color: Color.fromRGBO(33, 158, 80, 1), fontSize: 20),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(  
                  labelText: 'Title',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(  
                  labelText: 'Subtitle',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(  
                  labelText: 'Description',  
                  labelStyle: const TextStyle(color: Color.fromRGBO(10, 62, 29, 1)),  
                  border: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1), width: 2.0),  
                  ),  
                  focusedBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                  enabledBorder: OutlineInputBorder(  
                    borderRadius: BorderRadius.circular(10),  
                    borderSide: const BorderSide(color: Color.fromRGBO(10, 62, 29, 1)),  
                  ),  
                            fillColor: Colors.white,  
                  filled: true,  
                ),
                style: GoogleFonts.poppins(color: Colors.black),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final subtitle = subtitleController.text.trim();
                final description = descriptionController.text.trim();

                if (title.isNotEmpty && subtitle.isNotEmpty && description.isNotEmpty) {
                  final email = await SessionManager.getUserSession();
                  final user = await DBHelper().getPatientsByEmail(email!);

                  if (user != null) {
                    Map<String, dynamic> medicalHistory = {
                      'title': title,
                      'subtitle': subtitle,
                      'description': description,
                    };
                    if (record == null) {
                      // Add new medical history
                      await DBHelper().insertMedicalHistory(email, medicalHistory);
                    } else {
                      // Update existing medical history
                      await DBHelper().updateMedicalHistory(email, record['title'] ,medicalHistory);
                    }
                    Navigator.pop(context); 
                    setState(() {
                      _loadMedicalHistory(email); 
                    });
                  }
                }
              },
              child: const Text("Save", style: TextStyle(color: Color.fromRGBO(33, 158, 80, 1)),),
            ),
          ],
        );
      },
    );
  }
}
