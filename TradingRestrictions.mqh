#property strict
//**********************************************************************************************************************
void closeBeforeCPI()
   {
      int currentMonth = TimeMonth(TimeCurrent());
      int currentDayOfMonth = TimeDay(TimeCurrent());
      
      Print("month: ", currentMonth, ". day: ", currentDayOfMonth);
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

