//+------------------------------------------------------------------+
//|                                                     Observer.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
/*
[OK] Find actual crossing of MAs
[OK] Detect proximity to bb borders
[OK] Define and detect minimum bb width for trades
[] bb find riding the band situations (number of bars crossing bounds)
[] bb measure slope angle of band close to current bar (breakout vs. retrace)
[] Identify Stochastic level
[] Anticipate MA crossing

[] use pending orders to avoid slippage
*/

#property copyright "JM"
#property link      ""

double BullScore = -100;
double BearScore = -100;

int FixedTimeFrame = PERIOD_M30;
int DebugDecimals = 6;
int MinimumBars = 100;
double MinimumBBWidth = 0.0030;

double PctBandBoundsProximity = 28;


double MA_1_Values[100]; 
double MA_2_Values[100]; 

double BB_1_Main[100];
double BB_1_Lower[100];
double BB_1_Upper[100];
double BB_1_Width[100];
double STOCH_1_K[100];
double STOCH_1_D[100];

int MA_1_Period = 14;
int MA_1_Mode = MODE_SMA;
int MA_2_Period = 21;
int MA_2_Mode = MODE_SMA;

int BB_1_Period = 20;
int BB_1_Deviations = 2;
int BB_1_Shift = 0;



int GFX_ID = 1;

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
      initHistory();
            
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
   
   initLabels();


   IsNewBar = isNewBar();
   if (IsNewBar) {
      onNewBar();
   }
   
   Spread = Ask - Bid;
   //MinimumBBWidth = Spread * 10;
   //Alert("New tick, Price = ", Bid," Spread: ", DoubleToStr(Spread, DebugDecimals));// Alert   

   if (OrdersTotal() > 0) {
      maintainTrade();      
   } else {
      analyze();
   }

   return(0);
  }
//+------------------------------------------------------------------+



void analyze() {
   bool isLong = true;
   double relevantPrice = 0;

   if (isLong)
      relevantPrice = Bid;
   else
      relevantPrice = Ask;

   double ma1 = MA_1_Values[0];
   double ma2 = MA_2_Values[0];   
      
   double ma1Distance = relevantPrice - ma1;
   double ma2Distance = relevantPrice - ma2;
   

   //Alert("bb1 main: ",DoubleToStr(bb1_main, DebugDecimals));

   double maInterDistance = ma1-ma2;

   if (IsNewBar) {
      int bbProx = checkBollingerBandsProximity();
      
      if (bbProx != 0) {
         color lineColor = Purple;

         string gfxName = "Entry" + GFX_ID;
         //ObjectCreate(gfxName,OBJ_VLINE,0,Time[0],0);
         //ObjectSet(gfxName,OBJPROP_COLOR,lineColor);
         GFX_ID = GFX_ID + 1;                             
      }
      
      
      //,":",Stochastic_1(MODE_MAIN));

      double stochScore = stochasticScore();

      ObjectSetText("SG_STOCH_CROSS","ST CR: " + stochScore);

      if (MathAbs(stochScore) > 0.4) {
         int greenValue = 0x0;
         int redValue = 0x0;
         int blueValue = 0x0;
         
         if (stochScore > 0)
            greenValue = (0xFF * stochScore);
         else            
            redValue = (0xFF * (-(stochScore)));

         color stLineColor = (blueValue << 16) | (greenValue << 8) | redValue;
         
         Alert(redValue);

                     
         string gfxNameStoch = "Stoch" + GFX_ID;
         //ObjectCreate(gfxNameStoch,OBJ_TEXT,0,Time[1],BB_1_Upper[0] + 0.0010);
         ObjectCreate(gfxNameStoch,OBJ_VLINE,0,Time[0],0);
         ObjectSet(gfxNameStoch,OBJPROP_COLOR,stLineColor);
         //ObjectSetText(gfxNameStoch,"S");
         GFX_ID = GFX_ID + 1;                    
      }
      
      

   }
      
}

double stochasticScore() {

   // todo: anticipate crossing, current signal is too late
   // allow to pass time frame for signal to get the other timeframe's crossing expectation

   int crossingBarsBack = 1;
   double lastCrossingDirection = 0;

   // find previous crossing
   while (crossingBarsBack < 30) {
      double prevK1 = Stochastic_1(MODE_MAIN,crossingBarsBack);
      double prevD1 = Stochastic_1(MODE_SIGNAL,crossingBarsBack);

      double prevK2 = Stochastic_1(MODE_MAIN,crossingBarsBack+1);
      double prevD2 = Stochastic_1(MODE_SIGNAL,crossingBarsBack+1);

      double deltaPrev1 = prevK1 - prevD1;
      double deltaPrev2 = prevK2 - prevD2;

      if (deltaPrev1 > 0 && deltaPrev2 < 0) {
         lastCrossingDirection = 1 - (crossingBarsBack * 0.2); // crossing up
         break;
      } else if (deltaPrev1 < 0 && deltaPrev2 > 0) {
         lastCrossingDirection = -1 + (crossingBarsBack * 0.2); // crossing down
         break;
      }
      
      crossingBarsBack++;
   }
   
   double K = Stochastic_1(MODE_MAIN,0);
   double D = Stochastic_1(MODE_SIGNAL,0);
   double curDelta = MathAbs(K-D);
   
   if (curDelta > 20)
      curDelta = 20;
   
   return(lastCrossingDirection * (curDelta / 20));
   
   
   /*
   double prevK1 = Stochastic_1(MODE_MAIN,1);
   double prevD1 = Stochastic_1(MODE_SIGNAL,1);

   double prevK2 = Stochastic_1(MODE_MAIN,2);
   double prevD2 = Stochastic_1(MODE_SIGNAL,2);

   double deltaPrev1 = prevK1 - prevD1;
   double deltaPrev2 = prevK2 - prevD2;
   
   //Alert(deltaPrev1," : ",deltaPrev2);

   if (deltaPrev1 > 0 && deltaPrev2 < 0)   
      return(1);
   else if (deltaPrev1 < 0 && deltaPrev2 > 0)
      return(-1);
   */

   //&& Open[1] > Open[0]  -- todo: catch divergence!
   /*
   Alert(prevK2," vs. ",K,(D-K));   
   
   if (longShort < 0 && D-K > 0 && prevK2 > K
   ) {
      return(1);
   } else if (longShort > 0 && K-D > 0 && prevK2 < K
   ) {
      return(-1);
   }
   
   return(0);
   */

}

int checkBollingerBandsProximity() {

   double bb1_main = BB_1_Main[0];
   double bb1_upper = BB_1_Upper[0];
   double bb1_lower = BB_1_Lower[0];


   double bb1Width = bb1_upper - bb1_lower;
   
   if (bb1Width < MinimumBBWidth) {
      Alert("bb width insufficient: ",bb1Width);      
      return;
   }
   
   if (BB_1_Width[0] < BB_1_Width[1] * 1.05 && BB_1_Width[0] < BB_1_Width[2] * 1.10)
      return;
   
   double minProximityBand = bb1Width * (PctBandBoundsProximity/100);   

   double proximityBand = 0;
   double distanceBandMain = 0;      
   //Alert(proximityBand," : ", minProximityBand);

   double weight = 0;

   if (Ask < bb1_main) {
      proximityBand = Ask - bb1_lower;      
      distanceBandMain = bb1_main - Ask;
      weight = 1;
   } else if (Bid > bb1_main && Bid < bb1_upper) {
      proximityBand = bb1_upper - Bid;
      distanceBandMain = Bid - bb1_main;
      weight = -1;
   }

   // todo: 
   // - put into context with previous bars forming out side or inside the band
   // - check if bands have been diverging, have been contracting, or have been forming a rel. stable channel up to now
   // - check if bands indicate clear contraction => probability of retracing vs. breakout
   
   /*
   if (proximityBand <= breakout.minProximityBand && distanceBandMain >= breakout.minDistanceMain) {
      drawLine = true;
      lineColor = Red;
   } else if (proximityBand <= range.minProximityBand && distanceBandMain >= range.minDistanceMain) {
      drawLine = true;
      lineColor = Green;
   }*/
      
   if (proximityBand <= minProximityBand && distanceBandMain > 0.0012) {
      return(weight);
   }
   
   return(0);   
}

int checkMACrossing() {
   int corssingDirection = 0;

   double ma1 = MA_1_Values[0];
   double ma2 = MA_2_Values[0];
   double ma1_prev = MA_1_Values[1];
   double ma2_prev = MA_2_Values[1];

   bool isMACrossing = false;

   if (ma1 > ma2 && ma1_prev <= ma2_prev) {
      return(1);
   } else if (ma1 < ma2 && ma1_prev >= ma2_prev) {
      return(-1);
   }   

   return(0);
   
      /*      
      int crossingDirection = checkMACrossing();      
      
      if (crossingDirection != 0) {
         if (crossingDirection > 0)
            Alert("Crossing UP!");
         if (crossingDirection < 0)
            Alert("Crossing DOWN!");
   
         string gfxName = "MA_Cross_" + GFX_ID;
         ObjectCreate(gfxName,OBJ_VLINE,0,Time[0],0);
         ObjectSet(gfxName,OBJPROP_COLOR,Red);
         GFX_ID = GFX_ID + 1;         
      }*/
   
   /*
   if (ma1Distance > 0)
   {
      Alert("Price is a above MA(",MA_1_Period,") ",Bid," vs ",ma1);
   } else {
      Alert("Price is a below MA(",MA_1_Period,") ",Bid," vs ",ma1);
   }*/
   
   
}




void maintainTrade() {
}

double BollingerBand_1(int mode, int shift=0) {
   return (iBands(NULL, FixedTimeFrame, BB_1_Period, BB_1_Deviations, BB_1_Shift, PRICE_CLOSE, mode,shift));
}

double Stochastic_1(int mode, int shift=0) {
   return (iStochastic(NULL, FixedTimeFrame, 5, 3, 3, MODE_SMA, 0, mode, shift));
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
      
      BB_1_Main[MinimumBars-i] = BB_1_Main[MinimumBars-i-1];
      BB_1_Upper[MinimumBars-i] = BB_1_Upper[MinimumBars-i-1];
      BB_1_Lower[MinimumBars-i] = BB_1_Lower[MinimumBars-i-1];
      BB_1_Width[MinimumBars-i] = BB_1_Width[MinimumBars-i-1];
      STOCH_1_K[MinimumBars-i] = STOCH_1_K[MinimumBars-i-1];
      STOCH_1_D[MinimumBars-i] = STOCH_1_D[MinimumBars-i-1];
   }
   MA_1_Values[0] = MA_1(0);
   MA_2_Values[0] = MA_2(0);
   
   BB_1_Main[0] = BollingerBand_1(MODE_MAIN);
   BB_1_Upper[0] = BollingerBand_1(MODE_UPPER);
   BB_1_Lower[0] = BollingerBand_1(MODE_LOWER);
   BB_1_Width[0] = BB_1_Upper[0] - BB_1_Lower[0];
   
   STOCH_1_K[0] = Stochastic_1(MODE_MAIN);
   STOCH_1_D[0] = Stochastic_1(MODE_SIGNAL);
   
}


void initHistory() {
   for (int i=0; i<MinimumBars; i++) {
      MA_1_Values[i] = MA_1(i);
      MA_2_Values[i] = MA_2(i);
   
      BB_1_Main[i] = BollingerBand_1(MODE_MAIN,i);
      BB_1_Upper[i] = BollingerBand_1(MODE_UPPER,i);
      BB_1_Lower[i] = BollingerBand_1(MODE_LOWER,i);
      BB_1_Width[i] = BB_1_Upper[i] - BB_1_Lower[i];
   
      STOCH_1_K[i] = Stochastic_1(MODE_MAIN,i);
      STOCH_1_D[i] = Stochastic_1(MODE_SIGNAL,i);
   
   }
}



void initLabels() {
   string gfxNameStoch = "SG_STOCH_CROSS";

   if (ObjectGet(gfxNameStoch, OBJPROP_CORNER) != 1)
   {
      ObjectCreate(gfxNameStoch,OBJ_LABEL,0,0,0);
      ObjectSet(gfxNameStoch,OBJPROP_COLOR,Black);
      ObjectSetText(gfxNameStoch,"ST CR: " + 0);
      ObjectSet(gfxNameStoch, OBJPROP_CORNER, 1);
      ObjectSet(gfxNameStoch, OBJPROP_XDISTANCE, 30);
      ObjectSet(gfxNameStoch, OBJPROP_YDISTANCE, 0);
   }
}



bool isNewBar() {
   static datetime currentBarTime = 0;
   if (currentBarTime != Time[0]){
      currentBarTime  = Time[0];
      return(true);
   }
   return(false);
   
   
}