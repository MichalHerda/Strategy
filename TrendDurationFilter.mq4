
// Zadaniem poniższego programu jest obliczenie długości trwania trendu wzrostowego dla dostępnych instrumentów
// a następnie posortowanie tych instumentów, od najdłużej trwającego do najkrócej trwającego trendu
 
#property strict

struct symbol
{
   string symbolName;
   int trendDuration;
};

symbol symbolArray[];

input int maPeriod = 10;
input ENUM_TIMEFRAMES maTF = PERIOD_W1;

ENUM_MA_METHOD maMethod = MODE_SMA;
bool enableShares = false;
string tfString = EnumToString(maTF);
string fileName = "TrendDurationList_" + tfString;



int OnInit()

{
   
   for(int i = 0; i < SymbolsTotal(false); i++) {
      // if(!isShare) { }
      //          else
      //              { }   
   }
   

   return(INIT_SUCCEEDED);
}



void OnDeinit(const int reason)
{
   
}



void OnTick()
{
  
}



void OnTimer()
{
  
}

