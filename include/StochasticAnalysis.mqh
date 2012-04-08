//+------------------------------------------------------------------+
//|                                           StochasticAnalysis.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "JM"
#property link      ""

#include <basics.mqh>
#include <drawing.mqh>

#define StAn.MAX_DATAPOINTS 200

#define StAn.VB_TIME 0
#define StAn.VB_MAIN 1
#define StAn.VB_SIGNAL 2
#define StAn.VB_PRICE 3
#define StAn.VB_CROSS_EXLOW_DOWN 4
#define StAn.VB_CROSS_EXLOW_UP 5
#define StAn.VB_CROSS_EXHIGH_DOWN 6
#define StAn.VB_CROSS_EXHIGH_UP 7
#define StAn.NUMVALUEBUCKETS 8

double StAn.EXTR_LOW = 25;
double StAn.EXTR_HIGH = 75;

double StAn.StochasticHistory[NUMPERIODS][StAn.MAX_DATAPOINTS][StAn.NUMVALUEBUCKETS];
bool StAn.InitializedHistory[NUMPERIODS];
int StAn.TimePeriod = 0;
int StAn.IndexOfTimePeriod = 0;


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
      for (int i=StAn.MAX_DATAPOINTS-1; i>=0; i--) {
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
   int tpIndex = StAn.IndexOfTimePeriod;

   StAn.StochasticHistory[tpIndex][barIndex][StAn.VB_TIME] = iTime(NULL, StAn.TimePeriod, barIndex);
   StAn.StochasticHistory[tpIndex][barIndex][StAn.VB_MAIN] = StochasticValue(MODE_MAIN,StAn.TimePeriod, barIndex);
   StAn.StochasticHistory[tpIndex][barIndex][StAn.VB_SIGNAL] = StochasticValue(MODE_SIGNAL,StAn.TimePeriod, barIndex);
   StAn.StochasticHistory[tpIndex][barIndex][StAn.VB_PRICE] = iClose(NULL, StAn.TimePeriod, barIndex);
   
   StAn.SetHV(barIndex, StAn.VB_CROSS_EXLOW_DOWN, 0);
   StAn.SetHV(barIndex, StAn.VB_CROSS_EXLOW_UP, 0);
   StAn.SetHV(barIndex, StAn.VB_CROSS_EXHIGH_DOWN, 0);
   StAn.SetHV(barIndex, StAn.VB_CROSS_EXHIGH_UP, 0);
   
   if (barIndex < StAn.MAX_DATAPOINTS - 3) {
      double main = StAn.GetHV(barIndex,StAn.VB_MAIN);
      double mainPrev = StAn.GetHV(barIndex+1,StAn.VB_MAIN);
      
      // did we cross into / out of extreme zone?   
      if (main < StAn.EXTR_LOW && mainPrev > StAn.EXTR_LOW){
         StAn.SetHV(barIndex, StAn.VB_CROSS_EXLOW_DOWN, 1);
      }
      else if (main > StAn.EXTR_LOW && mainPrev < StAn.EXTR_LOW) {
         StAn.SetHV(barIndex, StAn.VB_CROSS_EXLOW_UP, 1);      
      }
            
      else if (main > StAn.EXTR_HIGH && mainPrev < StAn.EXTR_HIGH) {
         StAn.SetHV(barIndex, StAn.VB_CROSS_EXHIGH_UP, 1);    
      }
            
      else if (main < StAn.EXTR_HIGH && mainPrev > StAn.EXTR_HIGH){
         StAn.SetHV(barIndex, StAn.VB_CROSS_EXHIGH_DOWN, 1);
      }

   }
}


double StAn.GetHV(int barIndex, int valueBucket) {
   return(StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][valueBucket]);
}

void StAn.SetHV(int barIndex, int valueBucket, double val) {
   StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][valueBucket] = val;
}