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
         datetime barTime = iTime(NULL, StAn.TimePeriod, z);
         //drawExtremeCrossing(z, barTime);
         //drawAvgCrossing(z, barTime);
         drawTopsAndBottoms(z, barTime);
      }
      drawPreviousTopBottom();
      Redraw = false;
   }
 
 
 }
 
 
void drawExtremeCrossing(int barIndex, datetime barTime) {
   if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_EXHIGH_DOWN) > 0)
   {  
      Gfx.DrawVLine(barTime, Red);
   }
   else if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_EXLOW_UP) > 0)
   {  
      Gfx.DrawVLine(barTime, Green);
   }
}
 
void drawAvgCrossing(int barIndex, datetime barTime) {
   if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_AVG_DOWN) > 0)
   {  
      Gfx.DrawVLine(barTime, Blue);
   }

   else if (StAn.GetHistVal(barIndex, StAn.VB_CROSS_AVG_UP) > 0)
   {  
      Gfx.DrawVLine(barTime, Purple);
   }
}

void drawTurningPoints(int barIndex, datetime barTime) {
   if (StAn.GetHistVal(barIndex, StAn.VB_TURN_DOWN) > 0)
   {  
      Gfx.DrawVLine(barTime, Red);
   }

   else if (StAn.GetHistVal(barIndex, StAn.VB_TURN_UP) > 0)
   {  
      Gfx.DrawVLine(barTime, Green);
   }
}

void drawTopsAndBottoms(int barIndex, datetime barTime) {
   if (StAn.GetHistVal(barIndex, StAn.VB_LOWER_PREV_ABS) > 2 && StAn.GetHistVal(barIndex, StAn.VB_LOWER_NEXT_ABS) > 2
      && StAn.GetHistVal(barIndex, StAn.VB_LOWER_PREV_REL) > 0 && StAn.GetHistVal(barIndex, StAn.VB_LOWER_NEXT_REL) > 0
   )
   {  
      Gfx.DrawVLine(barTime, Red);
   }
   else if (StAn.GetHistVal(barIndex, StAn.VB_HIGHER_PREV_ABS) > 2 && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_NEXT_ABS) > 2
      && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_PREV_REL) > 0 && StAn.GetHistVal(barIndex, StAn.VB_HIGHER_NEXT_REL) > 0
   )
   {  
      Gfx.DrawVLine(barTime, Green);
   }
}

void drawPreviousTopBottom() {
   int prevBar = StAn.PrevTopBottom(0);
   double barTime = iTime(NULL, StAn.TimePeriod, prevBar);
   Gfx.DrawVLine(barTime, Blue);
}
 
 
  
//+------------------------------------------------------------------+


