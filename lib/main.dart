import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:wildlife_tracker/user_profile.dart';
import 'package:wildlife_tracker/alert_notifications.dart';
import 'package:wildlife_tracker/add_pin.dart';
import 'package:wildlife_tracker/auth_layout.dart';
import 'package:wildlife_tracker/user_login.dart';
import 'package:wildlife_tracker/map_view.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_config_plus/flutter_config_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfigPlus.loadEnvVariables();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wildlife Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: AuthLayout(
        pageIfNotConnected: const UserLogin(),
        child: const MyHomePage(title: "Wildlife Tracker"),
      ),
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
  int _currentIndex = 0;

  void _setNavigationIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 24.0,
          ),
        ),
        forceMaterialTransparency: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: _currentIndex != 0
          ? null
          : FloatingActionButton(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              onPressed: () {
                // Your teammate's AddPin sheet
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => const AddPin(),
                );
              },
              child: const Icon(Icons.add),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MapView(), // Your isolated map file
          AlertNotifications(),
          UserProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _setNavigationIndex,
        selectedIndex: _currentIndex,
        indicatorColor: Colors.blue,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.map_outlined),
            label: "Map",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.notification_important_rounded),
            icon: Icon(Icons.notification_important_outlined),
            label: "Alerts",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person_rounded),
            icon: Icon(Icons.person_outlined),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}