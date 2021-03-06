dm "log;clear;";
%let datadir =C:\Users\Shuhao Ren\Dropbox\SAS\Part_2_Yang;
libname tick "&datadir.\Data\Tick";

*merge reference and securities in pilot program in merge1;
data reference(drop= PRIMEXCH );
set tick.reference;
run;
proc sort data=reference;
by ticker;
run;
proc sort data=tick.securities_list;
by ticker_symbol;
run;
data tick.sec_list(drop=ticker_symbol );
set tick.securities_list;
ticker=ticker_symbol;
run;
data tick.merge1;
merge reference tick.sec_list(in=a);
by ticker;
if a;
run;
data tick.merge1;
set tick.merge1;
if permno=. then delete;
run;
* merge trading symbol (TAQ symbol) with merge1 in merge2;
proc sort data=tick.merge1;
by permno;
run;
data trade_symbol(drop=date);
set tick.trade_symbol;
run;
proc sort data=trade_symbol;
by permno;
run;
data tick.merge2;
merge trade_symbol tick.merge1 (in=a);
by permno;
run;
data tick.merge2;
set tick.merge2;
if ticker='' then delete;
run;
*merge changes list with merge2 in merge3;

data tick.chan_list(drop=ticker_symbol listing_exchange security_name Tick_Size_Pilot_Program_Group);
set tick.change_list;
ticker=ticker_symbol;
run;
proc sort data=tick.chan_list;
by ticker;
run;
data merge2(drop=effective_date);
set tick.merge2;
run;
proc sort data=merge2;
by ticker;
run;
data tick.merge3;
merge tick.chan_list merge2(in=a);
by ticker;
if a ;
run;
*merge pre  with treatment group indentifier;
data reference;
set tick.merge2;
run;
proc sort data=reference;
by permno;
proc sort data=tick.pre;
by permno;
run;
data tick.pre_trend;
merge tick.pre(in=a) reference;
by permno;
run;
*merge post  with treatment group indentifier;
data reference2;
set tick.merge2;
run;
proc sort data=reference2;
by permno;
proc sort data=tick.post;
by permno;
run;
data tick.post_trend;
merge tick.post(in=a) reference2;
by permno;
run;
*simplify variable name;
data tick.pre_trend;
set tick.pre_trend;
tick_grp=tick_size_pilot_program_group;
run;
data tick.post_trend;
set tick.post_trend;
tick_grp=tick_size_pilot_program_group;
run;
*merge post and pre of volume log_re and sic;
data pre;
set tick.pre_trend;
post=0;
run;
data post;
set tick.post_trend;
post=1;
run;
proc sort data=pre;
by permno;
proc sort data=post;
by permno;
run;
data tick.dd;
set pre post;
by permno;
run;
data tick.dd;
set tick.dd;
keep siccd log_re permno date ticker vol tick_grp post;
run;
*merge volatility file with reference;
proc sort data=tick.sig_pre;
by permno;
proc sort data=tick.merge2;
by permno;
data tick.sig_pre_trend;
merge tick.sig_pre(in=a) tick.merge2;
if a ;
run;
proc sort data=tick.sig_post;
by permno;
proc sort data=tick.merge2;
by permno;
data tick.sig_post_trend;
merge tick.sig_post(in=a) tick.merge2;
if a ;
run;
*simplify variable name;
data tick.sig_pre_trend;
set tick.sig_pre_trend;
tick_grp=tick_size_pilot_program_group;
run;
data tick.sig_post_trend;
set tick.sig_post_trend;
tick_grp=tick_size_pilot_program_group;
run;

*merge post and pre of volatility;
data sig_pre;
set tick.sig_pre_trend;
post=0;
run;
data sig_post;
set tick.sig_post_trend;
post=1;
run;
proc sort data=sig_pre;
by permno;
proc sort data=sig_post;
by permno;
run;
data tick.sig_dd;
set sig_pre sig_post;
by permno;
run;
data tick.sig_dd;
set tick.sig_dd;
keep  permno date ticker sigma tick_grp post;
run;

proc export data=tick.merge1 outfile="&datadir.\Data\Tick\merge1.csv" dbms=csv replace;
run;
proc export data=tick.merge2 outfile="&datadir.\Data\Tick\merge2.csv" dbms=csv replace;
run;
proc export data=tick.merge3 outfile="&datadir.\Data\Tick\merge3.csv" dbms=csv replace;
run;
proc export data=tick.check outfile="&datadir.\Data\Tick\mergecheck.csv" dbms=csv replace;
run;
proc export data=tick.pre_trend outfile="&datadir.\Data\Tick\pre_trend.csv" dbms=csv replace;
run;
proc export data=tick.post_trend outfile="&datadir.\Data\Tick\post_trend.csv" dbms=csv replace;
run;
proc export data=tick.dd outfile="&datadir.\Data\Tick\diff_in_diff.csv" dbms=csv replace;
run;
proc export data=tick.pre outfile="&datadir.\Data\Tick\pre.csv" dbms=csv replace;
run;
proc export data=tick.post outfile="&datadir.\Data\Tick\post.csv" dbms=csv replace;
run;
