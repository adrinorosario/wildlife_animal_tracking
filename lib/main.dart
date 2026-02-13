import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import 'package:wildlife_tracker/user_profile.dart';
import 'package:wildlife_tracker/alert_notifications.dart';
import 'package:wildlife_tracker/add_pin.dart';
import 'package:wildlife_tracker/auth_layout.dart';
import 'package:wildlife_tracker/user_login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_config_plus/flutter_config_plus.dart';

import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfigPlus.loadEnvVariables();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  final Completer<GoogleMapController> _controller = Completer();
  int _currentIndex = 0;

  void _setNavigationIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.title,
          style: TextStyle(
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
                showCupertinoSheet<void>(
                  context: context,
                  useNestedNavigation: false,
                  builder: (context) => AddPin(),
                );
              },
              child: Icon(Icons.add),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(12.658833, 75.604339),
                  zoom: 15,
                ),
                mapType: MapType.satellite,
                myLocationEnabled: true,
                compassEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ],
          ),
          AlertNotifications(),
          UserProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _setNavigationIndex,
        selectedIndex: _currentIndex,
        indicatorColor: Colors.blue,
        destinations: [
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
