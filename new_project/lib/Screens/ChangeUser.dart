import 'package:flutter/material.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:provider/provider.dart';

class Changeuser extends StatelessWidget {
  Changeuser({super.key});

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
        actions: [
            Padding(padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/Screens/assets/stepgear.png'),
            )
          ],
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text('Username: '),
                Text(context.watch<Usernameprovider>().username),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<Usernameprovider>().ChangePatient(
                      newusername: _nameController.text,
                    );
                FocusManager.instance.primaryFocus?.unfocus();
                _nameController.clear();
              },
              child: const Text('Save'),
            ),
            Row(
              children: [
                Text('Birthday: '),
                Text(context.watch<Usernameprovider>().bday),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _birthdayController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<Usernameprovider>().ChangeBday(
                      newbday: _birthdayController.text,
                    );
                FocusManager.instance.primaryFocus?.unfocus();
                _nameController.clear();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
