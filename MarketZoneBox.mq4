
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
   datetime time;
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
   input ENUM_TIMEFRAMES lowTimeFrame = PERIOD_H1;
   input ENUM_TIMEFRAMES mediumTimeFrame = PERIOD_D1;
   input ENUM_TIMEFRAMES highTimeFrame = PERIOD_W1;
   input int lowTimeFramePeriod = 10;
   input int mediumTimeFramePeriod = 10;
   input int highTimeFramePeriod = 10;   
   input color lowTimeFrameRectColor = clrMidnightBlue;  
//**********************************************************************************************************************
double getAllTimeMinimumPrice() 
   {
    int lowestMonthlyBarIdx = iLowest(Symbol(), PERIOD_MN1, MODE_LOW);
    
    return iLow(Symbol(), PERIOD_MN1, lowestMonthlyBarIdx);    
   }
//**********************************************************************************************************************
double getAllTimeMaximumPrice() 
   {
    int highestMonthlyBarIdx = iHighest(Symbol(), PERIOD_MN1, MODE_HIGH);
    
    return iHigh(Symbol(), PERIOD_MN1, highestMonthlyBarIdx);    
   }  
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
    
    //debugging and tests:
    int allBarsAvailable = iBars(Symbol(), lowTimeFrame);
    int firstBarIdx = allBarsAvailable - lowTimeFramePeriod - 1;    
    datetime firstBarDate = iTime(Symbol(), lowTimeFrame, firstBarIdx);
    double firstBarClose = iClose(Symbol(), lowTimeFrame, firstBarIdx);
    
    //Print("appendTrendDirectionArray: ");
    //Print("    all bars available: ", allBarsAvailable);
    //Print("    firstBarIdx: ", firstBarIdx);
    //Print("    firstBarDate: ", firstBarDate);
    //Print("    firstBarClose: ", firstBarClose);
    
    //append array:
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
                            
      /*                                                                            
      Print("bar: ", i, " time: ", lowTimeFrameBarTime, " medium tf bar: ", mediumTimeFrameBarShift,
            " medium tf date: ", mediumTimeFrameBarDate, " high tf bar: ", highTimeFrameBarShift,
            " high tf date: ", highTimeFrameBarDate, " isLowTrendRising: ", isLowTrendRising,
            " isMediumTrendRising: ", isMediumTrendRising, " isHighTrendRising: ", isHighTrendRising);
      */      
      ArrayResize(trendDirectionArray, ArraySize(trendDirectionArray) + 1);
      int currentIdx = ArraySize(trendDirectionArray) - 1;
      trendDirectionArray[currentIdx].time = lowTimeFrameBarTime;
      trendDirectionArray[currentIdx].isHighTrendRising = isHighTrendRising;
      trendDirectionArray[currentIdx].isMediumTrendRising = isMediumTrendRising;
      trendDirectionArray[currentIdx].isLowTrendRising = isLowTrendRising;
    }
    
    //write to file:
    int fileHandle = FileOpen("trendDirectionArray", FILE_WRITE);
      
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
void appendTimePeriodArray()
   {
    ArrayResize(timePeriodArray, 0);
    bool isPeriodWriting = false;
    
    for (int i = 0; i <= ArraySize(trendDirectionArray) - 1; i++) {
      
            switch(maCombination) {
               
               case NONE:
                  break;
                  
               case LOW:
                   if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isLowTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isLowTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;   
                     }    
                  }   
                  break;
                                
               case MEDIUM:
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isMediumTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isMediumTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;   
                     }      
                  }   
                  break;   
                              
               case HIGH:
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;   
                     }                               
                  }   
                  break;
                                
               case LOW_MEDIUM:
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isLowTrendRising || !trendDirectionArray[i].isMediumTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isLowTrendRising && trendDirectionArray[i].isMediumTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;   
                     }                            
                  }   
                  break;      
                  
               case MEDIUM_HIGH:
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isMediumTrendRising || !trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isMediumTrendRising && trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;
                     }                        
                  }   
                  break;      
                  
               case LOW_HIGH:
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isLowTrendRising || !trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = false;
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                  }
                  else {
                     if(trendDirectionArray[i].isLowTrendRising && trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;
                     }                          
                  }   
                  break;
                  
               case ALL:
                  //Print(i, "TIME: ", trendDirectionArray[i].time, 
                  //      " L: ", trendDirectionArray[i].isLowTrendRising,
                  //      " M: ", trendDirectionArray[i].isMediumTrendRising,
                  //      " H: ", trendDirectionArray[i].isHighTrendRising);
                  if(isPeriodWriting) {
                     if(!trendDirectionArray[i].isLowTrendRising || !trendDirectionArray[i].isMediumTrendRising ||
                        !trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = false; 
                        datetime endDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate; 
                     }
                     else {
                        isPeriodWriting = true;
                     }   
                  }
                  else {
                     if(trendDirectionArray[i].isLowTrendRising && trendDirectionArray[i].isMediumTrendRising && 
                        trendDirectionArray[i].isHighTrendRising) {
                        isPeriodWriting = true;
                        ArrayResize(timePeriodArray, ArraySize(timePeriodArray) + 1);
                        datetime beginDate = trendDirectionArray[i].time;
                        timePeriodArray[ArraySize(timePeriodArray) - 1].beginDate = beginDate;     
                     }   
                     else {
                        isPeriodWriting = false;
                     }
                  }   
                  break;
                  
               default:
                  break;         
            
            }
    } 
      
    if (isPeriodWriting) {
        datetime endDate = iTime(Symbol(), lowTimeFrame, 0);
        timePeriodArray[ArraySize(timePeriodArray) - 1].endDate = endDate;
    }
    
    Print("timePeriodArray size: ", ArraySize(timePeriodArray));
    
    int fileHandle = FileOpen("timePeriodArray", FILE_WRITE);
    
    if(fileHandle != INVALID_HANDLE) {
      for(int i = 0; i < ArraySize(timePeriodArray); i++) {
         FileWrite(fileHandle,
                   i + 1,
                   timePeriodArray[i].beginDate,
                   timePeriodArray[i].endDate);
      }
      FileClose(fileHandle);
    }
    else {
      Print("chartIndicators invalid handle");
    }   
   }          
//**********************************************************************************************************************
void writeIndicatorOnChart() 
   {
      for(int i = ArraySize(timePeriodArray) - 1; i >= 0; i--) {
         string rectName = "BackgroundRect_" + IntegerToString(i);
         
         int startIndex = iBarShift(NULL, lowTimeFrame, timePeriodArray[i].beginDate, true);
         int endIndex = iBarShift(NULL, lowTimeFrame, timePeriodArray[i].endDate, true);
         
         if (!ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, timePeriodArray[i].beginDate, 
                           getAllTimeMinimumPrice(), timePeriodArray[i].endDate, getAllTimeMaximumPrice())) {
            Print("Nie udało się stworzyć obiektu prostokąta dla przedziału ", i+1);
            continue;
         }
         ObjectSetInteger(0, rectName, OBJPROP_COLOR, lowTimeFrameRectColor);         
      }
   }
//**********************************************************************************************************************
int OnInit()
  {
   EventSetTimer(10);
   appendTrendDirectionArray();
   appendTimePeriodArray();
   writeIndicatorOnChart();
   return(INIT_SUCCEEDED);
  }
//**********************************************************************************************************************
void OnDeinit(const int reason)
  {
    for (int i = 0; i < ArraySize(timePeriodArray); i++)
     {
      string rectName = "BackgroundRect_" + IntegerToString(i);
      ObjectDelete(0, rectName);
     }
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
