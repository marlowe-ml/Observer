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

int waitNumTicks = 40;
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
      
   StAn.UpdateResultsForTimePeriod(Period());   


   
   checkDraw();   
  
  
   return(0);
  }
  
 
 void checkDraw() {
 
   if (waitNumTicks > 0) {
      waitNumTicks--;
      Alert(waitNumTicks);
      if (waitNumTicks == 0)
         Redraw = true;
   }
  
  
   if (Redraw == true) {
      // verify crossings
      for (int z=0; z<StAn.MAX_DATAPOINTS; z++) {
         drawExtremeCrossing(z);
         drawAvgCrossing(z);
      }   
      Redraw = false;
   }
 
 
 }
 
 
void drawExtremeCrossing(int barIndex) {
   datetime barTime = iTime(NULL, StAn.TimePeriod, barIndex);
   
   if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_DOWN) > 0)
   {  
      Gfx.DrawVLine(barTime, Red);
   }
   else if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_EXLOW_UP) > 0)
   {  
      Gfx.DrawVLine(barTime, Green);
   }
}
 
void drawAvgCrossing(int barIndex) {
   datetime barTime = iTime(NULL, StAn.TimePeriod, barIndex);

   if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_AVG_DOWN) > 0)
   {  
      Gfx.DrawVLine(barTime, Blue);
   }

   else if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_AVG_UP) > 0)
   {  
      Gfx.DrawVLine(barTime, Purple);
   } 
}
 
 
  
//+------------------------------------------------------------------+


