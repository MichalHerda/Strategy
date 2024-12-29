#property strict
//**********************************************************************************************************************
int OnInit()
  {
    // Pobierz liczbę obiektów na wykresie
    int totalObjects = ObjectsTotal();
    Print("Total Objects: ", totalObjects);
    
    // Iteruj po wszystkich obiektach
    for (int i = totalObjects - 1; i >= 0; i--)
    {
        // Pobierz nazwę obiektu
        string objectName = ObjectName(i);
        
        // Usuń obiekt
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

