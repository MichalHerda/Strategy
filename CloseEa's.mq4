#property strict
//**********************************************************************************************************************
int OnInit()
{
/*
   if (ChartApplyTemplate(0, "Default"))
   {
      Print("Wszystkie EA zostały usunięte z wykresu przez zastosowanie domyślnego szablonu.");
   }
   else
   {
      Print("Nie udało się zastosować domyślnego szablonu. Kod błędu: ", GetLastError());
   }
*/   
   ExpertRemove();
   
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
