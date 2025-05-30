#property strict
#include "SharedLibrary.mqh"
//**********************************************************************************************************************
input double riskPercent = 4.0; 
input double rrRatio = 2.5;
input double initialAccountBalance = 1500;
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
//input int spreadModificator = 2;
input double stopLossModificator = 5.0;
input int startTradingHour = 1;
input int stopTradingHour = 22;
input int stopTradingMinute = 50;
input int adxPeriod = 14;
input int adxFilterValue = 20;
input int rsiPeriod = 14;
input int rsiFilterValue = 35;
//**********************************************************************************************************************
enum tradeResult
  {
   TP,
   SL,
   NONE
  };
//**********************************************************************************************************************
struct testRecord 
  {
   datetime timeStamp;
   int currentHighTFBarIdx;
   double previousBarMovAve;
   double movingAverageOnFlyOpen;
   double movingAverageOnFlyHigh;
   double lowMovAveOnFlyOpen;
   double lowMovAveOnFlyLow;
   bool isTrendOnOpenPrice;
   bool isTrendOnHighPrice;
   bool areHighTFs;
   bool areLowTFConditions;
   bool isTradeOpen;
   bool isSetup;
   double openTradePrice;
   double closeTradePrice;
   double stopLoss;
   double takeProfit;
   double lotSize;
   bool reachedSL;
   bool reachedTP;
   double balance;
   double openBarPrice;
   double closeBarPrice;
   double highBarPrice;
   double lowBarPrice;
   double stopLossValue;
   double takeProfitValue;
   tradeResult result;
   double adxFilter;
   double rsiFilter;
  };
//**********************************************************************************************************************
struct trendDirection
  {
   datetime time;
   int currentLowBarIdx;
   bool isLowTrendRising;
   bool isMediumTrendRising;
   bool isHighTrendRising;
  };
//**********************************************************************************************************************
struct trade
   {
    int number;
    datetime openTime;
    datetime closeTime;
    double openPrice;
    double closePrice;
    tradeResult result;
    double financialResult;
    double balance;
   };
//**********************************************************************************************************************
testRecord testRecordArray[];
trendDirection trendDirectionArray[];
trade tradesArray[];
//**********************************************************************************************************************
double calculateZeroBarMovAve(double currentValue, int period, int idx, ENUM_TIMEFRAMES tf)
{
   Print("idx: ", idx, " currentValue: ", currentValue, " period: ", period, " tf: ", tf); 
   double sum = 0;
   for(int i = idx + 1; i < idx + period; i++) {
      double closePrice = iClose(Symbol(), tf, i); 
      datetime barTime = iTime(Symbol(), tf, i);
      Print(" index: ",  i, " time; ", barTime, " iClose: ", closePrice);
      sum += closePrice;                         //iClose(Symbol(), tf, i);     
   } 
   sum += currentValue;
   double movAve = NormalizeDouble(sum/period, 2);
   
   Print("sum: ", sum);
   Print("ma: ", movAve);
   return movAve;
}
//**********************************************************************************************************************
bool checkForHighTFConditions(int idx)
  {
     return //trendDirectionArray[idx].isHighTrendRising &&
            //trendDirectionArray[idx].isMediumTrendRising &&
            trendDirectionArray[idx].isLowTrendRising;
  }
//********************************************************************************************************************** 
bool areTradingHours(datetime timeStamp)
  {
   int currentHour = TimeHour(timeStamp);
   int currentMinute = TimeMinute(timeStamp);
   
   if (currentHour == 22 && currentMinute >= 50) {
      return false;
   }
   
   if (currentHour >= startTradingHour && currentHour < stopTradingHour) {      
      return true;
   }
   
   return false;
  
  }
//********************************************************************************************************************** 
bool checkForLowTFConditions(int idx)
  {
     double movAve = iMA(Symbol(), lowTF, lowPeriod, idx, maMethod, maPrice, 0);
     double lowestPrice = iLow(Symbol(), lowTF, idx);
     
     return lowestPrice < movAve;
  }  
//**********************************************************************************************************************   
double calculateSL(int idx)
   {    
    bool isLowestPriceBelowMovAve = true;
    int barIdx = idx;
    double stopLoss = 0;
    
    while(isLowestPriceBelowMovAve) {
      double lowPrice = iLow(Symbol(), lowTF, barIdx);  
      double movAve = iMA(Symbol(), lowTF, lowPeriod, barIdx, maMethod, maPrice, 0);
      if(barIdx != idx) {
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
double calculateLotSize(int pointsSL, double accountBalance) 
   {
    // oblicz wielkość pozycji na podstawie podanej wartości StopLoss w punktach
    double balance = accountBalance;  //AccountBalance();
    double maxStopLoss = balance * riskPercent / 100;
    double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    double lotSize = maxStopLoss / (pointsSL * pipValue);
    //Print("account balance: ", balance);
    //Print("maxStopLoss: ", maxStopLoss);
    //Print("Account currency is ", AccountCurrency());
    //Print("pipValue: ", pipValue);
    //Print("lotSize: ", lotSize);
    return lotSize;
   }
//**********************************************************************************************************************  
bool isRisingTrend(string symbol, ENUM_TIMEFRAMES tf, int period, int idxLater, int idxBefore)
  {
   double movAveBar1 = iMA(symbol, tf, period, idxLater, MODE_SMA, PRICE_CLOSE, 0);
   double movAveBar2 = iMA(symbol, tf, period, idxBefore, MODE_SMA, PRICE_CLOSE, 0);

   return movAveBar1 > movAveBar2;
  }
//**********************************************************************************************************************  
void appendTrendDirectionArray(ENUM_TIMEFRAMES lowestTimeFrame, ENUM_TIMEFRAMES lowTimeFrame, 
                               ENUM_TIMEFRAMES mediumTimeFrame, ENUM_TIMEFRAMES highTimeFrame,
                               int lowTimeFramePeriod, int mediumTimeFramePeriod, int highTimeFramePeriod)
  {
    ArrayResize(trendDirectionArray, 0);
    
    //debugging and tests:
    int allBarsAvailable = iBars(Symbol(), lowestTimeFrame);
    int firstBarIdx = allBarsAvailable - lowTimeFramePeriod - 1;    
    datetime firstBarDate = iTime(Symbol(), lowestTimeFrame, firstBarIdx);
    double firstBarClose = iClose(Symbol(), lowestTimeFrame, firstBarIdx);
    
    //Print("appendTrendDirectionArray: ");
    //Print("    all bars available: ", allBarsAvailable);
    //Print("    firstBarIdx: ", firstBarIdx);
    //Print("    firstBarDate: ", firstBarDate);
    //Print("    firstBarClose: ", firstBarClose);
    
    //append array:
    for(int i = firstBarIdx; i > 0; i--) {
    
      datetime lowestTimeFrameBarTime = iTime(Symbol(), lowestTimeFrame, i);
      
      int lowTimeFrameBarShift = iBarShift(Symbol(), lowTimeFrame, lowestTimeFrameBarTime);
      //int mediumTimeFrameBarShift = iBarShift(Symbol(), mediumTimeFrame, lowestTimeFrameBarTime);
      //int highTimeFrameBarShift = iBarShift(Symbol(), highTimeFrame, lowestTimeFrameBarTime);
      
      datetime lowTimeFrameBarDate = iTime(Symbol(), lowTimeFrame, lowTimeFrameBarShift);
      //datetime mediumTimeFrameBarDate = iTime(Symbol(), mediumTimeFrame, mediumTimeFrameBarShift);
      //datetime highTimeFrameBarDate = iTime(Symbol(), highTimeFrame, highTimeFrameBarShift);
           
      bool isLowTrendRising = isRisingTrend(Symbol(), lowTimeFrame, lowTimeFramePeriod, lowTimeFrameBarShift,
                                            lowTimeFrameBarShift + 1);
      //bool isMediumTrendRising = isRisingTrend(Symbol(), mediumTimeFrame, mediumTimeFramePeriod, mediumTimeFrameBarShift,
      //                                         mediumTimeFrameBarShift + 1);
      //bool isHighTrendRising = isRisingTrend(Symbol(), highTimeFrame, highTimeFramePeriod, highTimeFrameBarShift,
      //                                       highTimeFrameBarShift +1);                             
      /*                                                                            
      Print("bar: ", i, " time: ", lowTimeFrameBarTime, " medium tf bar: ", mediumTimeFrameBarShift,
            " medium tf date: ", mediumTimeFrameBarDate, " high tf bar: ", highTimeFrameBarShift,
            " high tf date: ", highTimeFrameBarDate, " isLowTrendRising: ", isLowTrendRising,
            " isMediumTrendRising: ", isMediumTrendRising, " isHighTrendRising: ", isHighTrendRising);
      */      
      ArrayResize(trendDirectionArray, ArraySize(trendDirectionArray) + 1);
      int currentIdx = ArraySize(trendDirectionArray) - 1;
      trendDirectionArray[currentIdx].time = lowestTimeFrameBarTime;
      trendDirectionArray[currentIdx].currentLowBarIdx = lowTimeFrameBarShift;
      //trendDirectionArray[currentIdx].isHighTrendRising = isHighTrendRising;
      //trendDirectionArray[currentIdx].isMediumTrendRising = isMediumTrendRising;
      trendDirectionArray[currentIdx].isLowTrendRising = isLowTrendRising;
    }
    
    //write to file:
    int fileHandle = FileOpen("TESTER_trendDirectionArray" + Symbol(), FILE_WRITE);
      
      if(fileHandle != INVALID_HANDLE) {
         for(int i = 0; i < ArraySize(trendDirectionArray); i++) {
            FileWrite(fileHandle, i, trendDirectionArray[i].time,
                      " lowTfBarShift: ", trendDirectionArray[i].currentLowBarIdx,
                      " isLowTrendRising: ", trendDirectionArray[i].isLowTrendRising);
                      //" isMediumTrendRising: ", trendDirectionArray[i].isMediumTrendRising,
                      //" isHighTrendRising: ", trendDirectionArray[i].isHighTrendRising);
         }
         FileClose(fileHandle);
      }
      else {
         Print("FAILED TO SAVE FILE");   
      }    
  }
//**********************************************************************************************************************  
void appendTestRecordArray()
  {
    ArrayResize(testRecordArray, 0);
    double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
    double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
    
    double accountBalance = initialAccountBalance;
    
    bool isTradeOpen = false;
    double stopLossValue = 0;
    double takeProfitValue = 0;
    double lotSize = 0;
    
    double stopLoss = 0;
    double takeProfit = 0;
    double openTradePrice = 0;
    double closeTradePrice = 0;    
    
    for (int i = 0, barIdx = ArraySize(trendDirectionArray);             // właściwa pętla
         i <= ArraySize(trendDirectionArray) - 1; i++, barIdx--) {
         
    //for (int i = 0, barIdx = ArraySize(trendDirectionArray);           // testowa pętla 
    //     i <= 5000; i++, barIdx--) {      
         
      //Print("test: ", i);
      ArrayResize(testRecordArray, ArraySize(testRecordArray) + 1);
           
      datetime timeStamp = trendDirectionArray[i].time;
           
      bool reachedTP = false;
      bool reachedSL = false;
                 
      testRecordArray[i].timeStamp = timeStamp;
      testRecordArray[i].currentHighTFBarIdx = trendDirectionArray[i].currentLowBarIdx;    // h1 bar
      testRecordArray[i].previousBarMovAve = iMA(Symbol(), highTF3, highPeriod3, testRecordArray[i].currentHighTFBarIdx + 1,
                                                 maMethod, maPrice, 0);
                                                            
      testRecordArray[i].openBarPrice = iOpen(Symbol(), lowTF, barIdx);
      testRecordArray[i].closeBarPrice = iClose(Symbol(), lowTF, barIdx);
      testRecordArray[i].highBarPrice = iHigh(Symbol(), lowTF, barIdx);
      testRecordArray[i].lowBarPrice = iLow(Symbol(), lowTF, barIdx);
      
      double adxFilter = iADX(Symbol(), highTF3, adxPeriod, PRICE_CLOSE, MODE_PLUSDI, testRecordArray[i].currentHighTFBarIdx);
      testRecordArray[i].adxFilter = adxFilter;
      
      double rsiFilter = iRSI(Symbol(), lowTF, rsiPeriod, PRICE_CLOSE, barIdx);
      testRecordArray[i].rsiFilter = rsiFilter;
      
      Print("calculate high moving average on fly: ");
      double movingAverageOnFlyOpen = calculateZeroBarMovAve(testRecordArray[i].openBarPrice, highPeriod3, testRecordArray[i].currentHighTFBarIdx, highTF3);
      double movingAverageOnFlyHigh = calculateZeroBarMovAve(testRecordArray[i].highBarPrice, highPeriod3, testRecordArray[i].currentHighTFBarIdx, highTF3);
      
      testRecordArray[i].movingAverageOnFlyOpen = movingAverageOnFlyOpen;
      testRecordArray[i].movingAverageOnFlyHigh = movingAverageOnFlyHigh;
            
      Print("calculate low moving average on fly: ");
      double lowMovAveOnFlyOpen = calculateZeroBarMovAve(testRecordArray[i].openBarPrice, lowPeriod, barIdx, lowTF);
      double lowMovAveOnFlyLow = calculateZeroBarMovAve(testRecordArray[i].lowBarPrice, lowPeriod, barIdx, lowTF);
      
      testRecordArray[i].lowMovAveOnFlyOpen = lowMovAveOnFlyOpen;
      testRecordArray[i].lowMovAveOnFlyLow = lowMovAveOnFlyLow;
      
      bool areLowTFConditions; // = checkForLowTFConditions(barIdx);
      
      if(testRecordArray[i].openBarPrice <= lowMovAveOnFlyOpen ||
         testRecordArray[i].lowBarPrice <= lowMovAveOnFlyLow ) {
         areLowTFConditions = true;
      }
      else {
         areLowTFConditions = false;
      }
      
      testRecordArray[i].areLowTFConditions = areLowTFConditions;
      
      if(testRecordArray[i].previousBarMovAve <= movingAverageOnFlyOpen) {
            testRecordArray[i].isTrendOnOpenPrice = true;
      }
      else {
            testRecordArray[i].isTrendOnOpenPrice = false;
      }     
      
      if(testRecordArray[i].previousBarMovAve <= movingAverageOnFlyHigh) {
            testRecordArray[i].isTrendOnHighPrice = true;
      }
      else {
            testRecordArray[i].isTrendOnHighPrice = false;
      }                                                               
        
      //bool areHighTFs = checkForHighTFConditions(i);   
      if( (testRecordArray[i].isTrendOnOpenPrice) || (testRecordArray[i].isTrendOnHighPrice) ) {
         testRecordArray[i].areHighTFs = true;
      }
      else {
         testRecordArray[i].areHighTFs = false;
      }                                                         
           
      if(!isTradeOpen) {
         if((testRecordArray[i].areHighTFs) && areLowTFConditions) {
            if(isBarGreen(Symbol(), lowTF, barIdx + 1) &&
               isBarRed(Symbol(), lowTF, barIdx + 2) &&
               adxFilter >= adxFilterValue &&
               //rsiFilter <= rsiFilterValue &&
               areTradingHours(timeStamp)){
               
                  //Print("OPEN TRADE, time: ", testRecordArray[i].timeStamp);
                  testRecordArray[i].isSetup = true;
                  double openBarPrice = testRecordArray[i].openBarPrice;
                  
                  //stopLoss = calculateSL(barIdx) - (currentSpread * spreadModificator);   
                  stopLoss = calculateSL(barIdx) - stopLossModificator; //* Point);
                              
                  int stopLossPoints = (int)MathRound((openBarPrice - stopLoss) / Point);
                  if(stopLossPoints < minimumPointsSL) {
                     stopLoss = openBarPrice - (minimumPointsSL * Point);
                     stopLossPoints = minimumPointsSL;
                  }                 
                  testRecordArray[i].stopLoss = stopLoss;
                  if(testRecordArray[i].isTrendOnOpenPrice) {
                     if(openBarPrice <= lowMovAveOnFlyOpen) {
                        openTradePrice = openBarPrice;
                     }
                     else {
                        openTradePrice = testRecordArray[i].lowBarPrice;
                     }
                  }
                  if(testRecordArray[i].isTrendOnHighPrice) {
                    openTradePrice = testRecordArray[i].highBarPrice;
                  }  
                  
                  int takeProfitPoints = (int)MathRound(stopLossPoints * rrRatio);
                  double takeProfitPips = takeProfitPoints * Point;
                  takeProfit = testRecordArray[i].openBarPrice + takeProfitPips;
                  
                  int lotSizeDecimalPlaces = 2;
                  if(isIndice(Symbol())) lotSizeDecimalPlaces = 1;
                  
                  lotSize = NormalizeDouble(calculateLotSize(stopLossPoints, accountBalance), lotSizeDecimalPlaces);
                  
                  if(lotSize > MarketInfo(Symbol(), MODE_MAXLOT)) lotSize = MarketInfo(Symbol(), MODE_MAXLOT);
                  if(lotSize < MarketInfo(Symbol(), MODE_MINLOT)) lotSize = MarketInfo(Symbol(), MODE_MINLOT);
                  
                  stopLossValue = NormalizeDouble(stopLossPoints * pipValue * lotSize, 2);
                  takeProfitValue = NormalizeDouble(takeProfitPoints * pipValue * lotSize, 2);
                                                                  
                  testRecordArray[i].takeProfit = takeProfit;
                  testRecordArray[i].lotSize = lotSize;
                  testRecordArray[i].stopLossValue = stopLossValue;
                  testRecordArray[i].takeProfitValue = takeProfitValue;
                  //testRecordArray[i].balance = accountBalance;
                  //Print("  TP: ", takeProfit);
                  //Print("  SL: ", stopLoss);
                  //Print("  LotSize: ", lotSize);
                  isTradeOpen = true;
               }        // <--- are low bars conditions
               else {   // <--- if low time conditions == true, low bars conditions = false 
                  
               }
               testRecordArray[i].isTradeOpen = isTradeOpen;
               testRecordArray[i].balance = accountBalance;
               testRecordArray[i].openTradePrice = openTradePrice;
         }              // <--- are low timeframe conditions
         else {         // <--  else if(areHighTFs && areLowTFConditions) == false
               testRecordArray[i].balance = accountBalance;
               testRecordArray[i].isTradeOpen = isTradeOpen;
         }
         
      }        // <--- !isTradeOpen
      else {   // <--- else if(isTradeOpen)
         testRecordArray[i].isSetup = false;
         testRecordArray[i].isTradeOpen = isTradeOpen;
         if(stopLoss >= testRecordArray[i].lowBarPrice) {
            //Print("stopLoss has been reached");
            accountBalance -= stopLossValue;
            testRecordArray[i].closeTradePrice = stopLoss;
            stopLoss = 0;
            takeProfit = 0;
            //stopLossValue = 0;
            //takeProfitValue = 0;
            openTradePrice = 0;
            reachedSL = true;
            isTradeOpen = false;
            testRecordArray[i].balance = accountBalance;
            testRecordArray[i].takeProfit = takeProfit;
            testRecordArray[i].lotSize = lotSize;
            testRecordArray[i].stopLossValue = stopLossValue;
            testRecordArray[i].takeProfitValue = takeProfitValue;
            testRecordArray[i].reachedSL = reachedSL;
            testRecordArray[i].reachedTP = reachedTP;
            stopLossValue = 0;
            takeProfitValue = 0;
            continue;
         }  
         if(takeProfit <= testRecordArray[i].highBarPrice) {
            //Print("takeProfit has been reached");
            accountBalance += takeProfitValue;            
            testRecordArray[i].closeTradePrice = takeProfit;
            stopLoss = 0;
            takeProfit = 0;
            //stopLossValue = 0;
            //takeProfitValue = 0;
            openTradePrice = 0;
            reachedTP = true;
            isTradeOpen = false;
            testRecordArray[i].balance = accountBalance;
            testRecordArray[i].takeProfit = takeProfit;
            testRecordArray[i].lotSize = lotSize;
            testRecordArray[i].stopLossValue = stopLossValue;
            testRecordArray[i].takeProfitValue = takeProfitValue;
            testRecordArray[i].reachedSL = reachedSL;
            testRecordArray[i].reachedTP = reachedTP;
            takeProfit = 0;
            stopLossValue = 0;
            continue;
         }
         testRecordArray[i].balance = accountBalance;
         testRecordArray[i].takeProfit = takeProfit;
         testRecordArray[i].lotSize = lotSize;
         testRecordArray[i].stopLossValue = stopLossValue;
         testRecordArray[i].takeProfitValue = takeProfitValue;
         testRecordArray[i].openTradePrice = openTradePrice;         
      }
                   
    } //    <--- loop brace
    
    int fileHandle = FileOpen("TESTER_testRecordArray" + Symbol(), FILE_WRITE);
    
    if(fileHandle != INVALID_HANDLE) {
      FileWrite(fileHandle, Symbol(), "\nSETTINGS: \n", "RISK PERCENT: ", riskPercent, "\n",
                "RRR: ", rrRatio, "\n", "INITIAL ACCOUNT BALANCE: ", initialAccountBalance, "\n",
                "MINIMUM SL: ", minimumPointsSL, "\n",
                "STOP LOSS MODIFICATOR: ", stopLossModificator, "\n\n\n"); 
      for(int i = 0; i < ArraySize(testRecordArray); i++) {
         FileWrite(fileHandle, //i + 1,
                   "*******************************************************************************************\n",
                   i, "\n",
                   testRecordArray[i].timeStamp, "\n",
                   "previousBarMovAve", testRecordArray[i].previousBarMovAve, "\n",
                   "movAveOnFlyOpen", testRecordArray[i].movingAverageOnFlyOpen,
                   "movAveOnFlyHigh", testRecordArray[i].movingAverageOnFlyHigh,
                   "isTrendOnOpenPrice", testRecordArray[i].isTrendOnOpenPrice,
                   "isTrendOnHighPrice", testRecordArray[i].isTrendOnHighPrice, "\n",
                   "isTradeOpen", testRecordArray[i].isTradeOpen,
                   "High coonditions", testRecordArray[i].areHighTFs,
                   "lowConditions", testRecordArray[i].areLowTFConditions, 
                   "IS SETUP", testRecordArray[i].isSetup, "\n",
                   "O", testRecordArray[i].openBarPrice,
                   "C", testRecordArray[i].closeBarPrice,
                   "H", testRecordArray[i].highBarPrice,
                   "L", testRecordArray[i].lowBarPrice, "\n",                   
                   "SL", testRecordArray[i].stopLoss,
                   "TP", testRecordArray[i].takeProfit,
                   "Lot", testRecordArray[i].lotSize, "\n",
                   "Open", testRecordArray[i].openTradePrice,
                   "Close", testRecordArray[i].closeTradePrice,
                   "SL Value", testRecordArray[i].stopLossValue,
                   "TP Value", testRecordArray[i].takeProfitValue,   
                   "reachedSL", testRecordArray[i].reachedSL,
                   "reachedTP", testRecordArray[i].reachedTP, "\n",  
                   "adxFilter", testRecordArray[i].adxFilter,
                   "rsiFilter", testRecordArray[i].rsiFilter, "\n",              
                   "    BALANCE", testRecordArray[i].balance,
                   "\n\n\n" 
                   );
      }
      FileClose(fileHandle);
    }
    else {
      Print("TESTER_testRecordArray invalid handle");
    }   
    Print("TestRecordArray COMPLETED");
  }
//**********************************************************************************************************************
void appendTradesArray()
  {
   ArrayResize(tradesArray, 0);
   int maxSLinTheRow = 0;
   int maxTPinTheRow = 0;
   int maxSLinTheRowTemp = 0;
   int maxTPinTheRowTemp = 0;
   double maxAbsoluteDD = 0;
   double maxPercentageDD = 0;
   double maxAbsoluteDDTemp = 0;
   double maxPercentageDDTemp = 0;
   double tempSL = 0;
   double tempTP = 0;
   datetime maxSLinTheRowDate = 0;
   datetime maxTPinTheRowDate = 0;
   int tpNo = 0;
   int slNo = 0;
   int trades = 0;
   
   for(int i = 0; i < ArraySize(testRecordArray); i++) {
      //Print("trades array: ", i);
      //tradesArray[i].isTradeOpen = testRecordArray[i].isTradeOpen;   
      //tradesArray[i].timeStamp = testRecordArray[i].timeStamp;
      if(testRecordArray[i].isSetup) {
         ArrayResize(tradesArray, ArraySize(tradesArray) + 1);
         tradesArray[trades].number = trades + 1;
         tradesArray[trades].openTime = testRecordArray[i].timeStamp; 
         tradesArray[trades].openPrice = testRecordArray[i].openTradePrice; 
         tempSL = testRecordArray[i].stopLoss;
         tempTP = testRecordArray[i].takeProfit;        
      }
      else if(testRecordArray[i].reachedSL || testRecordArray[i].reachedTP) {
         tradesArray[trades].closeTime = testRecordArray[i].timeStamp;
         tradesArray[trades].balance = testRecordArray[i].balance;
         if(testRecordArray[i].reachedSL) {
            tradesArray[trades].result = SL;
            tradesArray[trades].financialResult = testRecordArray[i].stopLossValue;
            tradesArray[trades].closePrice = tempSL;
            if(trades != 0) {
               if(tradesArray[trades - 1].result == SL) {
                  maxSLinTheRowTemp++;
               } 
               else {
                  maxSLinTheRowTemp = 1;
               }
            }
            slNo++;
         }
         else if(testRecordArray[i].reachedTP) {
            tradesArray[trades].result = TP;
            tradesArray[trades].financialResult = testRecordArray[i].takeProfitValue;
            tradesArray[trades].closePrice = tempTP;
            if(trades != 0) {
               if(tradesArray[trades - 1].result == TP) {
                  maxTPinTheRowTemp++;
               } 
               else {
                  maxTPinTheRowTemp = 1;
               }
            }
            tpNo++;
         }
         trades++;
         
         if(maxTPinTheRowTemp > maxTPinTheRow) {
             maxTPinTheRow = maxTPinTheRowTemp;
             maxTPinTheRowDate = testRecordArray[i].timeStamp;
         }   
         if(maxSLinTheRowTemp > maxSLinTheRow) {
             maxSLinTheRow = maxSLinTheRowTemp;
             maxSLinTheRowDate = testRecordArray[i].timeStamp;
         }    
      }
   }
   
   int fileHandle = FileOpen("TESTER_tradesArray" + Symbol(), FILE_WRITE);
    
   if(fileHandle != INVALID_HANDLE) {
      FileWrite(fileHandle, Symbol(), "\n trades", trades, "sl", slNo, "tp", tpNo,
                "\nMAX SL IN THE ROW", maxSLinTheRow, maxSLinTheRowDate,
                "\nMAX TP IN THE ROW", maxTPinTheRow, maxTPinTheRowDate,
                "\n\n\n");
      for(int i = 0; i < ArraySize(tradesArray); i++) {
         FileWrite(fileHandle,
                   "*******************************************************************************************\n",
                   tradesArray[i].number, "\n",
                   "opened", tradesArray[i].openTime, "\n",
                   "closed", tradesArray[i].closeTime, "\n",
                   "open price", tradesArray[i].openPrice, "\n",
                   "close price", tradesArray[i].closePrice, "\n",
                   "result", EnumToString(tradesArray[i].result), tradesArray[i].financialResult, "\n",
                   "balance", tradesArray[i].balance,
                   "\n\n\n"
                   );
                   //"date: ", tradesArray[i].timeStamp,
                   //"isTradeOpen: ", tradesArray[i].isTradeOpen);
      }
   FileClose(fileHandle);
   }
   else {
      Print("TESTER_tradesArray invalid handle");
   }      
   Print("TradesArray COMPLETED");                   
  }
//**********************************************************************************************************************
int OnInit()
  {
   EventSetTimer(60);
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
   Print("current spread: ", currentSpread);
   Print("is indice: ", isIndice(Symbol()));
   Print("min lot size: ", MarketInfo(Symbol(), MODE_MINLOT));
   Print("max lot size: ", MarketInfo(Symbol(), MODE_MAXLOT));
   Print("Point: ", Point);
   Print("Positions opened on this chart: ", countOpenPositionsForSymbol(Symbol()));
   Print("Symbol name: ", Symbol());
   Print("isIndice: ", isIndice(Symbol()));
   appendTrendDirectionArray(lowTF, highTF3, highTF2, highTF1, highPeriod3, highPeriod2, highPeriod1);
   appendTestRecordArray();
   appendTradesArray();
   ExpertRemove();
   return(INIT_SUCCEEDED);
  }
//**********************************************************************************************************************
void OnDeinit(const int reason)
  {
   //ExpertRemove();
   EventKillTimer();   
  }
//**********************************************************************************************************************
void OnTick()
  {

   
  }
//**********************************************************************************************************************
void OnTimer()
  {

   
  }
//**********************************************************************************************************************

