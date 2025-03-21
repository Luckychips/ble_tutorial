

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import './pages/screen_page.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEMO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bluetooth Low Energy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
    checkBLEPermission().then((_) {
      if (mounted) {

      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkBLEPermission() async {
    if (!await FlutterBluePlus.isSupported) {
      print('Bluetooth not supported by this device.');
      return;
    }

    final status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      print('Denied');
      await Permission.bluetoothScan.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, textAlign: TextAlign.center),
      ),
      body: Center(
        child: MaterialApp(
          title: 'DEMO',
          debugShowCheckedModeBanner: false,
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: widget!,
            );
          },
          home: const ScreenPage(),
        ),
      ),
    );
  }
}
