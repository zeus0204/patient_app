import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodePage extends StatelessWidget {
  final String data;

  const QRCodePage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(  
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: const Text(
            'QR Code',
            style: TextStyle(color:  Color.fromRGBO(33, 158, 80, 1,), fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromRGBO(33, 158, 80, 1)),
      ),
      body: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 400.0,
          gapless: false,
        ),
      ),
    );  
  }
}