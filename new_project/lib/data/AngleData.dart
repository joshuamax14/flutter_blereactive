import 'package:collection/collection.dart';

double minKnee = -10.0;
double maxKnee = 150.0;
double minFoot = -50.0;
double maxFoot = 50.0;
double minHips = -30.0;
double maxHips = 60.0;

List<double> kneeangleOffset(
    List<double> proxValuesKneeKnee, List<double> distValuesKneeKnee) {
  //double proxValue = 0.0;
  //double distValue = 0.0;
  //double kneeAngle = 0.0;
  List<double> subtractedProxKnee = [];
  List<double> subtractedDistKnee = [];

  // if (proxValuesKnee.isNotEmpty && distValuesKnee.isNotEmpty) {
  //proxValue = proxValuesKnee.average;
  //distValue = distValuesKnee.average;
  //kneeAngle = (proxValue - 180) - (distValue - 180);
  proxValuesKneeKnee.forEach((knee_element1) {
    if (knee_element1 > 180.0) {
      knee_element1 = knee_element1 - 360;
    }
    ;
    subtractedProxKnee.add(knee_element1);
  });
  distValuesKneeKnee.forEach((knee_element) {
    if (knee_element > 180.0) {
      knee_element = knee_element - 360;
    }
    ;
    subtractedDistKnee.add(knee_element);
  });

  List<double> diffKnee = IterableZip([subtractedProxKnee, subtractedDistKnee])
      .map((knee_pair) => knee_pair[1] - knee_pair[0])
      .toList();

  //clean data
  diffKnee.removeWhere(
      (knee_number) => knee_number < minKnee || knee_number > maxKnee);

  return diffKnee;
}

List<double> footangleOffset(
    List<double> proxValuesFoot, List<double> distValuesFoot) {
  List<double> subtractedProxFoot = [];
  List<double> subtractedDistFoot = [];
  List<double> subtractFoot = [];

  proxValuesFoot.forEach((foot_element1) {
    foot_element1 += 15;
    if (foot_element1 > 180) {
      foot_element1 = foot_element1 - 360;
    }
    ;
    foot_element1 = foot_element1 + 90;
    subtractedProxFoot.add(foot_element1);
  });

  distValuesFoot.forEach((foot_element) {
    if (foot_element > 180) {
      foot_element = 270 - foot_element;
    }
    ;
    foot_element = foot_element - 10;
    subtractedDistFoot.add(foot_element);
  });

  print('proxraw: $proxValuesFoot');
  print('distraw: $distValuesFoot');
  //print('dist: $subtractedDistFoot');

  List<double> diffFoot = IterableZip([subtractedProxFoot, subtractedDistFoot])
      .map((foot_pair) => foot_pair[0] - foot_pair[1])
      .toList();
  diffFoot.forEach((foot_element3) {
    foot_element3 = foot_element3 - 110.0;
    subtractFoot.add(foot_element3);
  });
  //print(subtractFoot);
  //clean data
  //subtractFoot.removeWhere(
  //(foot_number) => foot_number < minFoot || foot_number > maxFoot);
  //print(subtractFoot);
  return subtractFoot;
}

List<double> hipangleCalc(
    List<double> proxValuesHips, List<double> distValuesHips) {
  List<double> subtractedProx = [];
  List<double> subtractedDist = [];
  List<double> subtractedHips = [];

  // if (proxValuesKnee.isNotEmpty && distValuesKnee.isNotEmpty) {
  //proxValue = proxValuesKnee.average;
  //distValue = distValuesKnee.average;
  //kneeAngle = (proxValue - 180) - (distValue - 180);
  proxValuesHips.forEach((element1) {
    if (element1 > 180) {
      element1 = element1 - 360;
    }
    ;
    //element1 = element1 - 10;
    subtractedProx.add(element1);
  });
  distValuesHips.forEach((element) {
    if (element > 180) {
      element = element - 360;
    }
    ;
    element = element - 20;
    subtractedDist.add(element);
  });

  print('prox: $subtractedProx');
  print('dist: $subtractedDist');

  List<double> diffHips = IterableZip([subtractedProx, subtractedDist])
      .map((pair) => -1 * (pair[1] - pair[0]))
      .toList();

  //clean data

  diffHips.removeWhere((number) => number < minHips || number > maxHips);

  return diffHips;
}

double AngleAveKnee(List<double> valuesKnee) {
  double averageKnee = valuesKnee.average;
  double final_average_knee = double.parse(
    averageKnee.toStringAsFixed(2),
  );
  return final_average_knee;
}

double AngleAveFoot(List<double> valuesFoot) {
  double averageFoot = valuesFoot.average;
  double final_average_foot = double.parse(
    averageFoot.toStringAsFixed(2),
  );
  return final_average_foot;
}

double AngleAveHips(List<double> valuesHips) {
  double averageHips = valuesHips.average;
  double final_average_hips = double.parse(
    averageHips.toStringAsFixed(2),
  );
  return final_average_hips;
}
