#property strict
#include "SharedLibrary.mqh"
//**********************************************************************************************************************
input double riskPercent = 4; 
input double rrRatio = 2.5;
input int minimumPointsSL = 1500;
input ENUM_TIMEFRAMES highTF1 = PERIOD_W1;
input ENUM_TIMEFRAMES highTF2 = PERIOD_D1;
input ENUM_TIMEFRAMES highTF3 = PERIOD_H1;
input ENUM_TIMEFRAMES lowTF = PERIOD_M5;
input int highPeriod1 = 10;
input int highPeriod2 = 10;
input int highPeriod3 = 10;
input int lowPeriod = 10;
ENUM_MA_METHOD maMethod = MODE_SMA;
ENUM_APPLIED_PRICE maPrice = PRICE_CLOSE;
input int spreadModificator = 2;
input double stopLossModificator = 3.8;
//**********************************************************************************************************************
bool areHighTFs() 
   {
      //RefreshRates();
      if(isRisingTrend(Symbol(), highTF1, maMethod, maPrice, highPeriod1, 1, 2) &&   
         isRisingTrend(Symbol(), highTF2, maMethod, maPrice, highPeriod2, 1, 2) &&
         isRisingTrend(Symbol(), highTF3, maMethod, maPrice, highPeriod3, 1, 2) ) {
            Print("The required trends are present");
            return true;
      }
      else {
         Print("The required trends are not present");
         return false;
      }      
   }
//**********************************************************************************************************************
int OnInit()
  {

   return(INIT_SUCCEEDED);
  }
//**********************************************************************************************************************
void OnDeinit(const int reason)
  {
   
  }
//**********************************************************************************************************************
void OnTick()
  {
   areHighTFs();
  }
//**********************************************************************************************************************
