import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Page'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Center(
              child: Text(
                'Help & Instructions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Follow these steps to get help:',
                style: TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 20),
            for (var step in instructions)
              InstructionCard(
                step: step['step']!,
                description: step['description']!,
              ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'For further assistance, contact our support team.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionCard extends StatelessWidget {
  final String step;
  final String description;

  InstructionCard({required this.step, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              step,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, String>> instructions = [
  {
    'step': 'Change Patient Information (Filipino)',
    'description': 'Pindutin ang "Change Patient" button upang mapalitan mo ang iyong pangalan at birthday sa text box at maaaring pindutin ang "Save" sa ilalim ng text box upang mailista ang iyong pangalan o kaarawan.'
  },
  {
    'step': 'Change Patient Information (English)',
    'description': 'Tap the "Change Patient" button to update your name and birthday. Insert your information on the specified text box and click "Save" to save your information.'
  },
  {
    'step': 'Home (Filipino)',
    'description': 'Pindutin ang "Home" button upang dumiretso sa ebalwasyon ng iyong paglakad. Siguraduhin na naka-bukas na ang mga device na nakasuot sa katawan at nakabukas na rin ang BLUETOOTH ng iyong selpon o tablet. Pindutin ang "Start" upang simulan ang pagtantos ng data, "Stop" naman kung tatapusin na ang pagkuha ng data, "Save" naman kung nais mong i-save bilang litrato ang data na iyong nakuha.'
  },
  {
    'step': 'Home(English)',
    'description': 'Tap the "Home" button to go to the assessment page. Please turn ON all of the wearable devices and the BLUETOOTH on your phone/tablet before you start the test. "Start" button signifies the start of collection of data, in which you can start walking, "Stop" button signifies the stop of data collection. "Save" button is when you wanted to screen capture the current information on your screen'
  },
  {
    'step': 'Help',
    'description': 'If you have further questions, unrelated to the application, kindly contact your physical therapist. Have a great day! The "left arrow" button on the upper left side of your screen means return to the page where you went last time.'
  },
];
