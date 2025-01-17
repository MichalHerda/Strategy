
#property strict

//**********************************************************************************************************************
enum swingType
  {
   above,
   below,
  };  
//**********************************************************************************************************************
struct swing 
  {
   int               position;
   int               duration;
   double            depth;  
   swingType         type;
   datetime          start;
   datetime          end;
  };
//**********************************************************************************************************************
swing swingArray[];
//**********************************************************************************************************************
void appendSwingArray(ENUM_TIMEFRAMES swingsTimeFrame, int swingMovingAveragePeriod)
   {
      ArrayResize(swingArray, 0);
      
      int allBarsAvailable = iBars(Symbol(), swingsTimeFrame);
      int firstBarIdx = allBarsAvailable - swingMovingAveragePeriod;
      
      swingType type;
      if(iClose(Symbol(), swingsTimeFrame, firstBarIdx) >= iMA(Symbol(), swingsTimeFrame, swingMovingAveragePeriod, 
                                                            firstBarIdx, MODE_SMA, PRICE_CLOSE, 0) ) type = above;
                                                   else
                                                      type = below;
      ArrayResize(swingArray, ArraySize(swingArray) + 1);
      int position = 1;
      int duration = 1;
      double depth = 0; 
      double currentDepth = 0;
      datetime start = iTime(Symbol(), swingsTimeFrame, firstBarIdx);
                                                          
      for(int i = firstBarIdx - 1; i >= 0; i--) {
         
         double movAve = iMA(Symbol(), swingsTimeFrame, swingMovingAveragePeriod, 
                             i, MODE_SMA, PRICE_CLOSE, 0);
         double high = iHigh(Symbol(), swingsTimeFrame, i);                   
         double low = iLow(Symbol(), swingsTimeFrame, i);
         double close = iClose(Symbol(), swingsTimeFrame, i);
                             
         if(type == below) {
            if(high >= movAve && low >= movAve) {
               swingArray[position - 1].position = position;
               swingArray[position - 1].duration = duration;
               swingArray[position - 1].depth = NormalizeDouble(depth, 4);
               swingArray[position - 1].type = type;
               swingArray[position - 1].start = start;
               swingArray[position - 1].end = iTime(Symbol(), swingsTimeFrame, i + 1);
               type = above;
               duration = 1;
               depth = 0;
               position++;
               start = iTime(Symbol(), swingsTimeFrame, i);
               ArrayResize(swingArray, ArraySize(swingArray) + 1);
            }
            else {
               duration++;
               currentDepth = movAve - low;
               if(currentDepth > depth) depth = currentDepth;
            }
         }
         if(type == above) {
             if(high <= movAve && low <= movAve) {
               swingArray[position - 1].position = position;
               swingArray[position - 1].duration = duration;
               swingArray[position - 1].depth = NormalizeDouble(depth, 4);
               swingArray[position - 1].type = type;
               swingArray[position - 1].start = start;
               swingArray[position - 1].end = iTime(Symbol(), swingsTimeFrame, i + 1);
               type = below;
               duration = 1;
               depth = 0;
               position++;
               start = iTime(Symbol(), swingsTimeFrame, i);
               ArrayResize(swingArray, ArraySize(swingArray) + 1);
            }
            else {
               duration++;
               currentDepth = high - movAve;
               if(currentDepth > depth) depth = currentDepth;
            }
         }      
      }
      
      int fileHandle = FileOpen("swingArray", FILE_WRITE);
      
      if(fileHandle != INVALID_HANDLE) {
         for(int i = 0; i < ArraySize(swingArray); i++) {
            FileWrite(fileHandle,
                      swingArray[i].position,
                      swingArray[i].duration,
                      swingArray[i].depth,
                      swingArray[i].type,
                      swingArray[i].start,
                      swingArray[i].end);
         }
         FileClose(fileHandle);
      }
      else {
         Print("miau! ćwir ćwir!");   
      }
   }
//**********************************************************************************************************************   