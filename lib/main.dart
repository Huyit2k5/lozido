import 'package:flutter/material.dart';
import 'package:lozido_app/presentation/pages/auth/register_page.dart';

void main() =>
    runApp(MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RegisterScreen();
  }
}
