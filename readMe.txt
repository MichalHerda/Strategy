PLAN NALEŻY MIEĆ NA UWADZE PRZY KAŻDYM PODEJŚCIU DO PRACY NAD PROJEKTEM, NIE POWINNO ODCHODZIĆ SIĘ OD GŁÓWNYCH ZAŁOŻEŃ PROJEKTU

****************************************************************************************************************************************

GŁÓWNE ZAŁOŻENIA:

1. Nie programuj wszystkiego od nowa - korzystaj z projektów, które zostały stworzone na etapie przygotowań do wdrożenia strategii:
	- to, co można wziąć pod uwagę, to uporządkowanie istniejącego kodu - podzielenie go na moduły. Ułatwi to dalszą pracę
	
2. Nie próbuj stworzyć robota, który będzie w pełni samodzielny. To jest prawdopodobnie kwestia odległej przyszłości:
	- główny temat, którego dotyczy ten punkt, to selekcja instrumentów na których należy grać
	- tutaj trzeba skorzystać z zaprogramowanych wskaźników dotyczących istnienia trendu
	- wybór instrumentów na których zostanie uruchomiony system zależy od tradera (na podstawie powyższych wskaźników)
	
3. Najważniejszy jest działający robot:
	- nie odwlekaj tematu testując w nieszkończoność  

****************************************************************************************************************************************
 
SZCZEGÓŁY STRATEGII:

1. Strategia w założeniu daje przewagę na instrumentach, na których istnieje trend wzrostowy wyższego rzędu (W1 + D1)

2. Następnym trendem branym pod uwagę, jest trend 10 okresowy na interwale H1 - możliwe jest zawieranie transakcji dopiero kiedy ten trend jest wzrostowy

3. Interwał najniższego rzędu to M5 (również 10 okresowy), tutaj poszukujemy sygnałów, kiedy cena znajduje się poniżej średniej kroczącej:
	- po serii świec spadkowych musi nastąpić świeca wzrostowa - warunek jest taki, że ostatnia świeca spadkowa powinna w całości znajdować się pod średnią kroczącą
	- SL i TP są obliczane na podstawie ostatnich świec, jednak np dla NQ100 wymagane jest minimum 15 pipsów. Dla innych instrumentów ta minimalna ilość pipsów zależy od  backtestów, jednak zamysł jest taki, aby SL stanowił około 10-krotność spreadu na danym instrumencie. Przy ustalaniu SL raczej należy wziąć pod uwagę najniższe wartości H1 z ostatniego spadkowego swingu,
	- np na NQ100, wg backtestów wychodzi, że ocekiwane RRR to SL: 1 do TP: 1.5
	- należy zoptymalizować RRR
	
****************************************************************************************************************************************

KOLEJNOŚĆ DZIAŁANIA:

1. Moduł iterujący poprzez wszystkie rynki i listujący tylko te, na których istnieje trend wzrostowy
2. Moduł właściwy:
	- taki, który oczekuje zaistnienia trendu wzrostowego na H1
	- oblicza wielkość pozycji dla porządanego RRR
3. Moduł wskaźnikowy:
	- moduł, który prezentuje na jednym wykresie wszystkie używane średnie kroczące
	- ma opcję zaznaczenia okresów czasu w których istniały warunki do zawarcia transakcji
4. Moduł testujący, umożliwiający przeprowadzanie backtestów (temat na przyszłość)

**************************************************************************************************************************************** 

