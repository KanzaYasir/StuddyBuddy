import 'package:flutter/material.dart';
import 'modules/home/home_screen.dart';

void main() {
  runApp(StudyBuddyApp());
}

class StudyBuddyApp extends StatefulWidget {
  @override
  State<StudyBuddyApp> createState() => _StudyBuddyAppState();
}

class _StudyBuddyAppState extends State<StudyBuddyApp> {
  bool isDarkTheme = true;

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkTheme
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black87,
              primaryColor: Colors.black87,
              colorScheme: ColorScheme.dark(primary: Colors.black87),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.grey[200],
              primaryColor: Colors.blueAccent,
              colorScheme: ColorScheme.light(primary: Colors.blueAccent),
            ),
      home: HomeScreen(
        toggleTheme: toggleTheme,
        isDarkTheme: isDarkTheme,
      ),
    );
  }
}
