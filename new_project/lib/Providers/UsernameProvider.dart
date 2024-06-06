import 'package:flutter/material.dart';

class Usernameprovider extends ChangeNotifier {
  String username;
  String bday;

  Usernameprovider({
    this.username = 'Patient',
    this.bday = 'August 10, 1997',
  });

  void ChangePatient({
    required String newusername,
  }) async {
    username = newusername;
    notifyListeners();
  }

  void ChangeBday({
    required String newbday,
  }) async {
    bday = newbday;
    notifyListeners();
  }
}
