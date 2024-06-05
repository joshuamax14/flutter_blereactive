import 'package:collection/collection.dart';

List<double> kneeangleOffset(List<double> proxValues, List<double> distValues) {
  //double proxValue = 0.0;
  //double distValue = 0.0;
  //double kneeAngle = 0.0;
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
    subtractedProx.add(element1);
  });
  distValues.forEach((element) {
    if (element > 180) {
      element = element - 360;
    }
    subtractedDist.add(element);
  });

  List<double> diffKnee = IterableZip([subtractedProx, subtractedDist])
      .map((pair) => pair[1] - pair[0])
      .toList();

  return diffKnee;
}

List<double> footangleOffset(List<double> proxValues) {
  List<double> subtractedProx = [];
  proxValues.forEach((element1) {
    if (element1 > 180) {
      element1 = element1 - 360;
    }
    subtractedProx.add(element1);
  });
  return subtractedProx;
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
    subtractedProx.add(element1);
  });
  distValues.forEach((element) {
    if (element > 180) {
      element = element - 360;
    }
    subtractedDist.add(element);
  });

  List<double> diffHips = IterableZip([subtractedProx, subtractedDist])
      .map((pair) => pair[1] - pair[0])
      .toList();

  return diffHips;
}
