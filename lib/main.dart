//lib
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
//this
import 'package:ble_tutorial/core/domains/core_model.dart';
import 'package:ble_tutorial/features/entry/presentation/pager_page.dart';
import 'package:ble_tutorial/features/entry/presentation/screen_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CoreModelAdapter());
  await Hive.openBox<CoreModel>('core');
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const ProviderScope(child: MyApp()));
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
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PagerPage()));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ScreenPage()));
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
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      child: Scaffold(
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
            home: Container(),
          ),
        ),
      ),
    );
  }
}
