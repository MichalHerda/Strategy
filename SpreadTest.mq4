//+------------------------------------------------------------------+
//|                                                   SpreadTest.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(10);
   
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
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   int availableSymbols = SymbolsTotal(false);
      for(int symbolNo = 0; symbolNo < availableSymbols; symbolNo++) {
               string symbolName = SymbolName(symbolNo, false);
               double spread = MarketInfo(symbolName, MODE_SPREAD);
               double pointSize = MarketInfo(symbolName, MODE_POINT);
               spread *= pointSize;
      
               Print(symbolName, " spread: ", spread);
      }
      ExpertRemove();   
   }      
//+------------------------------------------------------------------+
