
// Zadaniem poniższego programu jest obliczenie długości trwania trendu wzrostowego dla dostępnych instrumentów
// a następnie posortowanie tych instumentów, od najdłużej trwającego do najkrócej trwającego trendu
 
#property strict

#include "SharedLibrary.mqh"
//**********************************************************************************************************************

struct symbolStruct
{
   string symbolName;
   int trendDuration;
};

symbolStruct symbolArray[];

//**********************************************************************************************************************

input int maPeriod = 10;
input ENUM_TIMEFRAMES maTF = PERIOD_W1;

ENUM_MA_METHOD maMethod = MODE_SMA;
ENUM_APPLIED_PRICE maPrice = MODE_CLOSE;
string tfString = EnumToString(maTF);
string fileName = "TrendDurationList_" + tfString;

//**********************************************************************************************************************

int OnInit()

{
   Print("Wszystkie instrumenty: ", SymbolsTotal(false));
   int h = 0, k = 0;
   ArrayResize(symbolArray, 0);
   int fileHandle = FileOpen(fileName, FILE_WRITE);
   
   for(int i = 0; i < SymbolsTotal(false); i++) {
      string symbol = SymbolName(i, false);
      Print("symbol no. ", i, ": ", symbol);
      if(isShare(symbol) || isSymbolForbidden(symbol) ) {
         Print("symbol ", symbol, " nie podlega obserwacji");
         h++;
      }
      else {
         Print("symbol ", symbol, " zapisujemy do tablicy i obserwujemy");
         k++;
         ArrayResize(symbolArray, ArraySize(symbolArray) + 1);
         int currentIndex = ArraySize(symbolArray) - 1;
         symbolStruct dataArray;
         dataArray.symbolName = symbol;
         dataArray.trendDuration = getTrendDuration(symbol, maTF, maMethod, maPrice, maPeriod);
         symbolArray[currentIndex] = dataArray;
         //fileWrite(fileHandle, "symbol: ", symbolArray[currentIndex].symbolName, "trend duration: ", symbolArray[currentIndex].trendDuration); 
      }                   
   }
   
    symbolStruct temp;
    
    for(int j = 0; j < ArraySize(symbolArray) - 1; j++) {
       int minimumIdx = j;
       for(int i = j + 1; i < ArraySize(symbolArray); i++) 
         {
          if(symbolArray[i].trendDuration > symbolArray[minimumIdx].trendDuration) minimumIdx = i;
         }  
         
       if(minimumIdx != j) 
         {
          temp = symbolArray[minimumIdx];
          symbolArray[minimumIdx] = symbolArray[j];
          symbolArray[j] = temp;
         }   
      }
      
    for(int m = 0; m < ArraySize(symbolArray); m++) {
      FileWrite(fileHandle, "symbol: ", symbolArray[m].symbolName, "trend duration: ", symbolArray[m].trendDuration); 
                       
    }    
   
   FileClose(fileHandle);
   
   Print("Instrumenty obserwowane: ", k);
   Print("Instrumenty pominięte: ", h);
   Print("Rozmiar tablicy do zapisywania danych: ", ArraySize(symbolArray) );
   

   return(INIT_SUCCEEDED);
}

//**********************************************************************************************************************

void OnDeinit(const int reason)
{
   
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