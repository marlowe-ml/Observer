//+------------------------------------------------------------------+
//|                                          StochasticsAnalysis.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "JM"
#property link      ""

/*
#include <basics.mqh>
#include <drawing.mqh>
*/
#include <StochasticAnalysis.mqh>

int waitNumTicks = 100;
bool Redraw = false;


int init()
  {
  }

int deinit()
  {
   return(0);
  }


int start()
  {
   if (waitNumTicks > 0) {
      waitNumTicks--;
      Alert(waitNumTicks);
      if (waitNumTicks == 0)
         Redraw = true;
   }
      
   StAn.UpdateResultsForTimePeriod(Period());   
  
  
   if (Redraw == true) {
      // verify crossings
      for (int z=0; z<StAn.MAX_DATAPOINTS; z++) {
         if (StAn.GetHV(z, StAn.VB_CROSS_EXHIGH_DOWN) > 0)
         {
            datetime barTime = iTime(NULL, StAn.TimePeriod, z);
            Gfx.DrawVLine(barTime, Red);
         }
      }   
      Redraw = false;
   }
   
   
  
  
   return(0);
  }
//+------------------------------------------------------------------+


