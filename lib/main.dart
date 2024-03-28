import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:navigator/authcontrol/auth_state.dart';
//import 'package:navigator/authcontrol/login_or_register.dart';
import 'package:navigator/firebase_options.dart';
//import 'package:navigator/pages/map_page.dart';
import 'package:navigator/themes/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthState(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
