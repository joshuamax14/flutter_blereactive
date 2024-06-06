import 'package:flutter/material.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/Screens/Homepage.dart';
import 'package:new_project/Screens/Intropage.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Usernameprovider(),
        ),
      ],
      child: MaterialApp(
        title: 'StepGear Demo App',
        debugShowCheckedModeBanner: true,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Intropage(),
      ),
    );
  }
}
