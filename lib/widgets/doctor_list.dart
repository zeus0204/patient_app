import 'package:flutter/material.dart';
import 'package:patient_app/models/doctor.dart';
import 'package:patient_app/utils/constants.dart';

class DoctorList extends StatelessWidget {
  final List<Doctor> doctors;
  final Size size;

  const DoctorList({
    super.key,
    required this.doctors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: AppColors.white,
        height: size.height * 0.6,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(doctor.avatar),
              ),
              title: Text(
                doctor.name,
                style: TextStyle(fontSize: size.width * 0.035),
              ),
              subtitle: Text(
                doctor.updatedHistory,
                style: TextStyle(fontSize: size.width * 0.03),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey),
              onTap: () {},
            );
          },
        ),
      ),
    );
  }
}
