import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import './between_page.dart';

class ScreenPage extends StatefulWidget{
  const ScreenPage({super.key});

  @override
  State<ScreenPage> createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {

  @override
  void initState() {
    super.initState();
    redirectPage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkBLEPermission() async {
    final status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      print("Denied");
      await Permission.bluetoothScan.request();
    }
  }

  void redirectPage() {
    checkBLEPermission().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const BetweenPage()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Say Hi!'),
      ),
    );
  }
}
