import 'package:flutter/material.dart';

class AppColors {
  static const primaryColor = Color.fromRGBO(33, 158, 80, 1);
  static const primaryLightColor = Color.fromRGBO(227, 243, 208, 1);
  static const white = Colors.white;
  static const grey = Colors.grey;
}

class AppStyles {
  static const cardBorderRadius = 16.0;
  static const topBorderRadius = 20.0;
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.grey.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class AppStrings {
  static const reschedule = 'Reschedule';
  static const joinSession = 'Join Session';
  static const getQRCode = 'Get QR Code';
  static const addNotes = 'Add Notes';
  static const heyUser = 'Hey, ';
  static const busyDay = 'Today is a busy day';
}
