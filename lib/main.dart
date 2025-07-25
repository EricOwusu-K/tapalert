import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tapalert/firebase_options.dart';
import 'homepage.dart';
import 'alertpage.dart';
import 'contactpage.dart';
import 'emergencypage.dart';
import 'settingspage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TapAlertApp());
}

class TapAlertApp extends StatelessWidget {
  const TapAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapAlert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(
          0xFFF4F5F9,
        ), // Soft pastel background
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F5F9),
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.grey),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF736BFE), // Soft purple
          secondary: Color(0xFFF2F3F8),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    EmergencyPage(),
    AlertsPage(),
    EmergencyContactsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF736BFE),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.touch_app),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.contact_phone),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
