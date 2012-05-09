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
#define StAn.VB_CROSS_AVG_DOWN 8
#define StAn.VB_CROSS_AVG_UP 9
#define StAn.VB_TURN_DOWN 10
#define StAn.VB_TURN_UP 11
#define StAn.VB_LOWER_PREV_REL 12
#define StAn.VB_LOWER_NEXT_REL 13
#define StAn.VB_HIGHER_PREV_REL 14
#define StAn.VB_HIGHER_NEXT_REL 15
#define StAn.VB_LOWER_PREV_ABS 16
#define StAn.VB_LOWER_NEXT_ABS 17
#define StAn.VB_HIGHER_PREV_ABS 18
#define StAn.VB_HIGHER_NEXT_ABS 19
#define StAn.NUMVALUEBUCKETS 20

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
   
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXLOW_DOWN, 0);
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXLOW_UP, 0);
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_DOWN, 0);
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_UP, 0);
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_AVG_DOWN, 0);
   StAn.SetHistVal(barIndex, StAn.VB_CROSS_AVG_UP, 0);
   StAn.SetHistVal(barIndex, StAn.VB_TURN_UP, 0);
   StAn.SetHistVal(barIndex, StAn.VB_TURN_DOWN, 0);
   StAn.SetHistVal(barIndex, StAn.VB_LOWER_PREV_REL, 0);   
   StAn.SetHistVal(barIndex, StAn.VB_LOWER_NEXT_REL, 0);      
   StAn.SetHistVal(barIndex, StAn.VB_HIGHER_PREV_REL, 0);
   StAn.SetHistVal(barIndex, StAn.VB_HIGHER_NEXT_REL, 0);
   
   if (barIndex < StAn.MAX_DATAPOINTS - 3) {
      double main = StAn.GetHistVal(barIndex,StAn.VB_MAIN);
      double mainPrev = StAn.GetHistVal(barIndex+1,StAn.VB_MAIN);
      double signal = StAn.GetHistVal(barIndex,StAn.VB_SIGNAL);
      double signalPrev = StAn.GetHistVal(barIndex+1,StAn.VB_SIGNAL);
      
      // did we cross into / out of extreme zone?   
      if (main < StAn.EXTR_LOW && mainPrev > StAn.EXTR_LOW){
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXLOW_DOWN, 1);
      }
      else if (main > StAn.EXTR_LOW && mainPrev < StAn.EXTR_LOW) {
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXLOW_UP, 1);      
      }
            
      else if (main > StAn.EXTR_HIGH && mainPrev < StAn.EXTR_HIGH) {
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_UP, 1);    
      }
            
      else if (main < StAn.EXTR_HIGH && mainPrev > StAn.EXTR_HIGH){
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_DOWN, 1);
      }
      
      // did avg cross main?
      if (signal < main && signalPrev >= mainPrev)
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_AVG_DOWN, 1);

      else if (signal > main && signalPrev <= mainPrev)
         StAn.SetHistVal(barIndex, StAn.VB_CROSS_AVG_UP, 1);

      if (barIndex > 1) {         
         double mainPrev2 = StAn.GetHistVal(barIndex+2,StAn.VB_MAIN);
         // is this a turning point (top / bottom)
         if (mainPrev2 > mainPrev && main > mainPrev) {
            StAn.SetHistVal(barIndex+1, StAn.VB_TURN_UP, 1);
         }  else if (mainPrev2 < mainPrev && main < mainPrev) {
            StAn.SetHistVal(barIndex+1, StAn.VB_TURN_DOWN, 1);
         }
         
      }
   }
   
   StAn.adjustHistoryTopsBottoms(barIndex);
}

void StAn.adjustHistoryTopsBottoms(int startBar) {
   
   if (startBar >= StAn.MAX_DATAPOINTS-1)
      return;

   int barsBack = 1;
   
   int lowerNext = 0;
   int lowerPrev = 0;   
   int higherNext = 0;
   int higherPrev = 0;   
   int lowerNextAbs = 0;
   int lowerPrevAbs = 0;   
   int higherNextAbs = 0;
   int higherPrevAbs = 0;   
   
   double main = StAn.GetHistVal(startBar,StAn.VB_MAIN);   
   double mainAbs = main;
   double mainPrev = StAn.GetHistVal(startBar+barsBack,StAn.VB_MAIN);
   bool lookingForHigher = mainPrev > main;   
   
   int count = 0;
   bool continueRelative = true;
   bool continueAbsolute = true;
   
   while ((continueRelative || continueAbsolute) && startBar + barsBack < StAn.MAX_DATAPOINTS) {
      
      if (continueRelative) {
         if (lookingForHigher && mainPrev > main) {
            lowerNext++;
            higherPrev++;
            StAn.SetHistVal(startBar + barsBack, StAn.VB_LOWER_NEXT_REL, lowerNext);
         }
         else if (lookingForHigher == false && mainPrev <= main) {  
            higherNext++;
            lowerPrev++;
            StAn.SetHistVal(startBar + barsBack, StAn.VB_HIGHER_NEXT_REL, higherNext);      
         } else {
            continueRelative = false;
         }
      }

      if (continueAbsolute) {
         if (lookingForHigher && mainPrev > mainAbs) {
            lowerNextAbs++;
            higherPrevAbs++;
            StAn.SetHistVal(startBar + barsBack, StAn.VB_LOWER_NEXT_ABS, lowerNextAbs);
         }
         else if (lookingForHigher == false && mainPrev <= mainAbs) {  
            higherNextAbs++;
            lowerPrevAbs++;
            StAn.SetHistVal(startBar + barsBack, StAn.VB_HIGHER_NEXT_ABS, higherNextAbs);
         } else {
            continueAbsolute = false;
         }
      }

      
      barsBack = barsBack + 1;
      main = mainPrev;
      mainPrev = StAn.GetHistVal(startBar+barsBack,StAn.VB_MAIN);
      
      
      
   }
   
   StAn.SetHistVal(startBar, StAn.VB_LOWER_PREV_REL, lowerPrev);   
   StAn.SetHistVal(startBar, StAn.VB_HIGHER_PREV_REL, higherPrev);   

   StAn.SetHistVal(startBar, StAn.VB_LOWER_PREV_ABS, lowerPrevAbs);   
   StAn.SetHistVal(startBar, StAn.VB_HIGHER_PREV_ABS, higherPrevAbs);   

}

int StAn.PrevTopBottom(int startBar) {
   
   int barIndex = startBar+1;
   
   while (barIndex < StAn.MAX_DATAPOINTS) {   
      
      if (
      (StAn.GetHistVal(barIndex, StAn.VB_LOWER_PREV_ABS) > 2 && StAn.GetHistVal(barIndex, StAn.VB_LOWER_NEXT_ABS) > 2
      && StAn.GetHistVal(barIndex, StAn.VB_LOWER_PREV_REL) > 0 && StAn.GetHistVal(barIndex, StAn.VB_LOWER_NEXT_REL) > 0)
      ||
      (StAn.GetHistVal(barIndex, StAn.VB_HIGHER_PREV_ABS) > 2 && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_NEXT_ABS) > 2
      && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_PREV_REL) > 0 && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_NEXT_REL) > 0)      
      )
         return (barIndex);
         
      barIndex++;
   }
   
   return(startBar);
}

double StAn.GetHistVal(int barIndex, int valueBucket) {
   return(StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][valueBucket]);
}

void StAn.SetHistVal(int barIndex, int valueBucket, double val) {
   StAn.StochasticHistory[StAn.IndexOfTimePeriod][barIndex][valueBucket] = val;
}