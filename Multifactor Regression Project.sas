%let datadir =/folders/myfolders;
libname mydata "&datadir./data";
ods html gpath="&datadir./graph" path="&datadir./output" file="final.html" ;
ods pdf file="&datadir./output/final.pdf" ;
proc import datafile="&datadir./data/Farm.xlsx" dbms = xlsx replace out=farmfrench;*import data of farma french*;
	getnames = yes;
run;
data "&datadir./temp/farmfrench";
	set farmfrench;
run;
libname mydata "&datadir./data";
ods html gpath="&datadir./graph" path="&datadir./output" file="final.html" ;
ods pdf file="&datadir./output/final.pdf" ;
*****************************missing values********************************;
data retail;
set mydata.retail;
data retail_newvars;
set mydata.retail_newvars;
run;
proc contents data=retail;
run;
proc contents data=retail_newvars;
run;
data data_merge1;
merge retail(in=a) retail_newvars(keep=act lct ch emp invt csho pstk prcc_f dlc dltt );
if a;
run;
data check;
set data_merge1;
if lct eq . or csho eq . or invt eq . or at eq . or revt eq . or pstk eq . or prcc_f eq . or dlc eq . or dltt eq .  ;
run;
proc sort data=check(keep=gvkey fyear lct csho pstk invt at revt prcc_f dlc dltt)   noduplicate;
by gvkey fyear;
run;
proc means data=check nmiss;   *check how many missing values resulted by each variable*;
var lct prcc_f csho pstk invt at revt dlc dltt;
run;
proc sort data=check(drop=pstk prcc_f csho dlc dltt);
by gvkey fyear;
proc sort data=data_merge1;
by gvkey;
run; 
data data_merge2(drop=pstk prcc_f csho dlc dltt);
merge check(in=a ) data_merge1;
by gvkey fyear;
if not a;
run;
proc sort data=data_merge2;
by fyear;
run;
******merge with macro variables*******;
data macro_var_new(keep=year g_gdp g_cpi ffo credit_sprd);
set mydata.macro_var_final;
if year>1999;
run;
data data_final;
merge macro_var_new(in=a rename=(year=fyear)) data_merge2;
by fyear;
if a ;
run;
proc sort data=data_final;
by gvkey fyear;
run;
data farm_new;
set farmfrench;
if fyear ne .;
run;
proc sort data=data_final;
by fyear;
run;
data data_final;
merge farm_new(in=a) data_final;
by fyear;
if a ;
run;
proc sort data=data_final;
by gvkey fyear;
run;
*****************************compute financial ratios variables********************************;
data data_final;
set data_final;
by gvkey fyear;

if capx = . or capx<0 then capx=0;		
	if ch=. or ch<0 then ch=0;
	
	

if act>0 then ct_ratio=act/lct;
if ebitda>0 then 
ebitda_mar=ebitda/revt;


invt_lag1=lag1(invt);
at_lag1=lag1(at);
revt_lag1=lag1(revt);
if first.gvkey=1 then do;
at_lag1=.;
invt_lag1=.;
revt_lag1=.;
end;
if invt_lag1>0 then invt_avg=(invt_lag1+invt)/2;
if at_lag1>0 then at_avg=(at+at_lag1)/2;
label invt_avg="Inventory average";
label at_avg="asset average";

if revt_lag1>0 then g_revt=revt/revt_lag1-1;
if cogs ne . then invt_turn=cogs/invt_avg;
if oiadp ne . then ROA=oiadp/at_avg;
if capx ne . then 
capx_ratio=capx/at_lag1;
if ch ne . then 
cash_h=ch/at;
if emp ne . then ln_emp=log(emp);
if at ne . then ln_at=log(at);
label ln_emp="employee size";
label ln_at="asset size";
label capx_ratio="capital expenditure ratio";
label cash_h="cash holdings";
label invt_turn="inventory turnover";
label ROA="Return on Asset";
label ct_ratio="current ratio";
label ebitda_mar="ebitda marign";
proc means data=data_final n nmiss mean median min max p1 p5 p95 p99 maxdec=3;
	var g_revt ln_emp ln_at  capx_ratio cash_h invt_turn ROA ct_ratio ebitda_mar g_cpi g_gdp ffo credit_sprd smb hml usdli;
	title 'Financial Ratios - Adj for Missing';
run;
****************************winsorization********************************;
proc sort data=data_final;
	by fyear ;
proc means data=data_final noprint;
	by fyear;
	var  g_revt ln_emp ln_at  capx_ratio cash_h invt_turn ROA ct_ratio ebitda_mar g_cpi g_gdp ffo credit_sprd smb hml usdli;
	output out= _winsor p5 = _g_revt5 _ln_emp5 _ln_at5 _5 _capx_ratio5 _cash_h5 _invt_turn5 _ROA5 _ct_ratio5 _ebitda_mar5 _g_cpi5 _g_gdp5 _ffo5 _credit_sprd5 _smb5 _hml5 _usdli5 
 		p95 = _g_revt95 _ln_emp95 _ln_at95 _95 _capx_ratio95 _cash_h95 _invt_turn95 _ROA95 _ct_ratio95 _ebitda_mar95 _g_cpi95 _g_gdp95 _ffo95 _credit_sprd95 _smb95 _hml95 _usdli95 ;
run;
data NEW;
	merge data_final _winsor;
	by fyear;
	
if ln_emp ne . then ln_emp_w = max(_ln_emp5, min(_ln_emp95, ln_emp));
if ln_at ne . then ln_at_w = max(_ln_at5, min(_ln_at95, ln_at));

if capx_ratio ne . then capx_ratio_w = max(_capx_ratio5, min(_capx_ratio95, capx_ratio));
if cash_h ne . then cash_h_w = max(_cash_h5, min(_cash_h95, cash_h));
if invt_turn ne . then invt_turn_w = max(_invt_turn5, min(_invt_turn95, invt_turn));
if ROA ne . then ROA_w = max(_ROA5, min(_ROA95, ROA));
if ct_ratio ne . then ct_ratio_w = max(_ct_ratio5, min(_ct_ratio95, ct_ratio));
if ebitda_mar ne . then ebitda_mar_w = max(_ebitda_mar5, min(_ebitda_mar95, ebitda_mar));
if g_cpi ne . then g_cpi_w = max(_g_cpi5, min(_g_cpi95, g_cpi));
if g_gdp ne . then  g_gdp_w = max(_g_gdp5, min(_g_gdp95, g_gdp));
if ffo ne . then ffo_w = max(_ffo5, min(_ffo95, ffo));
if credit_sprd ne . then credit_sprd_w = max(_credit_sprd5, min(_credit_sprd95, credit_sprd));
if g_revt ne . then g_revt_w = max(_g_revt5, min(_g_revt95, g_revt));
if smb ne . then smb_w = max(_smb5, min(_smb95, smb));
if hml ne . then hml_w = max(_hml5, min(_hml95, hml));
if usdli ne . then usdli_w = max(_usdli5, min(_usdli95, usdli));
run;

data data_final (drop =_:);
	set NEW;

proc means data=data_final n nmiss mean median min max maxdec=4;
	var  g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w g_cpi_w g_gdp_w ffo_w credit_sprd_w smb_w hml_w usdli_w;
	title 'Financial Ratios - Winsorized';
run;

proc sgplot data=data_final;
histogram ln_emp_w;
run;
proc sgplot data=data_final;
histogram ln_at_w;
run;
proc sgplot data=data_final;
histogram capx_ratio_w;
run;
proc sgplot data=data_final;
histogram cash_h_w;
run;
proc sgplot data=data_final;
histogram invt_turn_w;
run;
proc sgplot data=data_final;
histogram ROA_w;
run;
proc sgplot data=data_final;
histogram ct_ratio_w;
run;
proc sgplot data=data_final;
histogram ebitda_mar_w;
run;
proc sgplot data=data_final;
histogram g_cpi_w;
run;
proc sgplot data=data_final;
histogram g_gdp_w;
run;
proc sgplot data=data_final;
histogram ffo_w;
run;
proc sgplot data=data_final;
histogram credit_sprd_w;
run;
proc sgplot data=data_final;
histogram g_revt_w;
run;

proc sgplot data=data_final;
histogram smb_w;
run;
proc sgplot data=data_final;
histogram hml_w;
run;
proc sgplot data=data_final;
histogram usdli_w;
run;
proc sort data=data_final;
	by gvkey descending fyear;
run;
data data_final;
	set data_final;
	by gvkey;
	g_revt_lead1 = lag1(g_revt_w);
	if first.gvkey = 1 then g_revt_lead1 = .;
run;
data mydata.data_final;
set data_final;
run;
****************************correlation********************************;
**********Test correlation, heteroscatasticity and multi-collinearity of firm variables*******;
proc corr data=data_final nosimple rank ;	
	var  g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w  ;
	with g_revt_lead1;
	title "Computing Pearson Correlation Coefficients";
run;

***** Spearman Nonparamateric Correlation **********;
proc corr data=data_final nosimple spearman;
	var  g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w  ;
	with g_revt_lead1;
title "Computing Spearman Rank Correlation";
run;

***Generating a correlation matrix*******;
proc corr data=data_final nosimple;	
	var  g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w  ;
run;

***ROBUSTNESS CHECKS*******;
title "Robustness Checks";

proc reg data=data_final plot=none;	
model g_revt_lead1 =   g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w/white spec ;
title "Checking for Heterscedasticity";
run;
*******Multi-collinearity*******;
proc reg data=data_final plot=none;	
model  g_revt_lead1 =    g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w  /VIF ;
title "Checking for Multi-collinearity";
run;

**********Test correlation, heteroscatasticity and multi-collinearity of macro variables*******;
data macro_var_final_new;
merge macro_var_new(rename=(year=fyear)) farm_new(in=a);
by fyear;
if a;
run;
proc corr data=macro_var_final_new;
var g_gdp g_cpi credit_sprd ffo smb hml usdli;
title "correlation of macro variables";
run;
proc corr data=data_final nosimple rank ;	
	var  g_gdp g_cpi credit_sprd ffo smb hml usdli ;
	with g_revt_lead1;
	title "Computing Pearson Correlation Coefficients";
run;
******Multi-collinearity of Macro *******;
proc reg data=data_final plot=none;	
model  g_revt_lead1 =    g_gdp g_cpi credit_sprd ffo smb hml usdli   /VIF ;
title "Checking for Multi-collinearity";
run;
****************************Model Regression********************************;
**********Stepwise Regression*******;
proc reg data=data_final plots=none outest=beta_selection tableout adjrsq;
	Stepwise: model  g_revt_lead1 = g_revt_w ln_emp_w ln_at_w  capx_ratio_w cash_h_w invt_turn_w ROA_w ct_ratio_w ebitda_mar_w g_cpi_w ffo_w  smb_w hml_w usdli_w /
  		selection = stepwise slentry=0.15 slstay=0.15;	
  		title "Model Selection";
run;
**********Double check heteroscadasticity and multi-collinearity*******;
proc reg data=data_final plot=none;	
model  g_revt_lead1 = g_revt_w  capx_ratio_w cash_h_w  ROA_w  ct_ratio_w ffo_w  smb_w ebitda_mar   /VIF white spec ;
title "Checking for Multi-collinearity and Heterodasticity";
run;
proc reg data=data_final outest=beta tableout adjrsq;	
	model g_revt_lead1 = g_revt_w  capx_ratio_w cash_h_w ffo_w  smb_w ebitda_mar  ;
	output out= est p = yhat r=resid cookd = d;
	title "Running a Simple Linear Regression Model";
run;
*********fixed effect model*******;
proc glm data=data_final;
	class fyear sic2 ;
	model g_revt_lead1 = g_revt_w  capx_ratio_w cash_h_w ffo_w  smb_w ebitda_mar  fyear sic2/solution;
	title "Year Fixed Effect and Ind Fixed Effect";
run;

proc glm data=data_final;
class fyear sic2;
model g_revt_lead1 = g_revt_w  capx_ratio_w cash_h_w ffo_w  smb_w ebitda_mar  fyear*sic2 / solution;
output out = est_fix p=yhat_fix r=resid_fix;
title "INDUSTRY-YEAR FIXED EFFECT";
run;

******Using Regressions to Predict *******;
data input;
	set data_final;
	g_revt_lead1_save = g_revt_lead1;
	if substr(gvkey, 1, 3) eq '001' then g_revt_lead1=.;	/**erase capx ratio for some firms***/

proc glm data=input plot=none noprint;
	class fyear sic2;
	model g_revt_lead1 = g_revt_w  capx_ratio_w cash_h_w ffo_w  smb_w ebitda_mar fyear*sic2/solution   ;
	output out = est_sic p=yhat_sic r=resid_sic;
run;

proc print data=est_sic(where=(substr(gvkey, 1, 3) eq '001'));
	var gvkey yhat_sic g_revt_lead1_save g_revt_w  capx_ratio_w cash_h_w ffo_w  smb_w ebitda_mar  ;
	title "Using Regressions to Predict";
run;









