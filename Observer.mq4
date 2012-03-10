//+------------------------------------------------------------------+
//|                                                     Observer.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "JM"
#property link      ""


int FixedTimeFrame = PERIOD_M15;
int DebugDecimals = 6;
int MinimumBars = 100;
double MA_1_Values[100]; 
double MA_2_Values[100]; 

int MA_1_Period = 14;
int MA_1_Mode = MODE_SMA;
int MA_2_Period = 21;
int MA_2_Mode = MODE_SMA;

int BB_1_Period = 20;
int BB_1_Deviations = 2;
int BB_1_Shift = 0;

bool IsNewBar = false;


bool FirstTimeInitialized = false;

int Count=0; 
double Spread = 0;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   if (!FirstTimeInitialized) {
      for (int i=0; i<MinimumBars; i++) {
         MA_1_Values[i] = MA_1(i);
         MA_2_Values[i] = MA_2(i);
      }
      FirstTimeInitialized = true;
   }
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
  
  
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   
   if (Bars < MinimumBars) {
      Alert("Not enough bars.");     
      return(0);
   }

   IsNewBar = isNewBar();
   
   Spread = Ask - Bid;
   //Alert("New tick, Price = ", Bid," Spread: ", DoubleToStr(Spread, DebugDecimals));// Alert   

   analyze();
   // trade

   return(0);
  }
//+------------------------------------------------------------------+

double BollingerBand_1(int mode) {
   return (iBands(NULL, FixedTimeFrame, BB_1_Period, BB_1_Deviations, BB_1_Shift, PRICE_CLOSE, mode,0));
}

double MA_1(int numBarsBack) {
   return(iMA(NULL,FixedTimeFrame, MA_1_Period, 0, MA_1_Mode, PRICE_CLOSE, numBarsBack));
}

double MA_2(int numBarsBack) {
   return(iMA(NULL,FixedTimeFrame, MA_2_Period, 0, MA_2_Mode, PRICE_CLOSE, numBarsBack));
}

void onNewBar() {
   // shift history values   
   for (int i=1; i<MinimumBars+1; i++) {
      MA_1_Values[MinimumBars-i] = MA_1_Values[MinimumBars-i-1];
      MA_2_Values[MinimumBars-i] = MA_2_Values[MinimumBars-i-1];
   }
   MA_1_Values[0] = MA_1(0);
   MA_2_Values[0] = MA_2(0);
   
}



void analyze() {

   if (IsNewBar) {
      onNewBar();
   }

   double ma1 = MA_1(0);
   double ma2 = MA_2(0);
   double ma1_prev = MA_1(1);
   double ma2_prev = MA_2(1);
   
   double bb1_main = BollingerBand_1(MODE_MAIN);
   double bb1_upper = BollingerBand_1(MODE_UPPER);
   double bb1_lower = BollingerBand_1(MODE_LOWER);

   bool isLong = true;
   double relevantPrice = 0;

   if (isLong)
      relevantPrice = Bid;
   else
      relevantPrice = Ask;
      
   double ma1Distance = relevantPrice - ma1;
   double ma2Distance = relevantPrice - ma2;
   
   double bb1MainDistance = relevantPrice - bb1_main;
   double bb1UpperDistance = relevantPrice - bb1_upper;
   double bb1LowerDistance = relevantPrice - bb1_lower;

   //Alert("bb1 main: ",DoubleToStr(bb1_main, DebugDecimals));

   double maInterDistance = ma1-ma2;

   if (IsNewBar) {
      Alert("MA distance: ",DoubleToStr(maInterDistance, DebugDecimals));   
   
      if (ma1 > ma2 && ma1_prev < ma2_prev) {
         Alert("Crossing UP!");
      } else if (ma1 < ma2 && ma1_prev > ma2_prev) {
         Alert("Crossing DOWN!");
      }
   }
      
   //Alert("MA1: ",DoubleToStr(ma1, DebugDecimals)," MA2: ",DoubleToStr(ma2, DebugDecimals));
   
   /*
   if (ma1Distance > 0)
   {
      Alert("Price is a above MA(",MA_1_Period,") ",Bid," vs ",ma1);
   } else {
      Alert("Price is a below MA(",MA_1_Period,") ",Bid," vs ",ma1);
   }*/
   
      
}

bool isNewBar() {
   static datetime currentBarTime = 0;
   if (currentBarTime != Time[0]){
      currentBarTime  = Time[0];
      return(true);
   }
   return(false);
   
   
}