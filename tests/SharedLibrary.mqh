#property strict
//**********************************************************************************************************************
string forbiddenSymbolsAdmirals[] = {"USDZAR-Z", "USDZAR", "USDUAH-Z", "USDUAH", "USDTHB", "USDSGD", "USDSEK", 
                                     "USDRUB", "EURRUB",
                                     "USDRON-Z", "USDPEN", "USDNOK", "USDMXN-Z", "USDMXN", "USDJOD-Z", "USDJOD",
                                     "USDHUF", "USDHRK-Z", "USDHRK", "USDHKD", "USDDKK-Z", "USDCNH-Z", "USDCLP-Z",
                                     "USDCLP", "USDBRL-Z", "USDBRL", "USDBGN-Z", "USDBGN", "USDAED-Z", "USDAED",
                                     "I.USDX", "I.EURX", "GLDUSD", "GBXUSD", "GBPHKD", "EURRON", "EURHKD", 
                                     "BTCEUR", "BTCUSD", "ETHUSD", "LTCUSD", "XRPUSD", "BCHUSD", "LTCEUR"
                                    };                                    
//**********************************************************************************************************************
bool isSymbolForbidden(string symbol)
   {
      for(int i = 0; i < ArraySize(forbiddenSymbolsAdmirals); i++) {
        if(symbol == forbiddenSymbolsAdmirals[i]) {
           return true;
        }
      }
      return false;
   }
//**********************************************************************************************************************                                    
bool isShare(string symbol)
   {
      int firstCharCode = StringGetChar(symbol, 0);
      return firstCharCode == '#';
   }
//**********************************************************************************************************************
bool isIndice(string symbol)
   {
      int firstCharCode = StringGetChar(symbol, 0);
      return firstCharCode == '[';
   }
//**********************************************************************************************************************
int countOpenPositionsForSymbol(string symbol)
{
    int count = 0;
    
    // Przechodzimy przez wszystkie otwarte zlecenia
    for (int i = 0; i < OrdersTotal(); i++)
    {
        // Wybieramy i sprawdzamy konkretne zlecenie
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            // Jeśli symbol zlecenia pasuje do podanego symbolu, zwiększamy licznik
            if (OrderSymbol() == symbol)
            {
                count++;
            }
        }
    }    
    return count;
}   
//**********************************************************************************************************************
bool isRisingTrend(string symbol, 
                   ENUM_TIMEFRAMES tf, 
                   ENUM_MA_METHOD movAveMethod,
                   ENUM_APPLIED_PRICE movAvePrice,
                   int period, 
                   int idxLater, 
                   int idxBefore)
   {
      double movAveBar1 = iMA(symbol, tf, period, idxLater, movAveMethod, movAvePrice, 0);
      double movAveBar2 = iMA(symbol, tf, period, idxBefore, movAveMethod, movAvePrice, 0);
      
      //Print("IS RISING TREND: ");
      //Print("  period: ", tf, "movAveBar1: ", movAveBar1);
      //Print("  period: ", tf, "movAveBar2: ", movAveBar2);
   
      return movAveBar1 > movAveBar2;
   } 
//**********************************************************************************************************************
int getTrendDuration(string symbol, 
                     ENUM_TIMEFRAMES tf, 
                     ENUM_MA_METHOD movAveMethod,
                     ENUM_APPLIED_PRICE movAvePrice,
                     int period)
   {
      double movAveBar1 = iMA(symbol, tf, period, 1, movAveMethod, movAvePrice, 0);
      double movAveBar2 = iMA(symbol, tf, period, 2, movAveMethod, movAvePrice, 0);
      int trendDuration = 0;
      
      while(movAveBar1 > movAveBar2)
        {
         movAveBar1 = iMA(symbol, tf, period, trendDuration + 1, movAveMethod, movAvePrice, 0);
         movAveBar2 = iMA(symbol, tf, period, trendDuration + 2, movAveMethod, movAvePrice, 0);
         trendDuration++;
        }
   
      return trendDuration;
   }
//**********************************************************************************************************************
bool isBarRed(string symbol, ENUM_TIMEFRAMES tf, int idx)
   {
    return iClose(symbol, tf, idx) < iOpen(symbol, tf, idx);
   }
//**********************************************************************************************************************
bool isBarGreen(string symbol, ENUM_TIMEFRAMES tf, int idx)
   {
    return iClose(symbol, tf, idx) > iOpen(symbol, tf, idx);
   }
//**********************************************************************************************************************