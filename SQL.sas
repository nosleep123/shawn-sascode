dm "log;clear;";

%let datadir =C:\Users\Shuhao Ren\Dropbox\SAS\Part_2_Yang;
libname check "&datadir.\Data";
ods html gpath="&datadir.\graph" path="&datadir.\output" file="check.html" ;
ods pdf file="&datadir.\output\check.pdf" ;
proc import datafile="&datadir.\Data\Sylvain.xlsx" dbms=xlsx out=check.sd replace;
getnames=yes;
run;

proc import datafile="&datadir.\Data\Shuhao.xlsx" dbms=xlsx out=check.sr replace;
getnames=yes;
run;

proc contents data=check.sd;
run;
proc contents data=check.sr;
run;


proc sql;
create table check.final_check as 
select a.ticker, b.sr_ticker,a.sd_releasedate,b.sr_releasedate,a.sd_releasetime,b.sr_releasetime,
a.sd_forperiodending,b.sr_forperiodending,a.sd_actual,b.sr_actual,
a.sd_forecastmedian,b.sr_forecastmedian
from check.sd a full join check.sr b
on a.ticker=b.sr_ticker and  a.sd_releasedate=b.sr_releasedate;
proc export data=check.final_check outfile="&datadir.\Data\final_check3.xlsx" dbms=xlsx replace;
run;



/*Calculate the difference*/




data check.clean2(where=(sr_ticker="CPI URBAN" OR sr_ticker="CONSUMER CONFIDENCE" OR sr_ticker="GDP ADVANCE" OR sr_ticker="INITIAL JOBLESS CLAIMS" OR sr_ticker="NAPM-ISM PMI" OR sr_ticker ="NONFARM PAYROLLS"));
set check.final_check;
run;
proc export data=check.clean2 outfile="&datadir.\Data\clean2.xlsx" dbms=xlsx replace;
run;
proc export data=check.final_check outfile="&datadir.\Data\final_check.xlsx" dbms=xlsx replace;
run;


