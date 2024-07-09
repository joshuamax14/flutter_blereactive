
/*
toeoffindex=999
                            if self.checkForHeelStrike:
                                self.delay-=1
                            if self.delay==0:
                                self.delay=SYNC_DELAY
                                self.checkForHeelStrike=False
                                #print(f"knee flex: {self.kneeFlexion[-1:]}")
                                startfound=False
                                endfound=False
                                toesofffound=False
                                endindex = 0
                                startindex = 0
                                dell=12
                                #print(f"checking heelstrike ")
                                for z in range(1,200):
                                #for z in range(1,self.sampsize):
                                    n=self.sampsize-z
                                    #print(f"checking {self.fStates[n]} and {self.fStates[n-1]}")
                                    if self.fStates[n]==1:
                                        if (n>=3):
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
                                        else:
                                            #no start in this sample set.
                                            break
                                rawkneeFlex=[]
                                rawankleFlex=[]
                                rawtoeoff=[]
                                rawhipsFlex=[]
                                toeoffLocation=0.0 
                                midfootLocation = 0
                                midfootfound=False
                                if (startfound):
                                    durr = endindex-startindex
                                    print(f"{self.durr}  HEELSTRIKE end {endindex} - start {startindex} = {endindex-startindex}")
                                    #if durr>self.durr*1.5:
                                    #    startindex = endindex-self.durr
                                    for n in range(startindex,endindex-1):
                                        if self.fStates[n]==0: #lifted foot
                                            if self.fStates[n-1]==0: #lifted foot
                                                if self.fStates[n-2]==2: #toestrike
                                                    if self.fStates[n-3]==2: #toestrike
                                                        toeoffindex=n-1
                                                        if midfootfound:
                                                            toeoffLocation = MIDFOOTPERCENT + (toeoffindex-(midfootLocation))/durr
                                                        else:
                                                            toeoffLocation = float(toeoffindex - startindex)/durr
                                                        break
                                        elif not midfootfound:
                                            if self.fStates[n]==3: #midfoot
                                                if self.fStates[n-1]==1: #heelstrike
                                                    midfootLocation = n
                                                    midfootfound=True
                                            elif self.fStates[n]==2: #toe
                                                if self.fStates[n-1]==1: #heel
                                                    if self.fStates[n-2]==1: #heel
                                                        midfootLocation = n-2
                                                        midfootfound=True
                                    if midfootfound:
                                        startindex = endindex - int((endindex - midfootLocation)/(1.0-MIDFOOTPERCENT))
                                    dell=int((endindex-startindex)*.0)
                                    #dell=int((endindex-startindex)*.1)
                                    #dell=int((endindex-startindex)*.05)
                                    startindex+=dell
                                    #startindex-=0
                                    endindex+=dell
                                    #toeoffindex-=dell
                                    rawtoeoff = self.fStates[startindex:endindex]
                                    print("HEELSTRIKE found")
                                    #lets plot it
                                    nElements = endindex-startindex
*/

List<Map<String, double>> stateDetection(List<int> foot_states, List<double> knee_angles, List<double> foot_angles, List<double> hips_angles, List<DateTime> Timestamps) {
  bool startfound=false;
  bool endfound=false;
  bool toesofffound= false;
  int endindex = 0;
  int startindex = 0;
  for (int x = 1; x < foot_states.length; x++) {
    //read from the last instance
    int n = foot_states.length -1; 
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
        if (foot_states[n-1] ==1 && foot_states[n-2] ==0 && foot_states[n-3] ==0) {
          // valid heel strike
          if (endfound == false) {
            // found end strike
            endfound = true;
            endindex = n-1;
          } else {
            //found start
            if (endindex-n>5) {
              startindex = n-1;
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
double toeoffLocation = 0.0; 
int midfootLocation = 0;
bool midfootfound = false;
if (startfound == true) {
  
  
}
  
  return
}



List<T> filterDataPoints<T>(List<T> dataList1, List<T> dataList2, List<T> dataList3, List<int> timeStamps1, List<int> timeStamps2, List<int> timeStamps3) {
  List<T> filteredDataList1 = [];
  List<T> filteredDataList2 = [];
  List<T> filteredDataList3 = [];
  
  int length = dataList1.length;

  for (int i = 1; i < length; i++) {
    int time1 = timeStamps1[i-1];
    int time2 = timeStamps2[i-1];
    int time3 = timeStamps3[i-1];
    int time4 = timeStamps1[i];
    int time5 = timeStamps2[i];
    int time6 = timeStamps3[i];

    if ((time1 - time2).abs() <= 20 && (time1 - time3).abs() <= 20 && (time2 - time3).abs() <= 20) {
      filteredDataList1.add(dataList1[i]);
      filteredDataList2.add(dataList2[i]);
      filteredDataList3.add(dataList3[i]);
    }
  }

  return [filteredDataList1, filteredDataList2, filteredDataList3];
}

void main() {
  // Example data
  List<int> dataList1 = [1, 2, 3, 4, 5];
  List<int> dataList2 = [10, 20, 30, 40, 50];
  List<int> dataList3 = [100, 200, 300, 400, 500];

  List<int> timeStamps1 = [1000, 2000, 3000, 4000, 5000];
  List<int> timeStamps2 = [1015, 2015, 3015, 4015, 5015];
  List<int> timeStamps3 = [1005, 2005, 3005, 4005, 5005];

  var filteredLists = filterDataPoints(dataList1, dataList2, dataList3, timeStamps1, timeStamps2, timeStamps3);

  print(filteredLists[0]); // Filtered dataList1
  print(filteredLists[1]); // Filtered dataList2
  print(filteredLists[2]); // Filtered dataList3
}
