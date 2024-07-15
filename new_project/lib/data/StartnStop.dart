List<double> Heelstrike(List<int> foot_states, List<double> knee_angles) {
  bool startfound = false;
  bool endfound = false;
  bool toesofffound = false;
  int endindex = 0;
  int startindex = 0;
  for (int x = 1; x < foot_states.length; x++) {
    //read from the last instance
    int n = foot_states.length - 1;
    if (foot_states[n] == 1) {
      if (n >= 3) {
        /*
        if (self.fStates[n-1] == 1) and (self.fStates[n-2] == 0) and (self.fStates[n-3] == 0):
                                            #found valid heelstrike
                                                if endfound==False:
                                                    #found the end
                                                    endfound=True
                                                    endindex=n-1 #+dell #+((SYNC_DELAY-0)*2)
                                                else:
                                                    #found start of heelstrike
                                                    if endindex-n>5:
                                                        startindex = n-1 #+dell  #+((SYNC_DELAY-0)*2)
                                                        startfound=True
                                                        break
                                                        */
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
    return knee_angles.sublist(startindex, endindex);
  } else if (endfound == true) {
    return knee_angles.sublist(0, endindex);
  }
  return knee_angles;
}
