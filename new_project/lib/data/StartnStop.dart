List<DateTime> Heelstrike(List<int> foot_states, List<DateTime> foot_time) {
  print(foot_states.length);
  print(foot_time.length);
  List<DateTime> heelStrikes = [];
  bool startfound = false;
  bool endfound = false;
  //bool toesofffound = false;
  int endindex = 0;
  int startindex = 0;
  for (int x = 1; x < foot_states.length; x++) {
    //read from the last instance
    int n = foot_states.length - 1;
    if (foot_states[n] == 1) {
      if (n >= 3) {
        if (foot_states[n - 1] == 1 &&
            foot_states[n - 2] == 0 &&
            foot_states[n - 3] == 0) {
          // valid heel strike
          if (endfound == false) {
            // found end strike
            endfound = true;
            endindex = n - 1;
          } else {
            //found start
            if (endindex - n > 5) {
              startindex = n - 1;
              startfound = true;
              break;
            }
          }
        } else {
          //what do we do when it doesn't see a start?
          break;
        }
      }
    }
  }
  if (startfound == true && endfound == true) {
    heelStrikes.add(foot_time[startindex]);
    heelStrikes.add(foot_time[endindex]);
    return heelStrikes;
  } else if (endfound == true) {
    heelStrikes.add(foot_time[0]);
    heelStrikes.add(foot_time[endindex]);
    return heelStrikes;
  } else {
    heelStrikes.add(foot_time[0]);
    heelStrikes.add(foot_time[foot_states.length - 1]);
    return heelStrikes;
  }
}
