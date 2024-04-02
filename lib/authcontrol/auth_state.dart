import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:navigator/authcontrol/login_or_register.dart';
import 'package:navigator/pages/custom_search.dart';
//import 'package:navigator/pages/map_page.dart';

class AuthState extends StatelessWidget {
  const AuthState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return const MapScreen();
          } else {
            return const LoginOrRegister();
          }
        }),
      ),
    );
  }
}
