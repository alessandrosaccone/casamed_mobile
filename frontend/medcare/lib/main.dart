// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() { //async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = 'pk_test_51RBewF4IOwwF31fGraDQ9QdzjdFfNPQ7pLuJ4IbAQAR7xRFtpSQSfMAEktPppaJLTrqKhfD2K27KzQVwPt5lsFcS00oOCuD348';
  //await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
