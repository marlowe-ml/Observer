//+------------------------------------------------------------------+
//|                                                       basics.mq4 |
//|                                                               JM |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "JM"
#property link      ""

#define NUMPERIODS 9

int AllPeriods[] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1,PERIOD_H4,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
datetime CurrentBarTimes[NUMPERIODS] = {0,0,0,0,0,0,0,0,0};

double StochasticValue(int mode, int timeperiod, int shift=0) {
   return (iStochastic(NULL, timeperiod, 5, 3, 3, MODE_SMA, 0, mode, shift));
}

int TimePeriod(int index) {
   return(AllPeriods[index]);
}

int IndexOfTimePeriod(int timeperiod=0) {
   int index = -1;
   int curPeriod = -1;
   
   while (curPeriod < timeperiod && index < ArraySize(AllPeriods)) {
      index++;
      curPeriod = AllPeriods[index];
   }
   return(index);
}





/*
bool IsNewBar(int timeperiod=0) {
   int tfIndex = IndexOfTimePeriod(timeperiod);
   
   datetime newTime = iTime(NULL, timeperiod, 0);
   
   if (CurrentBarTimes[tfIndex] != newTime) {
      CurrentBarTimes[tfIndex] = newTime;
      return(true);
   }
   
   return(false);
}*/




//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2005

//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);

// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import

//+------------------------------------------------------------------+
//| EX4 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex4"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+