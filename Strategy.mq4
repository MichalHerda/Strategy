//+------------------------------------------------------------------+
//|                                                     Strategy.mq4 |
//|                                              Copyright 2024, MH. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

#include "SharedLibrary.mqh"

input ENUM_TIMEFRAMES highTF1 = PERIOD_W1;
input ENUM_TIMEFRAMES highTF2 = PERIOD_D1;
input ENUM_TIMEFRAMES highTF3 = PERIOD_H1;
input int highPeriod1 = 10;
input int highPeriod2 = 10;
input int highPeriod3 = 10;
ENUM_MA_METHOD maMethod = MODE_SMA;
ENUM_APPLIED_PRICE maPrice = PRICE_CLOSE;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
//   EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(isRisingTrend(Symbol(), highTF1, maMethod, maPrice, highPeriod1, 1, 2) &&   
      isRisingTrend(Symbol(), highTF2, maMethod, maPrice, highPeriod2, 1, 2) &&
      isRisingTrend(Symbol(), highTF3, maMethod, maPrice, highPeriod3, 1, 2) ) {
         Print("Obecnie są warunki do handlu");
      }
      else {
         Print("Nie ma warunków do handlu");
      }      
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
