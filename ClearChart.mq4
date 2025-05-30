#property strict
//**********************************************************************************************************************
int OnInit()
  {
    
    int totalObjects = ObjectsTotal();
    Print("Total Objects: ", totalObjects);   
    
    for (int i = totalObjects - 1; i >= 0; i--)
    {
        
        string objectName = ObjectName(i);
        
        if (ObjectDelete(objectName))
        {
            Print("Usunięto obiekt: ", objectName);
        }
        else
        {
            Print("Nie udało się usunąć obiektu: ", objectName);
        }
    }
    
   Print("Wszystkie obiekty zostały usunięte.");
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

