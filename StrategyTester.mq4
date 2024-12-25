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
  };
//**********************************************************************************************************************
testRecord testRecordArr[];
//**********************************************************************************************************************
int OnInit()
  {
   EventSetTimer(60);
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

