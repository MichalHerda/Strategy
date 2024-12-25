#property strict
//**********************************************************************************************************************7
input double riskPercent = 4; 
input double rrRatio = 2.5;
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
struct testRecord 
  {
   datetime timeStamp;
   bool areHighTFs;
   bool areLowTFConditions;
   bool isTradeOpen;
   bool reachedSL;
   bool reachedTP;
   double accountBalance;
   double openPrice;
   double closePrice;
   double highPrice;
   double lowPrice;
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
    
    for (int i = 0; i <= ArraySize(trendDirectionArray) - 1; i++) {
      ArrayResize(testRecordArray, ArraySize(testRecordArray) + 1);
      int idx = ArraySize(testRecordArray) - 1;
      datetime timeStamp = trendDirectionArray[i].time;
      testRecordArray[idx].timeStamp = timeStamp;
      testRecordArray[idx].areHighTFs = checkForHighTFConditions(idx);
      
      
    }
    
    int fileHandle = FileOpen("TESTER_testRecordArray", FILE_WRITE);
    
    if(fileHandle != INVALID_HANDLE) {
      for(int i = 0; i < ArraySize(testRecordArray); i++) {
         FileWrite(fileHandle,
                   i + 1,
                   testRecordArray[i].timeStamp,
                   testRecordArray[i].areHighTFs
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

