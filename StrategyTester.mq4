#property strict
#include "SharedLibrary.mqh"
//**********************************************************************************************************************
input double riskPercent = 4; 
input double rrRatio = 2.5;
input double initialAccountBalance = 1000;
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
  };
//**********************************************************************************************************************
struct trendDirection
  {
   datetime time;
   bool isLowTrendRising;
   bool isMediumTrendRising;
   bool isHighTrendRising;
  };
//**********************************************************************************************************************
struct trade
   {
    int number;
    datetime timeStamp;   // <--- to test / delete later
    datetime openTime;
    datetime closeTime;
    tradeResult result;
    double financialResult;
    double balance;
    bool isTradeOpen;     // <--- to test / delete later
   };
//**********************************************************************************************************************
testRecord testRecordArray[];
trendDirection trendDirectionArray[];
trade tradesArray[];
//**********************************************************************************************************************
bool checkForHighTFConditions(int idx)
  {
     return trendDirectionArray[idx].isHighTrendRising &&
            trendDirectionArray[idx].isMediumTrendRising &&
            trendDirectionArray[idx].isLowTrendRising;
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
    Print("maxStopLoss: ", maxStopLoss);
    //Print("Account currency is ", AccountCurrency());
    //Print("pipValue: ", pipValue);
    Print("lotSize: ", lotSize);
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
      int mediumTimeFrameBarShift = iBarShift(Symbol(), mediumTimeFrame, lowestTimeFrameBarTime);
      int highTimeFrameBarShift = iBarShift(Symbol(), highTimeFrame, lowestTimeFrameBarTime);
      
      datetime lowTimeFrameBarDate = iTime(Symbol(), lowTimeFrame, lowTimeFrameBarShift);
      datetime mediumTimeFrameBarDate = iTime(Symbol(), mediumTimeFrame, mediumTimeFrameBarShift);
      datetime highTimeFrameBarDate = iTime(Symbol(), highTimeFrame, highTimeFrameBarShift);
           
      bool isLowTrendRising = isRisingTrend(Symbol(), lowTimeFrame, lowTimeFramePeriod, lowTimeFrameBarShift,
                                            lowTimeFrameBarShift +1);
      bool isMediumTrendRising = isRisingTrend(Symbol(), mediumTimeFrame, mediumTimeFramePeriod, mediumTimeFrameBarShift,
                                               mediumTimeFrameBarShift + 1);
      bool isHighTrendRising = isRisingTrend(Symbol(), highTimeFrame, highTimeFramePeriod, highTimeFrameBarShift,
                                             highTimeFrameBarShift +1);                             
      /*                                                                            
      Print("bar: ", i, " time: ", lowTimeFrameBarTime, " medium tf bar: ", mediumTimeFrameBarShift,
            " medium tf date: ", mediumTimeFrameBarDate, " high tf bar: ", highTimeFrameBarShift,
            " high tf date: ", highTimeFrameBarDate, " isLowTrendRising: ", isLowTrendRising,
            " isMediumTrendRising: ", isMediumTrendRising, " isHighTrendRising: ", isHighTrendRising);
      */      
      ArrayResize(trendDirectionArray, ArraySize(trendDirectionArray) + 1);
      int currentIdx = ArraySize(trendDirectionArray) - 1;
      trendDirectionArray[currentIdx].time = lowestTimeFrameBarTime;
      trendDirectionArray[currentIdx].isHighTrendRising = isHighTrendRising;
      trendDirectionArray[currentIdx].isMediumTrendRising = isMediumTrendRising;
      trendDirectionArray[currentIdx].isLowTrendRising = isLowTrendRising;
    }
    
    //write to file:
    int fileHandle = FileOpen("TESTER_trendDirectionArray", FILE_WRITE);
      
      if(fileHandle != INVALID_HANDLE) {
         for(int i = 0; i < ArraySize(trendDirectionArray); i++) {
            FileWrite(fileHandle, i, trendDirectionArray[i].time,
                      " isLowTrendRising: ", trendDirectionArray[i].isLowTrendRising,
                      " isMediumTrendRising: ", trendDirectionArray[i].isMediumTrendRising,
                      " isHighTrendRising: ", trendDirectionArray[i].isHighTrendRising);
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
    //     i <= 10000; i++, barIdx--) {      
         
      //Print("test: ", i);
      ArrayResize(testRecordArray, ArraySize(testRecordArray) + 1);
           
      datetime timeStamp = trendDirectionArray[i].time;
      bool areHighTFs = checkForHighTFConditions(i);
      bool areLowTFConditions = checkForLowTFConditions(barIdx);
                 
      testRecordArray[i].timeStamp = timeStamp;
      testRecordArray[i].areHighTFs = areHighTFs;
      testRecordArray[i].areLowTFConditions = areLowTFConditions;
      
      testRecordArray[i].openBarPrice = iOpen(Symbol(), lowTF, barIdx);
      testRecordArray[i].closeBarPrice = iClose(Symbol(), lowTF, barIdx);
      testRecordArray[i].highBarPrice = iHigh(Symbol(), lowTF, barIdx);
      testRecordArray[i].lowBarPrice = iLow(Symbol(), lowTF, barIdx);
           
      if(!isTradeOpen) {
         if(areHighTFs && areLowTFConditions) {
            if(isBarGreen(Symbol(), lowTF, barIdx + 1) &&
               isBarRed(Symbol(), lowTF, barIdx + 2) ){
               
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
                  openTradePrice = openBarPrice;
                  
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
            Print("stopLoss has been reached");
            accountBalance -= stopLossValue;
            testRecordArray[i].closeTradePrice = stopLoss;
            stopLoss = 0;
            takeProfit = 0;
            stopLossValue = 0;
            takeProfitValue = 0;
            openTradePrice = 0;
            isTradeOpen = false;
            testRecordArray[i].balance = accountBalance;
            testRecordArray[i].takeProfit = takeProfit;
            testRecordArray[i].lotSize = lotSize;
            testRecordArray[i].stopLossValue = stopLossValue;
            testRecordArray[i].takeProfitValue = takeProfitValue;
            continue;
         }  
         if(takeProfit <= testRecordArray[i].highBarPrice) {
            //Print("takeProfit has been reached");
            accountBalance += takeProfitValue;            
            testRecordArray[i].closeTradePrice = takeProfit;
            stopLoss = 0;
            takeProfit = 0;
            stopLossValue = 0;
            takeProfitValue = 0;
            openTradePrice = 0;
            isTradeOpen = false;
            testRecordArray[i].balance = accountBalance;
            testRecordArray[i].takeProfit = takeProfit;
            testRecordArray[i].lotSize = lotSize;
            testRecordArray[i].stopLossValue = stopLossValue;
            testRecordArray[i].takeProfitValue = takeProfitValue;
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
      FileWrite(fileHandle, "SETTINGS: \n", "RISK PERCENT: ", riskPercent, "\n",
                "RRR: ", rrRatio, "\n", "INITIAL ACCOUNT BALANCE: ", initialAccountBalance, "\n",
                "MINIMUM SL: ", minimumPointsSL, "\n",
                "STOP LOSS MODIFICATOR: ", stopLossModificator, "\n\n\n"); 
      for(int i = 0; i < ArraySize(testRecordArray); i++) {
         FileWrite(fileHandle, i + 1,
                   testRecordArray[i].timeStamp,
                   "isTradeOpen:", testRecordArray[i].isTradeOpen,
                   //testRecordArray[i].areHighTFs,
                   //testRecordArray[i].areLowTFConditions,
                   //"O:", testRecordArray[i].openBarPrice,
                   //"C:", testRecordArray[i].closeBarPrice,
                   //"H:", testRecordArray[i].highBarPrice,
                   //"L:", testRecordArray[i].lowBarPrice,
                   "    IS SETUP:", testRecordArray[i].isSetup,
                   //"SL:", testRecordArray[i].stopLoss,
                   //"TP:", testRecordArray[i].takeProfit,
                   //"Lot:", testRecordArray[i].lotSize,
                   //"SL Value: ", testRecordArray[i].stopLossValue,
                   //"TP Value: ", testRecordArray[i].takeProfitValue,
                   "Open: ", testRecordArray[i].openTradePrice,
                   "Close: ", testRecordArray[i].closeTradePrice,
                   "    BALANCE:", testRecordArray[i].balance,
                   "\n" 
                   );
      }
      FileClose(fileHandle);
    }
    else {
      Print("TESTER_testRecordArray invalid handle");
    }   
  }
//**********************************************************************************************************************
void appendTradesArray()
  {
   ArrayResize(tradesArray, ArraySize(testRecordArray));
   
   for(int i = 0; i < ArraySize(testRecordArray); i++) {
      Print("trades array: ", i);
      tradesArray[i].isTradeOpen = testRecordArray[i].isTradeOpen;   
      tradesArray[i].timeStamp = testRecordArray[i].timeStamp;
   }
   
   int fileHandle = FileOpen("TESTER_tradesArray", FILE_WRITE);
    
   if(fileHandle != INVALID_HANDLE) {
      for(int i = 0; i < ArraySize(tradesArray); i++) {
         FileWrite(fileHandle,
                   "date: ", tradesArray[i].timeStamp,
                   "isTradeOpen: ", tradesArray[i].isTradeOpen);
      }
   FileClose(fileHandle);
   }
   else {
      Print("TESTER_tradesArray invalid handle");
   }      
                   
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

