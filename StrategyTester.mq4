#property strict
#include "SharedLibrary.mqh"
//**********************************************************************************************************************7
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
   double stopLoss;
   double takeProfit;
   double lotSize;
   bool reachedSL;
   bool reachedTP;
   double accountBalance;
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
testRecord testRecordArray[];
trendDirection trendDirectionArray[];
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
double calculateLotSize(int pointsSL) 
   {
    // oblicz wielkość pozycji na podstawie podanej wartości StopLoss w punktach
    double balance = initialAccountBalance;  //AccountBalance();
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
    
    Print("appendTrendDirectionArray: ");
    Print("    all bars available: ", allBarsAvailable);
    Print("    firstBarIdx: ", firstBarIdx);
    Print("    firstBarDate: ", firstBarDate);
    Print("    firstBarClose: ", firstBarClose);
    
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
    
    for (int i = 0, barIdx = ArraySize(trendDirectionArray);             // właściwa pętla
         i <= ArraySize(trendDirectionArray) - 1; i++, barIdx--) {
         
    //for (int i = 0, barIdx = ArraySize(trendDirectionArray);           // testowa pętla 
    //     i <= 5000; i++, barIdx--) {      
         
      Print("test: ", i);
      ArrayResize(testRecordArray, ArraySize(testRecordArray) + 1);
           
      datetime timeStamp = trendDirectionArray[i].time;
      bool areHighTFs = checkForHighTFConditions(i);
      bool areLowTFConditions = checkForLowTFConditions(barIdx);
      
      bool isTradeOpen = false;
      
      double stopLossValue = 0;
      double takeProfitValue = 0;
      
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
               
                  Print("OPEN TRADE, time: ", testRecordArray[i].timeStamp);
                  testRecordArray[i].isSetup = true;
                  double openBarPrice = testRecordArray[i].openBarPrice;
                  
                  double stopLoss = calculateSL(barIdx) - ( currentSpread * 2);               
                  int stopLossPoints = (int)MathRound((openBarPrice - stopLoss) / Point);
                  if(stopLossPoints < minimumPointsSL) {
                     stopLoss = openBarPrice - (minimumPointsSL * Point);
                     stopLossPoints = minimumPointsSL;
                  }                 
                  testRecordArray[i].stopLoss = stopLoss;
                  
                  int takeProfitPoints = (int)MathRound(stopLossPoints * rrRatio);
                  double takeProfitPips = takeProfitPoints * Point;
                  double takeProfit = testRecordArray[i].openBarPrice + takeProfitPips;
                  
                  double lotSize = NormalizeDouble(calculateLotSize(stopLossPoints), 1);
                  stopLossValue = NormalizeDouble(stopLossPoints * pipValue * lotSize, 2);
                  takeProfitValue = NormalizeDouble(takeProfitPoints * pipValue * lotSize, 2);
                                                
                  //double lotSize = NormalizeDouble(lotSizeNotNormalized, _Digits);
                  testRecordArray[i].takeProfit = takeProfit;
                  testRecordArray[i].lotSize = lotSize;
                  testRecordArray[i].stopLossValue = stopLossValue;
                  testRecordArray[i].takeProfitValue = takeProfitValue;
                  Print("  TP: ", takeProfit);
                  Print("  SL: ", stopLoss);
                  Print("  LotSize: ", lotSize);
               }
         }
      }   
      else {
         testRecordArray[i].isSetup = false;
      }
      
      
    }
    
    int fileHandle = FileOpen("TESTER_testRecordArray", FILE_WRITE);
    
    if(fileHandle != INVALID_HANDLE) {
      for(int i = 0; i < ArraySize(testRecordArray); i++) {
         FileWrite(fileHandle,
                   i + 1,
                   testRecordArray[i].timeStamp,
                   testRecordArray[i].areHighTFs,
                   testRecordArray[i].areLowTFConditions,
                   "O:", testRecordArray[i].openBarPrice,
                   "C:", testRecordArray[i].closeBarPrice,
                   "H:", testRecordArray[i].highBarPrice,
                   "L:", testRecordArray[i].lowBarPrice,
                   "    IS SETUP: ", testRecordArray[i].isSetup,
                   "SL:", testRecordArray[i].stopLoss,
                   "TP:", testRecordArray[i].takeProfit,
                   "Lot:", testRecordArray[i].lotSize,
                   "SL Value: ", testRecordArray[i].stopLossValue,
                   "TP Value: ", testRecordArray[i].takeProfitValue,
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
int OnInit()
  {
   EventSetTimer(60);
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
   Print("current spread: ", currentSpread);
   appendTrendDirectionArray(lowTF, highTF3, highTF2, highTF1, highPeriod3, highPeriod2, highPeriod1);
   appendTestRecordArray();
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

   
  }
//**********************************************************************************************************************

