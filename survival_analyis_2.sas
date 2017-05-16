OPTIONS S=72  MISSING= ' ' NOSOURCE NOCENTER PS=9999;
DM "log; clear; ";
dm 'odsresults; clear';
libname dbo ODBC DSN=SFCC_DW UID=SFCC_DW_IR PWD=R3ad_0n!y  SCHEMA=DBO;


PROC IMPORT DATAFILE= "S:\Reports\common\Data Request\Programs\William\survival_analysis\fa12_data_2.xlsx"	
OUT=surv_dat
	 DBMS=EXCEL2010 REPLACE;
run;



data in;
	length Id $20;
	input age Id $3-8 ;
	datalines;
19 age19
28 age28

;
ods graphics on;
proc phreg data=surv_dat plots(overlay)=survival;
	class race;
	model yrs*status(1)= age;
	baseline  covariates= in out=Pred1 survival=_all_;
	run;


	/*********** credits ******************/

	data in2;
	length Id $20;
	input credits Id $3-8 ;
	datalines;
3  cr3
6  cr6
9  cr9
12 cr12
15 cr15
;

proc phreg data=surv_dat plots(overlay)=survival;
	model yrs*status(1)=credits;
	baseline  covariates=in2 out=Pred1 survival=_all_;
	run;



/************ race *************/

proc phreg data=surv_dat plots(overlay)=survival;
	class race;
	model yrs*status(1)=credits race;
	baseline  covariates=surv_dat out=Pred1 survival=_all_/diradj group=race;
	run;


	/************race ********/
data in3;
	length Id $20;
	input race Id $3-8 ;
	datalines;
1_  race1
2_  race2
3_  race3
4_  race4
5  race5
6  race6
;


proc phreg data=suvr_dat plots(overlay)=survival;
	class race;
	model yrs*status(1)=race;
	baseline  covariates=in3 out=Pred1 survival=_all_;
	run;
