import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const DeuBandaApp());
}

class DeuBandaApp extends StatelessWidget {
  const DeuBandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeuBanda App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}