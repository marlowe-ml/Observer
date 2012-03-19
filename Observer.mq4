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

int FixedTimeFrame = 0; //PERIOD_M30;
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
double STOCH_1_DELTA[100];

int MA_1_Period = 14;
int MA_1_Mode = MODE_SMA;
int MA_2_Period = 21;
int MA_2_Mode = MODE_SMA;

int BB_1_Period = 20;
int BB_1_Deviations = 2;
int BB_1_Shift = 0;

int AllPeriods[10] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
datetime CurrentBarTimes[10] = {0,0,0,0,0,0,0,0,0,0,0,0,0};

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



void checkDrawStochInfo(int timeframe) {
      if (isNewBar(timeframe)) {
         double stochInfo[6] = {0,0,0,0,0,0};
         datetime barTime = iTime(NULL, timeframe, 0);
         stochCrossingInfo(timeframe, stochInfo);
         
         int tfIndex = indexOfTimeFrame(timeframe);
         

            // -- label         
            int labelIndex = indexDiffTimeFrame(timeframe);
            if (labelIndex < 0)
               labelIndex = 0;
            else if (labelIndex > 0)
               labelIndex = 2;
            else
               labelIndex = 1;
               
            double diff = stochInfo[4]-stochInfo[2];
            int barsBack = stochInfo[0];
            double priceDiff = iOpen(NULL, timeframe, 0) - iClose(NULL, timeframe, barsBack);
            double stochSlope = (stochInfo[4] - stochInfo[2]) / stochInfo[0]; // ascending / descending slope
            double priceSlope = priceDiff / stochInfo[0];

            color col = Red;

            updateLabel(stochGfx(labelIndex, 0), "ST" + labelIndex);
            updateLabel(stochGfx(labelIndex, 1), "bars: " + barsBack);
            
            if (stochInfo[1] > 0)
               col = Green;               
            updateLabel(stochGfx(labelIndex, 2), " cross: " + strInt(stochInfo[1]), col);
            
            if (stochInfo[2] > 0) col = Green; else col = Red;
               updateLabel(stochGfx(labelIndex, 3), " val: " + str2(stochInfo[2]), col);
            
            if (diff > 0) col = Green; else col = Red;
               updateLabel(stochGfx(labelIndex, 4), " diff: " + str2(diff), col);
            
            if (priceDiff > 0) col = Green; else col = Red;            
               updateLabel(stochGfx(labelIndex, 5), " pdiff: " + str5(priceDiff), col);
            
            if (stochSlope > 0) col = Green; else col = Red;            
               updateLabel(stochGfx(labelIndex, 6), " slope: " + str5(stochSlope), col);
            
            if (priceSlope > 0) col = Green; else col = Red;
               updateLabel(stochGfx(labelIndex, 7), " pslope: " + str5(priceSlope), col);
            // -- label


         if (stochInfo[0] == 1) {
         
            string gfx = nextGfxId();
            col = Red;
            //int symbol = SYMBOL_ARROWDOWN;
            double yPos = BollingerBand_1(MODE_UPPER, 0) - 0.0010 * tfIndex;
            string label = tfIndex;
            
            if (stochInfo[1] > 0) {
               //symbol = SYMBOL_ARROWUP;
               label = label+"+";
               col = Green;
            } else {
               label = label + "-"; 
            }
            
            ObjectCreate(gfx, OBJ_TEXT, 0, barTime, yPos);
            //ObjectSet(gfx, OBJPROP_ARROWCODE, symbol);
            ObjectSetText(gfx, label);
            ObjectSet(gfx, OBJPROP_COLOR, col);
         }
      }
}

void stochCrossingInfo(int timeFrame, double &info[]) {
    // delta sign change
    
    info[0] = 0;
    info[1] = 0;
    info[2] = 0;
    info[3] = 0;
    info[4] = 0;
    info[5] = 0;
    
    int prevTF = FixedTimeFrame;
    FixedTimeFrame = timeFrame;
    
    int barCount = 0;
    
    while (barCount < 50) {
      barCount++;
      double prevK1 = Stochastic_1(MODE_MAIN,barCount);
      double prevD1 = Stochastic_1(MODE_SIGNAL,barCount);

      double prevK2 = Stochastic_1(MODE_MAIN,barCount+1);
      double prevD2 = Stochastic_1(MODE_SIGNAL,barCount+1);
      
      double deltaPrev1 = prevK1 - prevD1;
      double deltaPrev2 = prevK2 - prevD2;      
      
      bool isCrossingUp = deltaPrev1 > 0 && deltaPrev2 < 0;
      bool isCrossingDown = deltaPrev1 < 0 && deltaPrev2 > 0;

      if (isCrossingUp || isCrossingDown) {
         info[0] = barCount;
         info[1] = 1;
         info[2] = Stochastic_1(MODE_MAIN,barCount);
         info[3] = Stochastic_1(MODE_SIGNAL,barCount);
         info[4] = Stochastic_1(MODE_MAIN,0);
         info[5] = Stochastic_1(MODE_SIGNAL,0);            
                     
         if (isCrossingUp) {
            info[1] = 1;
         } else if (isCrossingDown) {
            info[1] = -1;      
         }
         
         break;                  
      }
    }
    
    FixedTimeFrame = prevTF;   
}


void analyze() {

      int lowerTF = relTimeFrame(-1);
      int higherTF = relTimeFrame(+1);

      checkDrawStochInfo(lowerTF);
      checkDrawStochInfo(Period());
      checkDrawStochInfo(higherTF);
      
      
         /*
      if (isNewBar(lowerTF)) {
         barTime = iTime(NULL, lowerTF, 0);
      }*/



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

      /*            
      int stochBarsBack = stochCrossingInfo();
      if (stochBarsBack == 1) {
         drawVLine(Time[stochBarsBack], Purple);
      }*/
         
         

      /*
      double stochScore = stochasticCrossProbability();//stochasticScore();

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
      }*/

   }     
}



double stochasticCrossProbability() {
   double probability = 0;
   
   double deltas[3];
   
   for (int i=1; i<3; i++) {
      double prevK1 = Stochastic_1(MODE_MAIN,i);
      double prevD1 = Stochastic_1(MODE_SIGNAL,i);
      deltas[i-1] = prevK1 - prevD1;   
   }

   if ((deltas[1] > 0 && deltas[0] > 0 ) || (deltas[1] < 0 && deltas[0] < 0)) {   
      if (MathAbs(deltas[1]) > MathAbs(deltas[0])) {
         double diff = MathAbs(deltas[1])-MathAbs(deltas[0]);
         if (diff > 10)
            diff = 10;
         probability += 0.75 * (diff/10.0);
      }
      if ((deltas[2] > 0 && deltas[1] > 0 ) || (deltas[2] < 0 && deltas[1] < 0)) {   
         if (MathAbs(deltas[2]) > MathAbs(deltas[1])) {
            diff = MathAbs(deltas[2])-MathAbs(deltas[1]);
            if (diff > 10)
               diff = 10;
            
            probability += 0.25 * (diff/10.0);
         }
      }
   }

   if (Stochastic_1(MODE_MAIN,0) < Stochastic_1(MODE_SIGNAL,0)) {
      probability *= -1;
   }
   
   
   return(probability);

}





double stochasticScore() {

   // todo: anticipate crossing, current signal is too late
   // allow to pass time frame for signal to get the other timeframe's crossing expectation

   int crossingBarsBack = 0;
   double lastCrossingDirection = 0;

   int barCount = 1;

   // find previous crossing
   while (barCount < 4 || crossingBarsBack == 0) {
      double prevK1 = Stochastic_1(MODE_MAIN,barCount);
      double prevD1 = Stochastic_1(MODE_SIGNAL,barCount);

      double prevK2 = Stochastic_1(MODE_MAIN,barCount+1);
      double prevD2 = Stochastic_1(MODE_SIGNAL,barCount+1);

      double deltaPrev1 = prevK1 - prevD1;
      double deltaPrev2 = prevK2 - prevD2;

      if (deltaPrev1 > 0 && deltaPrev2 < 0) {
         crossingBarsBack = barCount;
         lastCrossingDirection = 1 - (barCount * 0.1); // crossing up
         if (lastCrossingDirection < 0)
            lastCrossingDirection = 0.1;
      } else if (deltaPrev1 < 0 && deltaPrev2 > 0) {
         crossingBarsBack = barCount;
         lastCrossingDirection = -1 + (barCount * 0.1); // crossing down
         if (lastCrossingDirection > 0)
            lastCrossingDirection = -0.1;
         
      }
      
      barCount++;
   }
      
   
   //if (crossingBarsBack)
   
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
      STOCH_1_DELTA[MinimumBars-i] = STOCH_1_DELTA[MinimumBars-i-1];
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
      STOCH_1_DELTA[i] = STOCH_1_K[i]-STOCH_1_D[i];
   }
}



string stochGfx(int i, int j) {
   return("SG_STOCH_CROSS_" + i + "_" + j);
}

void initLabels() {
   
   for (int i=0; i<3; i++) {
      for (int j=0; j<8; j++) {   
         int xDist = j * 80;
         int yDist = 15 * (i+1);
         
         string gfxNameStoch = stochGfx(i,j);
         if (ObjectGet(gfxNameStoch, OBJPROP_XDISTANCE) != xDist)
         {
            ObjectCreate(gfxNameStoch,OBJ_LABEL,0,0,0);
            ObjectSet(gfxNameStoch,OBJPROP_COLOR,Red);
            ObjectSetText(gfxNameStoch,"-" + i + "_" + j, 8, "Arial");
            //ObjectSet(gfxNameStoch, OBJPROP_CORNER, 4);
            ObjectSet(gfxNameStoch, OBJPROP_XDISTANCE, xDist);
            ObjectSet(gfxNameStoch, OBJPROP_YDISTANCE, yDist);
         }
      
      }
   }  
}

void updateLabel(string labelName, string text, color col = CLR_NONE) {
   ObjectSetText(labelName, text);
   if (col != CLR_NONE)
      ObjectSet(labelName, OBJPROP_COLOR, col);     
}



bool isNewBar(int timeFrame=0) {
   int tfIndex = indexOfTimeFrame(timeFrame);
   
   datetime newTime = iTime(NULL, timeFrame, 0);
   
   if (CurrentBarTimes[tfIndex] != newTime) {
      CurrentBarTimes[tfIndex] = newTime;
      return(true);
   }
   
   return(false);
}

/*
bool isNewBar() {
   static datetime currentBarTime = 0;
   if (currentBarTime != Time[0]){
      currentBarTime  = Time[0];
      return(true);
   }
   return(false);
}*/

int indexDiffTimeFrame(int timeframe, int referenceTimeframe=0) {
   if (referenceTimeframe == 0)
      referenceTimeframe  = Period();
      
   int refIndex = indexOfTimeFrame(referenceTimeframe);
   int tfIndex = indexOfTimeFrame(timeframe);
   
   return(refIndex-tfIndex);
   
}


int indexOfTimeFrame(int timeFrame) {
   int index = -1;
   int curPeriod = -1;
   
   while (curPeriod < timeFrame && index < ArraySize(AllPeriods)) {
      index++;
      curPeriod = AllPeriods[index];
   }
   return(index);
}

int relTimeFrame(int diff, int referencePeriod=0) {
   if (referencePeriod == 0)
      referencePeriod = Period();
   
   /*
   int index = -1;
   int curPeriod = -1;
   while (curPeriod < referencePeriod && index < ArraySize(AllPeriods)) {
      index++;
      curPeriod = AllPeriods[index];
   }*/
   
   int index = indexOfTimeFrame(referencePeriod);
   
   
   index = index + diff;
   if (index < 0)
      index = 0;
   
   if (index > ArraySize(AllPeriods)-1)
      index = ArraySize(AllPeriods)-1;
      
   return(AllPeriods[index]);

   
}

void drawVLine(datetime t, color col) {
   string gfxName = nextGfxId();
   ObjectCreate(gfxName,OBJ_VLINE,0,t,0);
   ObjectSet(gfxName,OBJPROP_COLOR,col);
}

string nextGfxId() {
   GFX_ID++;
   return("gfx_" + GFX_ID);
}

string str6(double val) {
   return(DoubleToStr(val, 6));
}
string str5(double val) {
   return(DoubleToStr(val, 5));
}
string str4(double val) {
   return(DoubleToStr(val, 4));
}
string str3(double val) {
   return(DoubleToStr(val, 3));
}
string str2(double val) {
   return(DoubleToStr(val, 2));
}
string str1(double val) {
   return(DoubleToStr(val, 1));
}

string strInt(double val) {
   int v = val;
   return(v);
}


