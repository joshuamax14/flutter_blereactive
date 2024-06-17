List<Map<String, double>> normalizeGaitCycle(List<double> angles,
    List<DateTime> timestamps, List<DateTime> heelStrikes) {
  List<Map<String, double>> normalizedData = [];

  for (int i = 0; i < heelStrikes.length - 1; i++) {
    DateTime start = heelStrikes[i];
    DateTime end = heelStrikes[i + 1];
    int cycleDuration = end.difference(start).inMilliseconds;

    for (int j = 0; j < timestamps.length; j++) {
      if (timestamps[j].isAfter(start) && timestamps[j].isBefore(end)) {
        double percentage =
            (timestamps[j].difference(start).inMilliseconds / cycleDuration) *
                100;
        normalizedData.add({'percentage': percentage, 'angle': angles[j]});
      }
    }
  }

  return normalizedData;
}
