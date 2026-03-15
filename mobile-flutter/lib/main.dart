import 'package:flutter/material.dart';

import 'api_service.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const CucinometroMobileApp());
}

class CucinometroMobileApp extends StatelessWidget {
  const CucinometroMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return MaterialApp(
      title: 'Cucinometro Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A7E8C),
      ),
      home: HomePage(api: api),
    );
  }
}
