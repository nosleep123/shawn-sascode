%let datadir =C:\Users\Shuhao Ren\Dropbox\SAS\Part_2_Yang;
libname tick "&datadir.\Data\Tick";


proc import out=tick.change_list
   datefile="&datadir.\Data\Tick\TSPilotChanges.txt"
   dbms=dlm replace;
 delimiter='|';
 getnames=yes;
 datarow=2;
run;
proc import out=tick.securities_list
   datefile="&datadir.\Data\Tick\TSPilotSecurities.txt"
   dbms=dlm replace;
 delimiter='|';
 getnames=yes;
 datarow=2;
run;
proc import out=tick.mkt_maker_profit
   datefile="&datadir.\Data\Tick\CNSLD_MMProfitabilityStatistics_201709.dat"
   dbms=dlm replace;
 delimiter='|';
 getnames=yes;
 datarow=2;
run;
proc import out=tick.mkt_part_stat
   datefile="&datadir.\Data\Tick\FINRA_MMParticipationStatistics_201706.dat"
   dbms=dlm replace;
 delimiter='|';
 getnames=yes;
 datarow=2;
run;
proc import datafile="&datadir.\Data\Tick\trading symbol reference.csv" dbms=csv out=tick.trade_symbol replace;
 getnames=yes;
run;
data tick.pre;
	infile "&datadir.\Data\Tick\CRSP_pre_treatment.csv" delimiter=',' dsd;  /*dsd delimiter sensitive*/ 
	length siccd 4.;
	length ret 6.7;
	length prc 4.4;

	input permno date siccd ticker $ prc vol ret ;

 run;
 data tick.post;
	infile "&datadir.\Data\Tick\CRSP_post_treatment.csv" delimiter=',' dsd;  /*dsd delimiter sensitive*/ 
	length siccd 4.;
	length ret 6.7;
	length prc 4.4;

	input permno date siccd ticker $ prc vol ret ;

 run;
*delete missing values in pre and post;
data tick.pre;
 set tick.pre;
  if  prc= . then delete;
  if siccd = . then delete;
  if prc=<0 then delete;
run;
data tick.post;
 set tick.post;
  if prc = . then delete;
  if siccd = . then delete;
  if prc=<0 then delete;
run;
*get log return ;
data tick.pre;
 set tick.pre;
 run;
 proc sort data=tick.pre;
 by permno ;
 run;
 proc means data=tick.pre nmiss n;run;
 data tick.pre;
    set tick.pre;
	by permno;
	log_re=log(prc/lag(prc));*daily log return;

	if first.permno=1 then do;
	  log_re=.;
	end;

run;
data tick.post;
 set tick.post;
 run;
 proc sort data=tick.post;
 by permno ;
 run;
 proc means data=tick.post nmiss n;run;
 data tick.post;
    set tick.post;
	by permno;
	log_re=log(prc/lag1(prc)); *daily log return;
	
	if first.permno=1 then do;
	 log_re=.;
	end;
run;
*get log return volatility;
proc means data=tick.pre std;
class permno;
var log_re;
output out= tick.sig_pre std= sigma;
run;
proc means data=tick.post std;
class permno;
var log_re;
output out= tick.sig_post std= sigma;
run;
*annualized standard deviation;
data tick.sig_pre;
set tick.sig_pre;
sigma=sqrt(252)*sigma;
run;
data tick.sig_post;
set tick.sig_post;
sigma=sqrt(252)*sigma;
run;
ods html close;
ods pdf close;
proc export data=tick.change_list outfile="&datadir.\Data\Tick\change_list.xlsx" dbms=xlsx replace;
run;
proc export data=tick.securities_list outfile="&datadir.\Data\Tick\securities_list.xlsx" dbms=xlsx replace;
run;
proc export data=tick.mkt_maker_profit outfile="&datadir.\Data\Tick\mkt_maker_profit.xlsx" dbms=xlsx replace;
run;
proc export data=tick.mkt_part_stat outfile="&datadir.\Data\Tick\mkt_participant.csv" dbms=csv replace;
run;

