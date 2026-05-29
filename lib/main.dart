import 'package:flutter/material.dart';
import 'package:untitled/profilo.dart';
import 'package:untitled/widget/MyBottomBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/widget/servizio_notifiche.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notifService = NotificationService();
  await notifService.init();
  await notifService.scheduleNotificheEventi();
  await notifService.scheduleMotivazionale();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyBottomBar(),

      routes: {
        '/profilo': (context) => Profilo(),
      },

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}
