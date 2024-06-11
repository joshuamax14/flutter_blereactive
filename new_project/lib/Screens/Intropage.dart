import 'package:flutter/material.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/Screens/ChangeUser.dart';
import 'package:new_project/Screens/HelpScreen.dart';
import 'package:new_project/Screens/Homepage.dart';
import 'package:provider/provider.dart';

class Intropage extends StatelessWidget {
  const Intropage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StepGear'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/Screens/assets/stepgear.png'),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome ${context.watch<Usernameprovider>().username}!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),

            SizedBox(height: 20),
            // Wrap the image with a Container to adjust its size
            Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // 80% of the screen width
              height: MediaQuery.of(context).size.height *
                  0.3, // 30% of the screen height
              child: Image.asset('lib/Screens/assets/walking.gif'),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Changeuser(),
                  ),
                );
              },
              child: Text('Change Patient Information'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Homepage(),
                  ),
                );
              },
              child: Text('Home'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HelpPage(),
                  ),
                );
              },
              child: Text('Help'),
            )
          ],
        ),
      ),
    );
  }
}
