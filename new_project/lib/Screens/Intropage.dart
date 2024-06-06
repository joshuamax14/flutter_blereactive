import 'package:flutter/material.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/Screens/ChangeUser.dart';
import 'package:new_project/Screens/Homepage2.dart';
//import 'package:new_project/Screens/Homepage.dart';
import 'package:provider/provider.dart';

class Intropage extends StatelessWidget {
  const Intropage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StepGear'),
        actions: [
            Padding(padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/Screens/assets/stepgear.png'),
            )
          ],
      ),
      body: Column(
        children: [
          Text(
            context.watch<Usernameprovider>().username,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Changeuser(),
                    ));
              },
              child: Text('Change Patient')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Homepage2(),
                    ));
              },
              child: Text('Home'))
        ],
      ),
    );
  }
}
