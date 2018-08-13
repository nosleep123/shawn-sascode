%let datadir =C:\Users\Shuhao Ren\Dropbox\SAS\Part_2_Yang;
%let macrodir=C:\Users\Shuhao Ren\Dropbox\SAS\Part_2_Yang\Code\fama-french-industry-master\SAS;
libname tick "&datadir.\Data\Tick";
ods html gpath="&datadir.\graph" path="&datadir.\output" file="First Step.html" ;
ods pdf file="&datadir.\output\First Step: Pattern Analysis.pdf" ;

******************************************************
/* Welch Test for Volume, Log Return, SIC, and Volatility*/


*data for Welch test pre-treatment;

data data1;
set tick.pre_trend;
if tick_grp ne 'C' then tick_grp='T';*'T' is for treatment group;
else tick_grp='C';
sic2=int(siccd/10);
keep permno date sic2 Ticker vol  log_re tick_grp;
run;
*Welch test for pre-treatment;

proc ttest data=data1 cochran ci=equal umpu plots=none;
class tick_grp;
var  vol log_re sic2;
title "Welch Test for Pre-treatment of Volume, Log Return, and SIC";
run;

*data for Welch test post-treatment;

data data2;
set tick.post_trend;
if tick_grp ne 'C' then tick_grp='T';*'T' is for treatment group;
else tick_grp='C';
sic2=int(siccd/10);
keep permno date sic2 Ticker vol  log_re tick_grp;
run;
*Welch test for post-treatment;
proc ttest data=data2 cochran ci=equal umpu plots=none;
class tick_grp;
var  vol log_re sic2;
title "Welch Test for Post-treatment of Volume, Log Return, and SIC";
run;

*data for Welch test pre volatility;

data data3;
set tick.sig_pre_trend;
if tick_grp ne 'C' then tick_grp='T';*'T' is for treatment group;
else tick_grp='C';

title "Welch Test for Pre-treatment Volatility";
keep permno date Ticker sigma tick_grp;
run;
*Welch test for pre volatility;
proc ttest data=data3 cochran ci=equal umpu ;
class tick_grp;
var  sigma;
run;

*data for Welch test post volatility;

data data4;
set tick.sig_post_trend;
if tick_grp ne 'C' then tick_grp='T';*'T' is for treatment group;
else tick_grp='C';

title "Welch Test for Post-treatment Volatility";
keep permno date Ticker sigma tick_grp;
run;
*Welch test for pre volatility;
proc ttest data=data4 cochran ci=equal umpu ;
class tick_grp;
var  sigma;
run;

******************************************************
/* Difference in Difference Analysis*/;


data did;
set tick.dd;
if tick_grp='C' then treat=0;*set dummy variable Treat;
else treat=1;
sic2=int(siccd/10);
t_p=treat*post;
run;
proc reg data=did;
model vol = treat post t_p;
title "Difference in Difference Test of Volume";
quit;
proc reg data=did;
model log_re=treat post t_p;
title "Difference in Difference Test of Log Return";
quit;
proc reg data=did;
model sic2=treat post t_p;
title "Difference in Difference Test of SIC";
quit;



data sig_did;
set tick.sig_dd;
if tick_grp='C' then treat=0;*set dummy variable Treat;
else treat=1;
t_p=treat*post;
run;
proc reg data=sig_did;
model sigma = treat post t_p;
title "Difference in Difference Test of Volatility";
quit;


******************************************************
/* Number of Stocks by Farma French Industry 12 or 49*/;


%include "&macrodir.\Siccodes49.sas";
%include "&macrodir.\Siccodes12.sas";
%ff49(dsin = tick.pre, dsout=tick.pre_ind_49, sicvar=siccd, varname=ff49);
%ff49(dsin = tick.post, dsout=tick.post_ind_49, sicvar=siccd, varname=ff49);
%ff49(dsin = tick.dd, dsout=tick.total_ind_49, sicvar=siccd, varname=ff49);

%ff12(dsin = tick.pre, dsout=tick.pre_ind_12, sicvar=siccd, varname=ff12);
%ff12(dsin = tick.post, dsout=tick.post_ind_12, sicvar=siccd, varname=ff12);
%ff12(dsin = tick.dd, dsout=tick.total_ind_12, sicvar=siccd, varname=ff12);
* Number of stocks by industry under Farma French 49;
 
*use ff49;
proc sgplot data=tick.pre_ind_49;
  histogram ff49;
  title "Percent Of Stocks In Each Industry Pre-treatment By Farma French 49";
run;

proc sgplot data=tick.post_ind_49;
  histogram ff49;
  title "Percent Of Stocks In Each Industry Post-treatment By Farma French 49";
run;
/*Plot Control Group Both pre and post*/
proc sgplot data=tick.total_ind_49(where=( tick_grp = "C"));
  histogram ff49;
  title "Percent Of Stocks In Each Industry Of Control Group During Pre and Post Treatment By Farma French 49";
run;
/*Plot Treatment Group Both pre and post*/
proc sgplot data=tick.total_ind_49(where=( tick_grp ne "C"));
  histogram ff49;
  title "Percent Of Stocks In Each Industry Of Treatment Group During Pre and Post Treatment By Farma French 49";
run;
*use ff12;
proc sgplot data=tick.pre_ind_12;
  histogram ff12;
  title "Percent Of Stocks In Each Industry Pre-treatment By Farma French 12";
run;

proc sgplot data=tick.post_ind_12;
  histogram ff12;
  title "Percent Of Stocks In Each Industry of Control Group During Post-treatment By Farma French 12";
run;
/*Plot Control Group Both pre and post*/
proc sgplot data=tick.total_ind_12(where=(tick_grp="C"));
  histogram ff12;
  title "Percent Of Stocks In Each Industry of Control Group During Pre and Post Treatment By Farma French 12";
run;
/*Plot Treatment Group Both pre and post*/
proc sgplot data=tick.total_ind_12(where=(tick_grp ne "C"));
  histogram ff12;
  title "Percent Of Stocks In Each Industry of Treatment Group During Pre and Post Treatment By Farma French 12";
run;
ods html close;
ods pdf close;
