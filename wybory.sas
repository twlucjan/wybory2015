
%macro brakujace_glosy(komitety);
%local k komitet;
data komitety;
	length komitet $32;
	%do k=1 %to %sysfunc(countw(&komitety));
	   %let komitet = %scan(&komitety, &k);
	   komitet = "&komitet";
	   output;
	%end;
run;

data pkw_mandaty;
	merge pkw liczba_mandatow(drop=siedziba_OKW);
	by nr_okr;
run;

data komitety_x_ilorazy;
	set pkw_mandaty;
	length komitet $32;

	%do k=1 %to %sysfunc(countw(&komitety));
	   %let komitet = %scan(&komitety, &k);
	   komitet = "&komitet";
	   liczba_glosow = &komitet;
	   do dzielnik =1 to liczba_mandatow; iloraz = liczba_glosow / dzielnik; output; end; 
	%end;

	keep nr_okr siedziba_OKW komitet liczba_glosow dzielnik iloraz liczba_mandatow;
run;

proc sort data=komitety_x_ilorazy out=okregi_sort ;
	by nr_okr descending iloraz;
run;

data okregi_rank;
	set okregi_sort;
	by nr_okr;

	if first.nr_okr then nr_mandatu = 0;
	nr_mandatu + 1;

	mandat = (nr_mandatu le liczba_mandatow);
run;

proc sql; create table ilorazy_do_pobicia as 
	select 
		nr_okr, 
		siedziba_OKW, 
		a.komitet, 
		min(iloraz) as iloraz_do_pobicia
	from komitety a 
	inner join okregi_rank b on
		a.komitet ne b.komitet
	where mandat
	group by 1,2,3;
quit;

proc sql; create table najlepsze_ilorazy as
	select
		nr_okr,
		siedziba_OKW,
		komitet,
		dzielnik,
		iloraz as maks_iloraz
	from okregi_rank
	where not mandat
	group by 1,2,3
	having dzielnik = min(dzielnik);
quit;

proc sql; create table brakujace_glosy as
	select
		a.nr_okr,
		a.siedziba_OKW,
		a.komitet,
		ceil((a.iloraz_do_pobicia - b.maks_iloraz) * b.dzielnik) as brakujace_glosy
	from ilorazy_do_pobicia a
	inner join najlepsze_ilorazy b on
		a.nr_okr = b.nr_okr and
		a.komitet = b.komitet;
quit;

%mend;

%brakujace_glosy(PiS PO Nowoczesna Kukiz15 PSL);



data attrmapklub;
retain LINEPATTERN "solid";
length value $20  fillcolor $20 LINECOLOR $20;
input id $ value $ fillcolor $ LINECOLOR $;
datalines;
komitet PiS cx02075D cx02075D
komitet PO cxE45618 cxE45618
komitet PSL cx073B00 cx073B00
komitet Nowoczesna cx6C9FCE cx6C9FCE
komitet Kukiz15 cx790604 790604
;
run;

proc template;
 define statgraph heart;
  dynamic _skin _trans;
  begingraph / designwidth=10in designheight=6in
      datasymbols=(circlefilled);
      layout overlay / xaxisopts=(display=(tickvalues));
        scatterplot x=komitet y=brakujace_glosy /group=komitet jitter=auto markerattrs=(symbol=circlefilled size=11) 
          datatransparency=_trans filledoutlinedmarkers=true
          DATALABELATTRS=(color=gray size=8pt) dataskin=_skin;
        boxplot x=komitet y=brakujace_glosy /  DISPLAY=(/*OUTLIERS*/ mean median ) datalabel=autor displaystats=(mean median min)
          outlineattrs=(color=gray thickness=1) whiskerattrs=(color=gray thickness=1)
          medianattrs=(color=gray thickness=1) BOXWIDTH=0.8 ;
endlayout;
  endgraph;
 end;
run;

data brakujace_glosy2;
	set brakujace_glosy;
	if brakujace_glosy > 100000 then delete;
run;



proc sgrender data=brakujace_glosy2 template=heart dattrmap=Attrmapklub;
dattrvar komitet="komitet";
dynamic _trans=0.4 _skin='gloss';
label brakujace_glosy="G³osy do dodatkowego mandatu" komitet="Komitet";
run;

