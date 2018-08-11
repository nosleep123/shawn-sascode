%let datadir= C:\D Disk\Freddie Mac;
%let span=%sysevalf(1.0/(1.0+2.0));
%put span;
libname Freddie "&datadir.\data";
******Set up preferences*********;
ods html gpath="&datadir.\graph" path="&datadir.\output" file="Freddie_Project.html";
ods pdf file="&datadir.\output\Freddie_Project.pdf";
ods listing gpath="&datadir.\temp";

********************************************************************************************************************************
*****Data Steps********;
proc import datafile="&datadir.\data\PD_seller.xlsx" dbms=xlsx replace out=pd;
sheet="PD of seller"; 
getnames=yes; 
run;
********************************************************************************************************************************
********************************************************************************************************************************
******Part 1: PD*********;
data pd;
set pd;
format year 4.0;
cyear=input(year,4.);
rename P_D_=pd;
run;
data pd_seller;
set pd;
keep cyear pd;
run;
proc sort data=pd_seller; by cyear;

******Choice1:change span every time*********;
proc expand data=pd_seller out=mvpd_seller method=none;
convert pd=pd_mv/transformout=(ewma &span.);
run;
*******************************************************************************************************************************
********************************************************************************************************************************
******Part 2: Expected Exposure*********;
proc import datafile="&datadir.\data\expected_exposure.xlsx" dbms=xlsx replace out=ee_seller;
sheet="Result"; 
getnames=yes; 
run;
data Ee_seller;
set Ee_seller;
rename Year=cyear;
rename ee_a=ee; label ee="average exposure";
rename ee_s=es; label es="stress exposure";
rename ee=ea; label ea="expected exposure";
run;
*********Merge Two Datasets***********;
proc sort data=ee_seller; by cyear;
proc sort data=mvpd_seller; by cyear;
data seller_combine;
merge mvpd_seller(in=a) ee_seller(in=b);
by cyear;
if b;
drop time pd es ee;
run;
proc sgplot data=seller_combine;
scatter x=ea y=pd_mv/ markerattrs=(symbol=square);
titLe"Joint Histogram(Seller-servicers Default Rate & Exposure)";
run;
*********Calculate Correlation***********;
title 'Original Dataset Correlation';
ods output kendallcorr= corr;
proc corr data=seller_combine nosimple kendall;
var ea;
with pd_mv;
run;

********************************************************************************************************************************
********************************************Fitting Distributions***************************************************************
********************************************************************************************************************************
********Fitting PD Marginal Distribution***********;
*********Perpare Dataset***********;
data mvpd_seller;
set mvpd_seller;
drop time cyear pd;
run;
*********Fit Lognormal Distribution************;
title 'Fitted lognormal Deistribution of PD_Seller';
ods graphics on;
ods select Histogram ParameterEstimates GoodnessOfFit FitQuantiles;
proc univariate data=mvpd_seller;
   var pd_mv;
   histogram / midpoints=0to 0.03 by 0.005
               lognormal
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
run;
quit;
/*********Fit Beta Distribution************;
title 'Fitted Beta Distribution of PD_Seller';
ods select ParameterEstimates FitQuantiles Histogram;
proc univariate data=mvpd_seller;
   histogram pd_mv /
      beta(theta=0 scale=1 fill)
      odstitle  = 'Fitted Beta Distribution of PD_Seller';
   inset n = 'Sample Size' /
      pos=ne  cfill=blank;
run;
*********Fit Weibull Distribution************;
title 'Fitted weibull Deistribution of PD_Seller';
ods select Histogram ParameterEstimates GoodnessOfFit FitQuantiles;

proc univariate data=mvpd_seller;
   var pd_mv;
   histogram / midpoints=0to 0.03 by 0.005
               weibull
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
run;
*********Fit Gamma Distribution************;
title 'Fitted Gamma Distribution of PD_Seller';
proc univariate data=mvpd_seller;
   ods select ParameterEstimates GoodnessOfFit FitQuantiles MyHist;
   var pd_mv;
   histogram / midpoints=0to 0.03 by 0.005
               gamma
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
   axis1 label=(a=90 r=0);
run;*/

********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********Fitting EE Marginal Distribution*********;
*********Fit Beta Distribution************;
*********Fit Lognormal Distribution************;
title 'Fitted lognormal Deistribution of EE_Seller';
ods select Histogram ParameterEstimates GoodnessOfFit FitQuantiles;
proc univariate data=ee_seller;
   var ea;
   histogram / midpoints=0to 0.055 by 0.005
               lognormal
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
run;
/*ods select ParameterEstimates FitQuantiles Histogram;
proc univariate data=ee_seller;
   histogram ea /
      beta(theta=0 scale=1 fill)
      odstitle  = 'Fitted Beta Distribution of EE_Seller';
   inset n = 'Sample Size' /
      pos=ne  cfill=blank;
run;
*********Fit Weibull Distribution************;
title 'Fitted weibull Distribution of EE_Seller';
ods select Histogram ParameterEstimates GoodnessOfFit FitQuantiles;
proc univariate data=ee_seller;
   var ea;
   histogram / midpoints=0to 0.055 by 0.005
               weibull
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
run;
*********Fit Gamma Distribution************;
title 'Fitted Gamma Distribution of EE_Seller';
ods select Histogram ParameterEstimates GoodnessOfFit FitQuantiles;
proc univariate data=ee_seller;
   var ea;
   histogram / midpoints=0to 0.055 by 0.005
               gamma
               odstitle = title;
   inset n mean(5.3) std='Std Dev'(5.3) skewness(5.3)
          / pos = ne  header = 'Summary Statistics';
run;*/


********************************************************************************************************************************
************************************Generate new dataset for joint distribution*************************************************
*******Generate marginal numbers***********;
%let N=1000;
data marginal_pd (keep=x);
do i=1 to &N.;
x=rand("lognoraml",-6.61419,1.528319);*******Change parameters everytime***********;
output;
end;
run;
data marginal_pd ;
set marginal_pd;
rename x=pd;
run;
data marginal_ee (keep=x);
do i=1 to &N.;
x=rand("lognormal",-4.27318,0.438112);*******Change parameters everytime************;
output;
end;
run;
data marginal_ee;
set marginal_ee;
rename x=ee;
run;
data marginal_combined;
merge marginal_ee marginal_pd;
run;
/*proc export data=marginal_combined outfile="&datadir./data/marginal_combined" dbms=xlsx;
run;*/

********************************************************************************************************************************
****************************************Use Copula Metheod for joint distribution***********************************************
********************************************************************************************************************************
*******Fit a Copula(Not applicable as we decide to use fitted correlation in joint distribution***********;
/*data seller_copula;
set seller_combine;
drop cyear;
run;
proc corr data=seller_copula kendall outk=corrk;
var pd_mv ea;
run;
data corrk;
set corrk;
if _type_="MEAN" then delete;
if _type_="STD" then delete;
if _type_="N" then delete;
drop _Type_;
run;
data pearson;
set corrk;
pd_t=sin(constant('pi')*pd_mv/2);
ea_t=sin(constant('pi')*ea/2);
run;
data pearson;
set pearson;
keep pd_t ea_t;
run;
proc copula data = marginal_combined;
var pd ee;
fit normal / outcopula=estimates;
run;*/

/*****Copula estimation and simulation*******;
proc copula data = marginal_combined;
var pd ee;
fit normal /marginals=empirical;
simulate /  ndraws = 5000
            out=simulated_normal
            plots=(distribution=pdf);
run;*/
*****Simulate T copula*******;
proc copula data = marginal_combined;
var pd ee;
fit T init=(df=3)/marginals=empirical;
simulate cop / ndraws = 1000  
out = simulated_t
plots=(distribution=cdf);
run;

/*****Simulate Clayton copula*******;
proc copula data = marginal_combined;
var pd ee;
fit clayton /marginals=empirical;
simulate / 
ndraws = 5000
marginals=empirical
out=simulated_clayton
plots=(distribution=pdf);
run;

*****Simulate Gumbel copula*******;
proc copula data = marginal_combined;
var pd ee;
fit gumbel /marginals=empirical;
simulate / 
ndraws = 5000
marginals=empirical
out=simulated_gumbel
plots=(distribution=pdf);
run;*/

********************************************************************************************************************************
****************************************Calculate alpha*************************************************************************
********************************************************************************************************************************
****Take T as default*******;
/*%let type=t;               ****Specify the type of copula data you want to use:normal/t/clayton/gumbel*******;
data simulated_alpha;
set simulated_&type.;
joint=pd*ee;
run;

****Calculate numerator*******;
proc sort data=simulated_alpha; by joint; run;
proc univariate data=simulated_alpha noprint;
var joint; 
output out=numerator pctlpre=joint pctlpts= 99.9;
run;

****Calculate denominator*******;
proc sort data=marginal_combined; by pd; run;
proc univariate data=marginal_combined noprint;
var pd; 
output out=pd_99 pctlpre=pd pctlpts= 99.9;
run;
proc univariate data=marginal_combined noprint;
var ee; 
output out=mean mean=ee_50;
run;
****Merge Data*******;
data combine_alpha;
set numerator;
set pd_99;
set mean;
denomenator=pd99_9*ee_50
alpha=joint99_9/denomenator;
run;*/
*****Repeat multiple times to determine alpha mean, statistical uncertainty ******;
%macro alpha(time=);
proc datasets noprint;
	delete alpha _alpha;
run;quit;
data alpha;
run;
%do i=1 %to &time.;                      
    ods exclude all;
    proc copula data = marginal_combined;
         var pd ee;
         fit T init=(df=3)/marginals=empirical;
         simulate cop / ndraws = 1000  
         out = simulated_t;
    run;
    data simulated_alpha;
    set simulated_t;
        joint=pd*ee;
    run;
    proc sort data=simulated_alpha; by joint; run;
    proc univariate data=simulated_alpha noprint; 
         var joint; 
    output out=numerator pctlpre=joint pctlpts= 99.9;
    run;
    proc sort data=marginal_combined; by pd; run;
    proc univariate data=marginal_combined noprint;
         var pd; 
         output out=pd_99 pctlpre=pd pctlpts= 99.9;
    run;
    proc univariate data=marginal_combined noprint;
         var ee; 
         output out=mean mean=ee_50;
    run;
    data _alpha;
         set numerator;
         set pd_99;
         set mean;
         denomenator=pd99_9*ee_50;
         alpha=joint99_9/denomenator;
		 Time = &i.;
    run; 
	data alpha;
	    set alpha _alpha;
	run;
%end;
data alpha_&time.times;
	set alpha;
	if alpha=. then delete;
run;
proc datasets noprint;
	delete _alpha;
run;quit;
%mend alpha;
%alpha(time=50);                            /*change to the times you want*/
proc means data=alpha noprint;     /*change dataset name according to times*/
var alpha;
output out=alpha mean=_mean std=_std;
run;

********************************************************************************************************************************
************************************************Sensitivity Analysis************************************************************
********************************************************************************************************************************;
*****Parameters Sensitivity******;
******PD Error*******************;
%macro pd_fit(datafile=,var=,sampsize=,time=);
proc datasets noprint;
	delete est _est;
run;quit;
data est;
run;
%do i=1 %to &time.;
	proc surveyselect data=&datafile. out=sample method=srs
		sampsize=&sampsize.;
	run; 
	ods exclude all;
	ods output ParameterEstimates=_est;
	proc univariate data=sample noprint;
   		histogram &var.  /
      		midpoints=0to 0.03 by 0.005
            lognormal
      		odstitle  = 'Fitted Lognormal Distribution of PD_Seller';
   		inset n = 'Sample Size' /
      		pos=ne  cfill=blank;
	run;
	data _est;
		set _est;
		Time = &i.;
	run;
	data est;
		set est _est;
		if symbol="Theta" or symbol=" " then delete;
		drop parameter histogram;
	run;
%end;
data PD_&time.times_&sampsize.samples;
	set est;
	if estimate=. then delete;
run;
proc datasets noprint;
	delete est _est sample;
run;quit;
%mend pd_fit;
%pd_fit(datafile=mvpd_seller,var=pd_mv,sampsize=40,time=100);  /*change to the times you want*/
proc sort data=pd_100times_40samples; by time; run;/*change dataset name according to times*/
proc means data=pd_100times_40samples print;     /*change dataset name according to times*/
var estimate;
class symbol;
output out=pd_error mean=_mean std=_std;
run;
*******Sensitivity of pd***********;
%macro pd_alpha(par1m=,par1s=,par2m=,par2s=);
proc datasets noprint;
	delete pd_alpha;
run;quit;

data marginal_pd(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.+&par1s.),%sysevalf(&par2m.));
output;
end;
run;

data marginal_pd ;
set marginal_pd;
rename x=pd;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=50);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_1 mean=_mean;
run;

data marginal_pd(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.-&par1s.),%sysevalf(&par2m.));
output;
end;
run;

data marginal_pd ;
set marginal_pd;
rename x=pd;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;
run;

%alpha(time=50);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_2 mean=_mean;
run;

data marginal_pd(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.),%sysevalf(&par2m.+&par2s.));
output;
end;
run;

data marginal_pd ;
set marginal_pd;
rename x=pd;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=50);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_3 mean=_mean;
run;

data marginal_pd(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.),%sysevalf(&par2m.-&par2s.));
output;
end;
run;

data marginal_pd ;
set marginal_pd;
rename x=pd;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=50);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_4 mean=_mean;
run;

data pd_alpha;
	set alpha_1 alpha_2 alpha_3 alpha_4;
run;
%mend pd_alpha;
%pd_alpha(par1m=0.5617,par1s=0.0486,par2m=0.0075,par2s=0.0016);  /*change parameters*/

******EE Error*******************;
%macro ee_fit(datafile=,var=,sampsize=,time=);
proc datasets noprint;
	delete est _est;
run;quit;
data est;
run;
%do i=1 %to &time.;
	proc surveyselect data=&datafile. out=sample method=srs
		sampsize=&sampsize.;
	run; 
	ods exclude all;
	ods output ParameterEstimates=_est;
	proc univariate data=sample noprint;
   		histogram &var.  /
      		midpoints=0to 0.055 by 0.005
			lognormal
      		odstitle  = 'Fitted lognormal Distribution of EE_Seller';
   		inset n = 'Sample Size' /
      		pos=ne  cfill=blank;
	run;
	data _est;
		set _est;
		Time = &i.;
	run;
	data est;
		set est _est;
		if symbol="Theta" or symbol=" " then delete;
		drop parameter histogram;
	run;
%end;
data EE_&time.times_&sampsize.samples;
	set est;
	if estimate=. then delete;
run;
proc datasets noprint;
	delete est _est sample;
run;quit;
%mend ee_fit;
%ee_fit(datafile=ee_seller,var=ea,sampsize=19,time=200); /*change to the times you want*/
proc means data=ee_200times_19samples noprint;     /*change dataset name according to times*/
var estimate;
class symbol;
output out=ee_error mean=_mean std=_std;
run;
*******Sensitivity of ee***********;
%macro ee_alpha(par1m=,par1s=,par2m=,par2s=);
proc datasets noprint;
	delete ee_alpha;
run;quit;

data marginal_ee(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.+&par1s.),%sysevalf(&par2m.));
output;
end;
run;

data marginal_ee;
set marginal_ee;
rename x=ee;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=10);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_1 mean=_mean;
run;

data marginal_ee(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.-&par1s.),%sysevalf(&par2m.));
output;
end;
run;

data marginal_ee;
set marginal_ee;
rename x=ee;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=10);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_2 mean=_mean;
run;

data marginal_ee(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.),%sysevalf(&par2m.+&par2s.));
output;
end;
run;

data marginal_ee ;
set marginal_ee;
rename x=ee;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=10);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_3 mean=_mean;
run;

data marginal_ee(keep=x);
do i=1 to 1000;
x=rand("lognormal",%sysevalf(&par1m.),%sysevalf(&par2m.-&par2s.));
output;
end;
run;

data marginal_ee ;
set marginal_ee;
rename x=ee;
run;

data marginal_combined;
merge marginal_ee marginal_pd;
run;

%alpha(time=10);                            /*change to the times you want*/
proc means data=alpha noprint;              /*change dataset name according to times*/
var alpha;
output out=alpha_4 mean=_mean;
run;

data pd_alpha;
	set alpha_1 alpha_2 alpha_3 alpha_4;
run;
%mend ee_alpha;
%ee_alpha(par1m=0.556743,par1s=0.053817,par2m=0.007583,par2s=0.001738);  /*change parameters*/

ods pdf close
