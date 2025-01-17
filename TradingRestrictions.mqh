#property strict
//**********************************************************************************************************************
void closeBeforeCPI()
   {
      int currentMonth = TimeMonth(TimeCurrent());
      int currentDayOfMonth = TimeDay(TimeCurrent());
      
      //Print("month: ", currentMonth, ". day: ", currentDayOfMonth);
      if( (currentMonth == 1  && currentDayOfMonth == 15) ||
          (currentMonth == 2  && currentDayOfMonth == 12) ||
          (currentMonth == 3  && currentDayOfMonth == 12) ||
          (currentMonth == 4  && currentDayOfMonth == 10) ||
          (currentMonth == 5  && currentDayOfMonth == 13) ||
          (currentMonth == 6  && currentDayOfMonth == 11) ||
          (currentMonth == 7  && currentDayOfMonth == 15) ||
          (currentMonth == 8  && currentDayOfMonth == 12) ||
          (currentMonth == 9  && currentDayOfMonth == 11) ||
          (currentMonth == 10 && currentDayOfMonth == 15) ||
          (currentMonth == 11 && currentDayOfMonth == 13) ||
          (currentMonth == 12 && currentDayOfMonth == 10) )
          
          {
            Print("close before CPI");
            for(int i = OrdersTotal() - 1; i >= 0; i--)
            {
               if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                  
                  if (OrderType() == OP_BUY) {
                     bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);
                     if (!closed) {
                        Print("Błąd przy zamykaniu pozycji: ", GetLastError());
                     }
                  }
               }
            }
          }
                    
   }
//**********************************************************************************************************************
bool isCPIDay()
   {
      int currentMonth = TimeMonth(TimeCurrent());
      int currentDayOfMonth = TimeDay(TimeCurrent());
      
      if( (currentMonth == 1  && currentDayOfMonth == 15) ||
          (currentMonth == 2  && currentDayOfMonth == 12) ||
          (currentMonth == 3  && currentDayOfMonth == 12) ||
          (currentMonth == 4  && currentDayOfMonth == 10) ||
          (currentMonth == 5  && currentDayOfMonth == 13) ||
          (currentMonth == 6  && currentDayOfMonth == 11) ||
          (currentMonth == 7  && currentDayOfMonth == 15) ||
          (currentMonth == 8  && currentDayOfMonth == 12) ||
          (currentMonth == 9  && currentDayOfMonth == 11) ||
          (currentMonth == 10 && currentDayOfMonth == 15) ||
          (currentMonth == 11 && currentDayOfMonth == 13) ||
          (currentMonth == 12 && currentDayOfMonth == 10) ) {
               return true;
          }
          else {
               return false;
          }   
   }
//**********************************************************************************************************************
bool isUSMarketHoliday()
   {
      int currentYear = TimeYear(TimeCurrent());
      int currentMonth = TimeMonth(TimeCurrent());
      int currentDay = TimeDay(TimeCurrent());
      
      //Print("year: ", currentYear);
      //Print("month: ", currentMonth);
      //Print("day: ", currentDay);
      
      if(currentYear == 2025) {
         if( (currentMonth == 1  && currentDay == 20) ||
             (currentMonth == 2  && currentDay == 17) ||
             (currentMonth == 4  && currentDay == 18) ||
             (currentMonth == 5  && currentDay == 26) ||
             (currentMonth == 6  && currentDay == 19) ||
             (currentMonth == 7  && currentDay ==  3) ||
             (currentMonth == 7  && currentDay ==  4) ||
             (currentMonth == 9  && currentDay ==  1) ||
             (currentMonth == 11 && currentDay == 27) ||
             (currentMonth == 11 && currentDay == 28) ||
             (currentMonth == 12 && currentDay == 24) ||
             (currentMonth == 12 && currentDay == 25) ) {
                Print("Market holiday! NO TRADING!");
                return true;
             }
             else return false;
      }
      
      //Print("Not market holiday, trading allowed.");
      return false;
   }

//**********************************************************************************************************************