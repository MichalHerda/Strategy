
#property strict
//**********************************************************************************************************************
struct timePeriod
  {
   datetime beginDate;
   datetime endDate;
  };

//**********************************************************************************************************************
struct trendDirection
  {
   bool isLowTrendRising;
   bool isMediumTrendRising;
   bool isHighTrendRising;
  };
//**********************************************************************************************************************
enum movAveCombination 
  {
   NONE,                  // 0
   LOW,                   // 1
   MEDIUM,                // 2
   HIGH,                  // 3
   LOW_MEDIUM,            // 4
   MEDIUM_HIGH,           // 5
   LOW_HIGH,              // 6
   ALL                    // 7
  };
//**********************************************************************************************************************
   timePeriod timePeriodArray[];
   trendDirection trendDirectionArray[];
//**********************************************************************************************************************
   input movAveCombination maCombination = ALL;
   input ENUM_TIMEFRAMES highTimeFrame = PERIOD_W1;
   input ENUM_TIMEFRAMES mediumTimeFrame = PERIOD_D1;
   input ENUM_TIMEFRAMES lowTimeFrame = PERIOD_H1;
   input int highTimeFramePeriod = 10;
   input int mediumTimeFramePeriod = 10;
   input int lowTimeFramePeriod = 10;
//**********************************************************************************************************************
bool isRisingTrend(string symbol, ENUM_TIMEFRAMES tf, int period, int idxLater, int idxBefore)
  {
   double movAveBar1 = iMA(symbol, tf, period, idxLater, MODE_SMA, PRICE_CLOSE, 0);
   double movAveBar2 = iMA(symbol, tf, period, idxBefore, MODE_SMA, PRICE_CLOSE, 0);

   return movAveBar1 > movAveBar2;
  }
//**********************************************************************************************************************  
void appendTrendDirectionArray()
  {
    ArrayResize(trendDirectionArray, 0);
    
    int allBarsAvailable = iBars(Symbol(), lowTimeFrame);
    int firstBarIdx = allBarsAvailable - lowTimeFramePeriod - 1;    
    datetime firstBarDate = iTime(Symbol(), lowTimeFrame, firstBarIdx);
    double firstBarClose = iClose(Symbol(), lowTimeFrame, firstBarIdx);
    
    Print("appendTrendDirectionArray: ");
    Print("    all bars available: ", allBarsAvailable);
    Print("    firstBarIdx: ", firstBarIdx);
    Print("    firstBarDate: ", firstBarDate);
    Print("    firstBarClose: ", firstBarClose);
    
    for(int i = firstBarIdx; i > 0; i--) {
      datetime lowTimeFrameBarTime = iTime(Symbol(), lowTimeFrame, i);
      int mediumTimeFrameBarShift = iBarShift(Symbol(), mediumTimeFrame, lowTimeFrameBarTime);
      int highTimeFrameBarShift = iBarShift(Symbol(), highTimeFrame, lowTimeFrameBarTime);
      datetime mediumTimeFrameBarDate = iTime(Symbol(), mediumTimeFrame, mediumTimeFrameBarShift);
      datetime highTimeFrameBarDate = iTime(Symbol(), highTimeFrame, highTimeFrameBarShift);
      bool isLowTrendRising = isRisingTrend(Symbol(), lowTimeFrame, lowTimeFramePeriod, i, i +1);
      bool isMediumTrendRising = isRisingTrend(Symbol(), mediumTimeFrame, mediumTimeFramePeriod, mediumTimeFrameBarShift,
                                               mediumTimeFrameBarShift + 1);
      bool isHighTrendRising = isRisingTrend(Symbol(), highTimeFrame, highTimeFramePeriod, highTimeFrameBarShift,
                                             highTimeFrameBarShift +1);                                        
      Print("bar: ", i, " time: ", lowTimeFrameBarTime, " medium tf bar: ", mediumTimeFrameBarShift,
            " medium tf date: ", mediumTimeFrameBarDate, " high tf bar: ", highTimeFrameBarShift,
            " high tf date: ", highTimeFrameBarDate, " isLowTrendRising: ", isLowTrendRising,
            " isMediumTrendRising: ", isMediumTrendRising, " isHighTrendRising: ", isHighTrendRising);
            
      ArrayResize(trendDirectionArray, ArraySize(trendDirectionArray) + 1);
      int currentIdx = ArraySize(trendDirectionArray) - 1;
      trendDirectionArray[currentIdx].isHighTrendRising = isHighTrendRising;
      trendDirectionArray[currentIdx].isMediumTrendRising = isMediumTrendRising;
      trendDirectionArray[currentIdx].isLowTrendRising = isLowTrendRising;
    }
  }
//**********************************************************************************************************************
int OnInit()
  {
   EventSetTimer(10);
   appendTrendDirectionArray();
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
   //appendTrendDirectionArray();
   
  }
//**********************************************************************************************************************
