import 'package:flutter/material.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/Screens/Homepage.dart';
import 'package:provider/provider.dart';

class Changeuser extends StatelessWidget {
  Changeuser({super.key});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information',
            style: TextStyle(color: Color(0xFF0A3073))),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/Screens/assets/stepgear.png'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Name: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A3073),
                  ),
                ),
                Text(
                  context.watch<Usernameprovider>().username,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0A3073),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter new patient name',
                labelStyle: TextStyle(color: Color(0xFF0A3073)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0A3073)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0A3073)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<Usernameprovider>().ChangePatient(
                      newusername: _nameController.text,
                    );
                FocusManager.instance.primaryFocus?.unfocus();
                _nameController.clear();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.resolveWith<BorderSide>(
                  (states) {
                    if (states.contains(WidgetState.disabled)) {
                      return BorderSide(color: Color(0xFF0A3073));
                    }
                    return BorderSide(color: Color(0xFF0A3073), width: 2.0);
                  },
                ),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                )),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Color(0xFF0A3073)),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Birthday: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A3073),
                  ),
                ),
                Text(
                  context.watch<Usernameprovider>().bday,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0A3073),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _birthdayController,
              decoration: InputDecoration(
                labelText: 'Enter new birthday',
                labelStyle: TextStyle(color: Color(0xFF0A3073)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0A3073)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0A3073)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<Usernameprovider>().ChangeBday(
                      newbday: _birthdayController.text,
                    );
                FocusManager.instance.primaryFocus?.unfocus();
                _birthdayController.clear();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.resolveWith<BorderSide>(
                  (states) {
                    if (states.contains(WidgetState.disabled)) {
                      return BorderSide(color: Color(0xFF0A3073));
                    }
                    return BorderSide(color: Color(0xFF0A3073), width: 2.0);
                  },
                ),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                )),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Color(0xFF0A3073)),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Homepage(),
                      ));
                },
                child: Text('Home'))
          ],
        ),
      ),
    );
  }
}
