
#property strict

//**********************************************************************************************************************

bool isShare(string symbol)
{
   int firstCharCode = StringGetChar(symbol, 0);
   return firstCharCode == '#';
}

//**********************************************************************************************************************

bool isRisingTrend(string symbol, 
                   ENUM_TIMEFRAMES tf, 
                   ENUM_MA_METHOD maMethod,
                   ENUM_APPLIED_PRICE maPrice,
                   int period, 
                   int idxLater, 
                   int idxBefore)
{
   double movAveBar1 = iMA(symbol, tf, period, idxLater, maMethod, maPrice, 0);
   double movAveBar2 = iMA(symbol, tf, period, idxBefore, maMethod, maPrice, 0);

   return movAveBar1 > movAveBar2;
}

//**********************************************************************************************************************

int getTrendDuration(string symbol, 
                     ENUM_TIMEFRAMES tf, 
                     ENUM_MA_METHOD maMethod,
                     ENUM_APPLIED_PRICE maPrice,
                     int period)
{
   double movAveBar1 = iMA(symbol, tf, 5, 1, maMethod, maPrice, 0);
   double movAveBar2 = iMA(symbol, tf, 5, 2, maMethod, maPrice, 0);
   int trendDuration = 0;
   
   while(movAveBar1 > movAveBar2)
     {
      movAveBar1 = iMA(symbol, tf, period, trendDuration + 1, maMethod, maPrice, 0);
      movAveBar2 = iMA(symbol, tf, period, trendDuration + 2, maMethod, maPrice, 0);
      trendDuration++;
     }

   return trendDuration;
}

//**********************************************************************************************************************