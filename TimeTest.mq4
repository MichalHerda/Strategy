//+------------------------------------------------------------------+
//|                                                     TimeTest.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "TradingRestrictions.mqh"
//**********************************************************************************************************************
bool isTradingAllowed()
  {
   int currentHour = TimeHour(TimeCurrent());
   int currentMinute = TimeMinute(TimeCurrent());

   if (currentHour == 22 && currentMinute >= 50) {
      return false;
   }
   
   if (currentHour >= 2 && currentHour < 23) {      
      return true;
   }
   
   return false;
  }
//**********************************************************************************************************************  
void ClosePositionsAtEndOfDay()
{
   int currentHour = TimeHour(TimeCurrent());
   int currentMinute = TimeMinute(TimeCurrent());
   
   if ( currentHour == 9 && currentMinute >= 41 )
   {
      
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            
            if (OrderType() == OP_BUY) {
               bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);
               if (!closed) {
                  Print("Błąd przy zamykaniu pozycji: ", GetLastError());
               }
            }
         }
      }
   }  
}   
//********************************************************************************************************************** 
int OnInit()
  {

   EventSetTimer(5);
   return(INIT_SUCCEEDED);
  }
//**********************************************************************************************************************
void OnDeinit(const int reason)
  {

   EventKillTimer();
   
  }
//**********************************************************************************************************************
void OnTick()
  {

   
  }
//**********************************************************************************************************************
void OnTimer()
  {
 /* 
   Print("Year: ", TimeYear(TimeCurrent()));
   Print("Month: ", TimeMonth(TimeCurrent()));
   Print("Day: ", TimeDay(TimeCurrent()));
   Print("Hour: ", TimeHour(TimeCurrent()));
   Print("Minute: ", TimeMinute(TimeCurrent()));
   Print("Second: ", TimeSeconds(TimeCurrent()));
   Print("Is trading allowed: ", isTradingAllowed());
   Print("Current day of week: ", DayOfWeek());
 */ 
  //ClosePositionsAtEndOfDay();
  //closeBeforeCPI();
  //isUSMarketHoliday();
  }
//**********************************************************************************************************************