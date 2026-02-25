import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:wildlife_tracker/user_profile.dart';
import 'package:wildlife_tracker/alert_notifications.dart';
import 'package:wildlife_tracker/add_pin.dart';
import 'package:wildlife_tracker/map_view.dart';
import 'package:wildlife_tracker/auth_layout.dart';
import 'package:wildlife_tracker/user_login.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_config_plus/flutter_config_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:wildlife_tracker/theme_colors.dart';

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
      title: 'Animap',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: SavannahColors.beigeLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SavannahColors.greenOlive,
          primary: SavannahColors.greenOlive,
        ),
      ),
      home: const AuthLayout(
        pageIfNotConnected: UserLogin(),
        child: MyHomePage(title: "Animap"),
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
  final GlobalKey mapViewKey = GlobalKey();

  void _setNavigationIndex(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: SavannahColors.white.withOpacity(0.7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 2.5,
            fontWeight: FontWeight.w900,
            color: SavannahColors.textBlack,
            fontSize: 14.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: SavannahColors.beigeDark, width: 0.5),
        ),
      ),

      // Positions the FAB at the bottom right
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: _currentIndex != 0
          ? null
          : Padding(
              // Padding pushes the button up to clear the Google Maps zoom UI
              padding: const EdgeInsets.only(bottom: 90.0),
              child: FloatingActionButton(
                elevation: 4,
                backgroundColor: SavannahColors.greenDeep,
                foregroundColor: SavannahColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                // onPressed: () async {
                //   final result = await showCupertinoModalPopup(
                //     context: context,
                //     builder: (context) => AddPin(),
                //   );

                //   if (result != null) {
                //     final dynamic state = mapViewKey.currentState;
                //     if (state != null) {
                //       state.addExternalMarker(
                //         result["latitude"],
                //         result["longitude"],
                //         result["pinType"],
                //       );
                //     }
                //   }
                // },
                onPressed: () async {
                  final result = await showCupertinoModalPopup(
                    context: context,
                    builder: (context) => const AddPin(),
                  );

                  if (result != null) {
                    final dynamic state = mapViewKey.currentState;
                    if (state != null) {
                      // 1. Convert the String back to the actual Enum object
                      // We look through PinType.values to find the one with the matching title
                      final PinType selectedType = PinType.values.firstWhere(
                        (type) => type.title == result["pinType"],
                        orElse: () => PinType.sighting, // Default fallback
                      );

                      // 2. Pass the Enum object (selectedType) instead of just the String
                      state.addExternalMarker(
                        result["latitude"],
                        result["longitude"],
                        selectedType,
                      );
                    }
                  }
                },
                child: const Icon(Icons.add_location_alt_rounded, size: 28),
              ),
            ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          MapView(key: mapViewKey),
          AlertNotifications(),
          UserProfile(),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: SavannahColors.beigeDark, width: 1),
          ),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          backgroundColor: SavannahColors.white,
          indicatorColor: SavannahColors.orangeSand.withOpacity(0.3),
          selectedIndex: _currentIndex,
          onDestinationSelected: _setNavigationIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(
                Icons.map_rounded,
                color: SavannahColors.greenDeep,
              ),
              label: "Map",
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(
                Icons.notifications_rounded,
                color: SavannahColors.orangeCaramel,
              ),
              label: "Alerts",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: SavannahColors.greenDeep,
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
