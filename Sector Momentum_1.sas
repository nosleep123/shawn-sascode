%let datadir =D:\Dropbox\SAS\Part_2_Yang;
libname moment "&datadir.\Data";
ods html gpath="&datadir.\graph" path="&datadir.\output" file="momentum.html" ;
ods pdf file="&datadir.\output\momentum.pdf" ;

/* Data Step*/
proc import datafile="&datadir.\Data\sector momentum.xlsx" dbms=xlsx replace out=moment.raw;
sheet="Percentage"; 
getnames=yes;
run;

*Turn SAS data to Matrices;
proc iml;
   reset print;
use moment.raw;
read all var{xly xlp xle xlf xlv xli xlb xlk xlu} into a;
*Create rankings based on past 6 month cumulative returns;
b=j(nrow(a)-5,9,0);
*calculate the past 6 month cumulative return;
 
do p=6 to nrow(a); 
  do i=1 to 9;
  b[p-5,i]=(1+a[p,i])*(1+a[p-1,i])*(1+a[p-2,i])*(1+a[p-3,i])*(1+a[p-4,i])*(1+a[p-5,i])-1;
 end;
end;
print b;

*rank b matrix the biggest return would be 9 and the smallest return would be 1;
c=j(nrow(b),ncol(b),0);
do t=1 to nrow(c);
 c[t,]=rank(b[t,]);
end;
print c;
 



