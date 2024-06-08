import 'package:collection/collection.dart';

List<double> kneeangleOffset(
    List<double> proxValuesKnee, List<double> distValuesKnee) {
  //double proxValue = 0.0;
  //double distValue = 0.0;
  //double kneeAngle = 0.0;
  List<double> subtractedProxKnee = [];
  List<double> subtractedDistKnee = [];

  // if (proxValues.isNotEmpty && distValues.isNotEmpty) {
  //proxValue = proxValues.average;
  //distValue = distValues.average;
  //kneeAngle = (proxValue - 180) - (distValue - 180);
  proxValuesKnee.forEach((knee_element1) {
    if (knee_element1 > 180.0) {
      knee_element1 = knee_element1 - 360;
    }
    ;
    subtractedProxKnee.add(knee_element1-10.0);
  });
  distValuesKnee.forEach((knee_element) {
    if (knee_element > 180.0) {
      knee_element = knee_element - 360;
    }
    ;
    subtractedDistKnee.add(knee_element);
  });

  List<double> diffKnee = IterableZip([subtractedProxKnee, subtractedDistKnee])
      .map((knee_pair) => knee_pair[1] - knee_pair[0])
      .toList();

  return diffKnee;
}

List<double> footangleOffset(List<double> proxValuesFoot, List<double> distValuesFoot) {
  List<double> subtractedProxFoot = [];
  List<double> subtractedDistFoot = [];

  proxValuesFoot.forEach((foot_element1) {
    
    if (foot_element1 > 180) {
      foot_element1 = foot_element1 - 360;
      subtractedProxFoot.add(foot_element1);
    }
    ;
    //subtractedProxFoot.add(foot_element1);
  });
  distValuesFoot.forEach((foot_element) {
    if (foot_element > 180) {
      foot_element = foot_element - 360;
    }
    ;
    foot_element = foot_element -270;
    subtractedDistFoot.add(foot_element);
  });

  List<double> diffFoot = IterableZip([subtractedProxFoot, subtractedDistFoot])
      .map((foot_pair) => (foot_pair[0]) - foot_pair[1])
      .toList();

  return diffFoot;
}

List<double> hipangleCalc(List<double> proxValues, List<double> distValues) {
  List<double> subtractedProx = [];
  List<double> subtractedDist = [];

  // if (proxValues.isNotEmpty && distValues.isNotEmpty) {
  //proxValue = proxValues.average;
  //distValue = distValues.average;
  //kneeAngle = (proxValue - 180) - (distValue - 180);
  proxValues.forEach((element1) {
    if (element1 > 180) {
      element1 = element1 - 360;
    }
    ;
    subtractedProx.add(element1);
  });
  distValues.forEach((element) {
    if (element > 180) {
      element = element - 360;
    }
    ;
    subtractedDist.add(element);
  });

  List<double> diffHips = IterableZip([subtractedProx, subtractedDist])
      .map((pair) => -1 * (pair[1] - pair[0]))
      .toList();

  return diffHips;
}

List<double> enforceLimits(List<double> values, double min, double max) {
  return values.map((value) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }).toList();
}

