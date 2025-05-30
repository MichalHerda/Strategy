//**********************************************************************************************************************
#property strict
#include "SharedLibrary.mqh"
#include "TradingRestrictions.mqh"
//**********************************************************************************************************************
input double riskPercent = 4; 
input double rrRatio = 2.5;
input int minimumPointsSL = 1500;
/*input*/ ENUM_TIMEFRAMES highTF1 = PERIOD_W1;
/*input*/ ENUM_TIMEFRAMES highTF2 = PERIOD_D1;
/*input*/ ENUM_TIMEFRAMES highTF3 = PERIOD_H1;
/*input*/ ENUM_TIMEFRAMES lowTF = PERIOD_M5;
/*input*/ int highPeriod1 = 10;
/*input*/ int highPeriod2 = 10;
/*input*/ int highPeriod3 = 10;
/*input*/ int lowPeriod = 10;
ENUM_MA_METHOD maMethod = MODE_SMA;
ENUM_APPLIED_PRICE maPrice = PRICE_CLOSE;         
input double stopLossModificator = 5.0;
input double maxSpreadAllowed = 2.0;
datetime lastTradeTime = 0;
int timePassed = 0;
bool isTimeCondition = true;
input int digits = 1;
input bool enableADX = true;
input int adxPeriod = 14;
input int adxFilterValue = 20;
//**********************************************************************************************************************
bool isTradingAllowed()
  {
   int currentHour = TimeHour(TimeCurrent());
   int currentMinute = TimeMinute(TimeCurrent());
   int currentDayOfWeek = DayOfWeek();

   if (currentHour == 15 && isCPIDay()) {
      return false;
   }
   
   if (currentHour == 22 && currentMinute >= 50) {
      return false;
   }
   
   if (currentDayOfWeek == 0 || currentDayOfWeek == 6) {
      return false;
   } 
   
   //if (currentDayOfWeek == 1 && currentHour == 0 && currentMinute < 10) {
   //   return false;
   //}
   
   if (currentHour >= 1 && currentHour < 23) {      
      return true;
   }
   
   return false;
  }
//********************************************************************************************************************** 
void closeAllPositions()
{
   //int currentHour = TimeHour(TimeCurrent());
   //int currentMinute = TimeMinute(TimeCurrent());
   //
   //if ( currentHour == 23 && currentMinute >= 55 )
   //{
      
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
   //}
} 
//********************************************************************************************************************** 
bool checkForLastTradeTimeCondition(int seconds)
   {
      timePassed = int(TimeCurrent() - lastTradeTime);
      //Print("time passed since the last transaction: ", timePassed);
      return timePassed >= seconds;
   }
//**********************************************************************************************************************
bool areHighTFs() 
   {
      //RefreshRates();
      if(//isRisingTrend(Symbol(), highTF1, maMethod, maPrice, highPeriod1, 1, 2) &&   
         //isRisingTrend(Symbol(), highTF2, maMethod, maPrice, highPeriod2, 1, 2) &&
         isRisingTrend(Symbol(), highTF3, maMethod, maPrice, highPeriod3, 0, 1) ) {
            //Print("The required trends are present");
            return true;
      }
      else {
         //Print("The required trends are not present");
         return false;
      }      
   }
//**********************************************************************************************************************
bool isPriceBelowLowMovAve() 
   {
      //RefreshRates();
      if(Ask < iMA(Symbol(), lowTF, lowPeriod, 0, maMethod, maPrice, 0) ) {
         //Print("Ask price below lowTF iMA");
         return true;
      }
      else {
         //Print("Ask price over lowTF iMA");
         return false;
      }
   }   
// oblicz StopLoss na podstawie ostatnich świec    
//**********************************************************************************************************************
double calculateSL()
   {    
    bool isLowestPriceBelowMovAve = true;
    int barIdx = 0;
    double stopLoss = 0;
    
    while(isLowestPriceBelowMovAve) {
      double lowPrice = iLow(Symbol(), lowTF, barIdx);  
      double movAve = iMA(Symbol(), lowTF, lowPeriod, barIdx, maMethod, maPrice, 0);
      if(barIdx != 0) {
         if(lowPrice < stopLoss) {
            stopLoss = lowPrice;            
         }
      }
      else {
         stopLoss = lowPrice;    
      }
      barIdx++;
      if(lowPrice > movAve) isLowestPriceBelowMovAve = false;
    }
    return stopLoss;
   }
//**********************************************************************************************************************
bool isFallingKnife()
   {
    bool isLowestPriceBelowMovAve = true;
    int barIdx = 1;
    double lowestPrice = 0;
    
    while(isLowestPriceBelowMovAve) {
      double lowPrice = iLow(Symbol(), lowTF, barIdx);  
      double movAve = iMA(Symbol(), lowTF, lowPeriod, barIdx, maMethod, maPrice, 0);
      if(barIdx != 1) {
         if(lowPrice < lowestPrice) {
            lowestPrice = lowPrice;            
         }
      }
      else {
         lowestPrice = lowPrice;
      }
      barIdx++;
      if(lowPrice > movAve) isLowestPriceBelowMovAve = false;
    }
    if(lowestPrice >= Ask) {
      Print("falling knife!");
      return true;
    }   
    else {
      Print("there is no falling knife");
      return false;
    }   
   }
//********************************************************************************************************************** 
double calculateLotSize(int pointsSL) 
   {
    // oblicz wielkość pozycji na podstawie podanej wartości StopLoss w punktach
    double balance = AccountBalance();
    double maxStopLoss = balance * riskPercent / 100;
    double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double lotSize = maxStopLoss / (pointsSL * pipValue);
    //Print("account balance: ", balance);
    //Print("maxStopLoss: ", maxStopLoss);
    //Print("Account currency is ", AccountCurrency());
    //Print("pipValue: ", pipValue);
    //Print("lotSize: ", lotSize);
    return NormalizeDouble(lotSize, digits);
   }
//**********************************************************************************************************************
bool isADX()
   {
      if(!enableADX) {
         Print("ADX off");
         return true;
      }
      
      else {
         if(iADX(Symbol(), highTF3, adxPeriod, PRICE_CLOSE, MODE_PLUSDI, 0) >= adxFilterValue) {
            //Print("ADX filter OK");
            return true;
         }
         else {
            //Print("ADX too low");
            return false;
         }     
      }
   }
//**********************************************************************************************************************
bool isValidTradeSetup() 
   {
      if(isTradingAllowed() &&   
         isADX() &&     
         areHighTFs() &&
         isPriceBelowLowMovAve() &&
         isBarGreen(Symbol(), lowTF, 1) &&
         isBarRed(Symbol(), lowTF, 2) &&
         !isFallingKnife()&&
         !isUSMarketHoliday()) {
            Print("Execute trade");
            return true;
      }
      else {
            //Print("No trading conditions");
            return false;
      }   
   }
//**********************************************************************************************************************
int OnInit()
  {
   EventSetTimer(1);  
   
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
   Print("VERSION: 2025.01.12");
   Print("Current spread: ", currentSpread);
   Print("Is indice: ", isIndice(Symbol()));
   Print("Min lot size: ", MarketInfo(Symbol(), MODE_MINLOT));
   Print("Max lot size: ", MarketInfo(Symbol(), MODE_MAXLOT));
   Print("Point: ", Point);
   Print("Margin required per lot: ", MarketInfo(Symbol(), MODE_MARGINREQUIRED));
   Print("Pip value: ", MarketInfo(Symbol(), MODE_TICKVALUE));
   Print("Positions opened on this chart: ", countOpenPositionsForSymbol(Symbol()));
   Print("Symbol name: ", Symbol());
   Print("isIndice: ", isIndice(Symbol()));
    
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
   //rozważ, czy jest konieczne, aby EA działało na OnTick, może OnTimer byłoby wystarczające?
   //warunki handlu:
   //    1. Czy istnieją trendy wysokiego rzędu.
   //    2. Czy cena znajduje się poniżej trendu niskiego rzędu.
   //    3. Czy bar o indeksie 1 był wzrostowy.
   //    4. Czy bar o indeksie 2 był spadkowy.
   //    5. Oblicz SL na podstawie ostatnich barów. Jeśli jest za wąski - zwiększ go.
   //    6. Ustaw TP, w zależności od przyszłych backtestów.
   
   if(isValidTradeSetup()) {
      double stopLoss = calculateSL();
      Print(Symbol(), ": SETUP !");
      double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
      
      if(currentSpread < maxSpreadAllowed && isTimeCondition) {
         Print("current spread is ok");
         stopLoss -= stopLossModificator; //* Point);
         
         int stopLossPoints = (int)MathRound((Ask - stopLoss) / Point);
         //int takeProfitPoints = stopLossPoints * rrRatio;
         
         if(stopLossPoints < minimumPointsSL) {
            stopLoss = Ask - (minimumPointsSL * Point);
            stopLossPoints = minimumPointsSL;
         }    
         
         int takeProfitPoints = (int)MathRound(stopLossPoints * rrRatio);
   
         double takeProfit = Ask + (takeProfitPoints * Point);
   
         double lotSize = calculateLotSize(stopLossPoints);
         if(lotSize > MarketInfo(Symbol(), MODE_MAXLOT)) lotSize = MarketInfo(Symbol(), MODE_MAXLOT);
         if(lotSize < MarketInfo(Symbol(), MODE_MINLOT)) lotSize = MarketInfo(Symbol(), MODE_MINLOT);
         
         Print("calculated SL: ", stopLoss);
         Print("calculated TP: ", takeProfit);
         Print("calculated LotSize: ", lotSize);
         
         if(countOpenPositionsForSymbol(Symbol()) < 1) {
            int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 0, stopLoss, takeProfit);
                          
             if (ticket < 0) {
                 Print("Nie udało się otworzyć zlecenia kupna. Błąd: ", GetLastError());
             } 
             else {
                 Print("Zlecenie kupna otwarte pomyślnie. Ticket: ", ticket);
                 lastTradeTime = TimeCurrent();
             }
         }   
         else {      // <-- if(countOpenPositionsForSymbol(Symbol()) >= 1)
            //Print("The order is already open, only one per chart is allowed");
         }
      }   
      else {      // <-- if(!currentSpread < maxSpreadAllowed) 
         //Print("current spread is to high / not enough time has passed since last trade");
      }
   }
   else {
      //SETUP IS NOT VALID
   }
  }
//**********************************************************************************************************************
void OnTimer()
  {
   int hour = TimeHour(TimeCurrent());
   int minute = TimeMinute(TimeCurrent());
   
   //disable opening more than one trade for one bar
   if(checkForLastTradeTimeCondition(302)){
      //Print("time passed: ", timePassed);
      isTimeCondition = true;
   }
   else {
      isTimeCondition = false;
   }
   
   //close at the and of the day
   if(hour == 23 && minute >= 55) {
      //Print("close at 23:55");
      closeAllPositions();
   }   
   
   //close before CPI event
   if(hour == 15 && minute == 29) {
      closeBeforeCPI();
   }

  }
//**********************************************************************************************************************
