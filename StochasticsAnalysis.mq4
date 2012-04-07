//+------------------------------------------------------------------+
//|                                          StochasticsAnalysis.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "JM"
#property link      ""

#include <basics.mqh>

#define StAn.MAX_DATAPOINTS 200
#define StAn.NUMVALUEBUCKETS 3
#define StAn.VB_TIME 0
#define StAn.VB_MAIN 1
#define StAn.VB_SIGNAL 2


double StAn.StochasticHistory[NUMPERIODS][StAn.MAX_DATAPOINTS][StAn.NUMVALUEBUCKETS];
bool StAn.InitializedHistory[NUMPERIODS];
int StAn.TimePeriod = 0;
int StAn.IndexOfTimePeriod = 0;


int init()
  {
   StAn.TimePeriod = Period();
   return(0);
  }

int deinit()
  {
   return(0);
  }


int start()
  {
   StAn.UpdateResultsForTimePeriod(Period());
  
   return(0);
  }
//+------------------------------------------------------------------+

void StAn.UpdateResultsForTimePeriod(int timeperiod) {
   StAn.switchTimePeriod(timeperiod);
   StAn.update();
}


void StAn.switchTimePeriod(int timeperiod) {
   StAn.TimePeriod = timeperiod;
   StAn.IndexOfTimePeriod = IndexOfTimePeriod(timeperiod);
}


void StAn.update() {
   StAn.checkInitHistory();
   StAn.checkHandleNewBar();

   // in either case update values for current tick
   StAn.assembleHistoryData(0);
   
}

void StAn.checkInitHistory() {
   int tpIndex = StAn.IndexOfTimePeriod;
   
   // see if we need to run through all history for initial data collection   
   if (StAn.InitializedHistory[tpIndex] == false) {   
      for (int i=0; i<StAn.MAX_DATAPOINTS; i++) {
         StAn.assembleHistoryData(i);
      }
      StAn.InitializedHistory[tpIndex] = true;
   }
}

// check if a new bar has opened
void StAn.checkHandleNewBar() {
   int tpIndex = StAn.IndexOfTimePeriod;
   datetime curTime = iTime(NULL, StAn.TimePeriod, 0);
   
   if (curTime != StAn.StochasticHistory[tpIndex][0][StAn.VB_TIME]) {
      // new bar, shift right
      for (int dp=1; dp<StAn.MAX_DATAPOINTS; dp++) {
         for (int vb=0; vb<StAn.NUMVALUEBUCKETS; vb++ ){
            StAn.StochasticHistory[tpIndex][StAn.MAX_DATAPOINTS-dp][vb] = StAn.StochasticHistory[tpIndex][StAn.MAX_DATAPOINTS-dp-1][vb];
         }
      }
   }
}


void StAn.assembleHistoryData(int barIndex) {
   StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][StAn.VB_TIME] = iTime(NULL, StAn.TimePeriod, barIndex);
   StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][StAn.VB_MAIN] = StochasticValue(MODE_MAIN,StAn.TimePeriod, barIndex);
   StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][StAn.VB_SIGNAL] = StochasticValue(MODE_SIGNAL,StAn.TimePeriod, barIndex);
}



