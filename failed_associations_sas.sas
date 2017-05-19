
OPTIONS S=72  MISSING= ' ' NOSOURCE NOCENTER PS=9999;
DM "log; clear; ";
dm 'odsresults; clear';
libname dbo ODBC DSN=SFCC_DW UID=SFCC_DW_IR PWD=R3ad_0n!y  SCHEMA=DBO;

				/****** current courses failed *******/
*generates sids, count and lsit of current courses failed by deegree seeking students;

*generate sids;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_degree_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
		

ORDER BY Student_ID;
QUIT;*12694;


*get courses;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE courses_failed AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID
		FROM dbo.Daily_Term_Summary AS t1 
				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 
				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 
				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section
		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and T3.Course_Grade_SCH = 'F'

ORDER BY Student_ID;
QUIT;



PROC EXPORT DATA=courses_failed
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\courses_failed.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;


/*************** end of original query **************/


			/************ course failure combinations in term ************/

*generates market basket for courses failed in one term;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE failed_course_combos_interm AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course
		FROM dbo.Daily_Term_Summary AS t1 
				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 
				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 
				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course_Grade_SCH in ('D+', 'D', 'F')
			
		

ORDER BY Student_ID;
QUIT;*43202;



data fail_course1;
set failed_course_combos_interm;
format fail_course1 $10.;
fail_course1 = Course;
By student_ID;
if First.Student_ID then output;
run; *30508;

data failed_course_combos_interm3;
set failed_course_combos_interm;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data fail_course2;
set failed_course_combos_interm3;
format fail_course2 $10.;
fail_course2 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;


data failed_course_combos_interm4;
set failed_course_combos_interm3;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data fail_course3;
set failed_course_combos_interm4;
format fail_course3 $10.;
fail_course3 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;

data failed_course_combos_interm5;
set failed_course_combos_interm4;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data fail_course4;
set failed_course_combos_interm5;
format fail_course4 $10.;
fail_course4 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;

data failed_course_combos_interm6;
set failed_course_combos_interm5;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data fail_course5;
set failed_course_combos_interm6;
format fail_course5 $10.;
fail_course5 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;


data fail_course_combos_dat;
merge fail_course1 fail_course2 fail_course3 fail_course4 fail_course5;
by Student_ID;
drop Course;
run;*4201;

PROC EXPORT DATA=fail_course_combos_dat
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\fail_course_combos.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;


/**********************end of courses failed in term ****************************/ 

		/*********** course combinations in term **********/

*generates market basket of courses taken in term;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE course_combos AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course

		FROM dbo.Daily_Term_Summary AS t1 
				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						AND t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			
		

ORDER BY Student_ID;
QUIT;*43202;



data course1;
set course_combos;
format course1 $10.;
course1 = Course;
By student_ID;
if First.Student_ID then output;
run; *30508;

data course_combos3;
set course_combos;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course2;
set course_combos3;
format course2 $10.;
course2 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;


data course_combos4;
set course_combos3;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course3;
set course_combos4;
format course3 $10.;
course3 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;

data course_combos5;
set course_combos4;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course4;
set course_combos5;
format course4 $10.;
course4 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;

data course_combos6;
set course_combos5;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course5;
set course_combos6;
format course5 $10.;
course5 = Course;
by Student_ID;
if First.Student_ID then output;
drop Course;
run; *30508;


data course_combos_dat;
merge course1 course2 course3 course4 course5;
by Student_ID;
drop Course;
run;*12694;

PROC EXPORT DATA=course_combos_dat
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\course_combos2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;


/**************  end of courses taken in term market basket***************/

		/*********** course combinations market basket through time **********/
*geenrates market basket of courses taken in two subsequent terms;


*uses previous run file ... course_combos_dat;

*selects students who attended fa12 and generates sids for sp15;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE courses_2 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t1.Term_Year,
				t1.Term_Name,
				t2.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year ='2015' and t1.Term_Name = 'Spring')
			and t2.Student_ID in (select Student_ID from course1)
		
		

ORDER BY Student_ID;
QUIT;*32702;


data next_course1;
set courses_2;
format next_course1 $10.;
next_course1 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course1;
run; *1350;

data courses2;
set courses_2;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_course2;
set courses2;
format next_course2 $10.;
next_course2 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course2;
run; *816;


data courses3;
set courses2;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_course3;
set courses3;
format next_course3 $10.;
next_course3 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course3;
run; *363;


data courses4;
set courses3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_course4;
set courses4;
format next_course4 $10.;
next_course4 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course4;
run; *139;


data courses5;
set courses4;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_course5;
set courses5;
format next_course5 $10.;
next_course5 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course5;
run; *25;

data courses_sub_squared_dat;
merge course1 course2 course3 course4 course5 next_course1 next_course2 next_course3 next_course4 next_course5;
by Student_ID;
drop course;
run;



PROC EXPORT DATA=courses_sub_squared_dat
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\subsequent_course_combos\courses_sub_squared_dat.xlsx"
    DBMS=EXCEL2010 REPLACE;
RUN;

/************ end of courses through time ************/



		/***************  specific combos in semester *****************/
*looks at tagret courses for study;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE mat_psy_enc_combos AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						AND t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course in ('MAT1033', 'ENC1101', 'PSY2012')
		
		

ORDER BY Student_ID;
QUIT;*43202;

data course1;
set mat_psy_enc_combos;
format course1 $10.;
course1 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course1;
run; *30508;

data mat_combos2;
set mat_combos;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course2;
set mat_combos2;
format course2 $10.;
course2 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID course2;
run; *30508;


data mat_combos3;
set mat_combos2;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course3;
set mat_combos3;
format course3 $10.;
course3 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID course3;
run; *30508;


data mat_combos_dat;
merge course1 course2 course3;
by Student_ID;
run;*12694;

data mat_combos_dat2;
set mat_combos_dat;
if course1 = '' then delete;
if course2 = '' then delete;
if course3 = '' then delete;
run;*299;


proc sql;
	create table three_dat as
	select student_ID, Course, Course_Grade_SCH
	from mat_combos as t1
	where t1.student_ID in (select student_ID from mat_combos_dat2)
;quit;

data fail_combo;
set three_dat;
if Course_Grade_SCH in ('D+', 'D', 'F', 'W') then output;
run;

proc sql;
	create table fails as
	select distinct student_ID, count(Course) as total_fails 
	from (
	select student_ID, Course, Course_Grade_SCH
	from fail_combo )
group by Student_ID;
quit; *176; *59% failed at least once;*23% failed once;

data fails2;
set fails;
if total_fails = 2 then output;
run;*42, 14% failed two;

data fails3;
set fails;
if total_fails = 3 then output;
run;*57, 19% failed three;


Proc SQL;                                                                                                                                                                    
      CREATE TABLE mat_enc_combos AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date
						AND t2.Student_ID = t5.Student_ID 
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course in ('MAT1033', 'ENC1101')
		
		

ORDER BY Student_ID;
QUIT;*43202;

data course1;
set mat_enc_combos;
format course1 $10.;
course1 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course1;
run; *30508;

data mat_enc_combos2;
set mat_enc_combos;
by Student_ID;
if First.Student_ID then delete;
run; *30508;

data course2;
set mat_enc_combos2;
format course2 $10.;
course2 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID course2;
run; *30508;


data mat_enc_combos_dat;
merge course1 course2;
by Student_ID;
run;

data mat_enc_combos_dat2;
set mat_enc_combos_dat;
if course1 = '' then delete;
if course2 = '' then delete;
run;*1041 students took mat1033 and ecn1101 together;


proc sql;
	create table three_dat as
	select t1.student_ID, t1.Course, t1.Course_Grade_SCH
	from mat_enc_combos as t1
	where t1.student_ID in (select student_ID from mat_enc_combos_dat2)
;quit;

data fail_combo;
set three_dat;
if Course_Grade_SCH in ('D+', 'D', 'F', 'W') then output;
run;
*1041;

proc sql;
	create table fails as
	select distinct student_ID, count(Course) as total_fails 
	from (
	select student_ID, Course, Course_Grade_SCH
	from fail_combo )
group by Student_ID;
quit; 

data fails1;
set fails;
if total_fails = 1 then output;
run;*271, 16.9% failed one;


data fails2;
set fails;
if total_fails = 2 then output;
run;*303, 29.1% failed two;

data fails;
merge fails1 fails2;
by student_ID;
run;

/****************  end of target course study ****************/


				/******************** courses failures through time ****************/

*generates market basket of failures in subsequent semesters;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_failed_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course_Grade_SCH in ('D+', 'D', 'F')
		
		

ORDER BY Student_ID;
QUIT;*43202;

data fa14_failed_sids;
set fa14_failed_courses;
by Student_ID;
if first.Student_ID then output;
run;


Proc SQL;                                                                                                                                                                    
      CREATE TABLE failed_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t1.Term_Year,
				t1.Term_Name,
				t2.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year ='2015' and t1.Term_Name = 'Spring')
			and t3.Course_Grade_SCH in ('D+', 'D', 'F')
			and t2.Student_ID in (select Student_ID from fa14_failed_sids)
		
		

ORDER BY Student_ID;
QUIT;*43202;


proc sql;
	create table dropped as
	select distinct t1.student_ID
	from fa14_failed_sids as t1
	where t1.Student_ID not in (select Student_ID from failed_courses)
;quit;*2725;


data dropped_flag;
set dropped;
format flag 2.;
flag =1;
run;

data dropped_flag2;
merge dropped_flag fa14_failed_courses;
by Student_ID;
run;


data fa14_failed_sids_cl;
set dropped_flag2;
if flag = 1 then delete;
drop flag;
run;


data course1;
set fa14_failed_sids_cl;
format course1 $10.;
course1 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course1;
run; *4202;

data fa14_failed_courses2;
set fa14_failed_sids_cl;
by Student_ID;
if First.Student_ID then delete;
run; 

data course2;
set fa14_failed_courses2;
format course2 $10.;
course2 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course2;
run; *2103;

data fa14_failed_courses3;
set fa14_failed_courses2;
by Student_ID;
if First.Student_ID then delete;
run; 

data course3;
set fa14_failed_courses3;
format course3 $10.;
course3 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course3;
run; *852;

data fa14_failed_courses4;
set fa14_failed_courses3;
by Student_ID;
if First.Student_ID then delete;
run;

data course4;
set fa14_failed_courses4;
format course4 $10.;
course4 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course4;
run; *332;


data fa14_failed_courses5;
set fa14_failed_courses4;
by Student_ID;
if First.Student_ID then delete;
run; 

data course5;
set fa14_failed_courses5;
format course5 $10.;
course5 = Course;
By student_ID;
if First.Student_ID then output;
keep student_ID course5;
run; *68;

*generates courses failed in following sp15;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE failed_courses_2 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t1.Term_Year,
				t1.Term_Name,
				t2.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year ='2015' and t1.Term_Name = 'Spring')
			and t3.Course_Grade_SCH in ('D+', 'D', 'F')
			and t2.Student_ID in (select Student_ID from fa14_failed_sids_cl)
		
		

ORDER BY Student_ID;
QUIT;*43202;


data next_course1;
set failed_courses_2;
format next_course1 $10.;
next_course1 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course1;
run; *1350;

data failed_courses2;
set failed_courses_2;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_course2;
set failed_courses2;
format next_course2 $10.;
next_course2 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course2;
run; *816;


data failed_courses3;
set failed_courses2;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_course3;
set failed_courses3;
format next_course3 $10.;
next_course3 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course3;
run; *363;


data failed_courses4;
set failed_courses3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_course4;
set failed_courses4;
format next_course4 $10.;
next_course4 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course4;
run; *139;


data failed_courses5;
set failed_courses4;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_course5;
set failed_courses5;
format next_course5 $10.;
next_course5 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_course5;
run; *25;

*generates courses in follwing summer and fall;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE failed_courses_3 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t1.Term_Year,
				t1.Term_Name,
				t2.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year ='2015' and t1.Term_Name in ( 'Fall', 'Summer'))
			and t3.Course_Grade_SCH in ('D+', 'D', 'F')
			and t2.Student_ID in (select Student_ID from fa14_failed_sids_cl)
		

ORDER BY Student_ID;
QUIT;*43202;

data next_next_course1;
set failed_courses_3;
format next_course1 $10.;
next_next_course1 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course1;
run; *1350;

data failed_courses2_3;
set failed_courses_3;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_next_course2;
set failed_courses2_3;
format next_next_course2 $10.;
next_next_course2 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course2;
run; *816;


data failed_courses3_3;
set failed_courses2_3;
by Student_ID;
if First.Student_ID then delete;
run; 


data next_next_course3;
set failed_courses3_3;
format next_course3 $10.;
next_next_course3 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course3;
run; *363;


data failed_courses4_3;
set failed_courses3_3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_next_course4;
set failed_courses4_3;
format next_next_course4 $10.;
next_next_course4 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course4;
run; *139;


data failed_courses5_3;
set failed_courses4_3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_next_course5;
set failed_courses5_3;
format next_next_course5 $10.;
next_next_course5 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course5;
run; *25;

data failed_courses6_3;
set failed_courses5_3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_next_course6;
set failed_courses6_3;
format next_next_course5 $10.;
next_next_course6 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course6;
run; *25;

data failed_courses7_3;
set failed_courses6_3;
by Student_ID;
if First.Student_ID then delete;
run; 

data next_next_course7;
set failed_courses7_3;
format next_next_course7 $10.;
next_next_course7 = Course;
by Student_ID;
if First.Student_ID then output;
keep student_ID next_next_course7;
run; *25;

data failed_sub_squared_dat;
merge course1 course2 course3 course4 course5 next_course1 next_course2 next_course3 next_course4 next_course5
next_next_course1 next_next_course2 next_next_course3 next_next_course4 next_next_course5 next_next_course6 next_next_course7;
by Student_ID;
run;


PROC EXPORT DATA=failed_sub_squared_dat
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\failed_sub_squared_dat.xlsx"
    DBMS=EXCEL2010 REPLACE;
RUN;

/************* end of failed courses through time ******************/

/*mat1033 and enc1101 study using FTIC students */

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_FTIC_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date
						and t2.Student_ID = t5.Student_ID 
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE t1.Most_Recent_For_Term_Flag = 'H' 
			AND t3.Institution_FICE_Code_SCH = '0001519'
			AND t2.Enrollment_Status_Code <> 'D'
			AND t3.Enrollment_Status_Code_SCH <> 'D'
			AND t1.Term_Year = '2014'
			AND t1.Term_Name = 'Fall'
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t5.FTIC_First_Time_in_College_Flag = 'F' 
			
ORDER BY Student_ID;
QUIT;*1896;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_math_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and (t3.Course in ('MAT1033') and Course_Attempted_SFCC = 1)
			and t5.FTIC_First_Time_In_College_Flag = 'F'
			

ORDER BY Student_ID;
QUIT;*887;


Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_enc_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and (t3.Course in ('ENC1101') and Course_Attempted_SFCC = 1)
			and t5.FTIC_First_Time_In_College_Flag = 'F'
			

ORDER BY Student_ID;
QUIT;*1081;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE sp15_math_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2015' )
			AND (t1.Term_Name = 'Spring')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and (t3.Course in ('MAT1033') and Course_Attempted_SFCC = 1)
			and t2.Student_ID in (select Student_ID from fa14_enc_sids)
			

ORDER BY Student_ID;
QUIT;*106;


Proc SQL;                                                                                                                                                                    
      CREATE TABLE sp15_enc_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2015' )
			AND (t1.Term_Name = 'Spring')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and (t3.Course in ('ENC1101') and Course_Attempted_SFCC = 1)
			and t2.Student_ID in (select Student_ID from fa14_math_sids)
			

ORDER BY Student_ID;
QUIT;*94;


/**** math first *****/

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_math_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course ,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t2.Student_ID in (Select Student_ID from fa14_math_sids)
			and t2.Student_ID in (select Student_ID from sp15_enc_sids)
			

ORDER BY Student_ID;
QUIT;*358;

data fa14_math_fails;
set fa14_math_courses;
if Course_Grade_SCH in ('D+', 'D', 'F');
run;


proc sql;
	create table fa14_math_fail_counts as
	select distinct Student_ID, Count(Course) as fail_count
	from fa14_math_fails
group by Student_ID
order by Student_ID;
quit;

proc sql;
	create table fa14_math_counts as
	select distinct Student_ID, Count(Course) as course_count
	from fa14_math_courses
group by Student_ID
order by Student_ID;
quit;


data fa14_math_outcome;
merge fa14_math_counts fa14_math_fail_counts;
By Student_ID;
run;

data fa14_math_outcome2;
set fa14_math_outcome;
if course_count < 3 then delete;
run;

data fa14_math_outcome3;
set fa14_math_outcome;
if course_count < 3 then output;
run;

/************ end of math first ****/


/**** english first *****/

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_enc_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course ,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t2.Student_ID in (Select Student_ID from fa14_enc_sids)
			and t2.Student_ID in (select Student_ID from sp15_math_sids)
			

ORDER BY Student_ID;
QUIT;*561;

data fa14_enc_fails;
set fa14_enc_courses;
if Course_Grade_SCH in ('D+', 'D', 'F');
run;


proc sql;
	create table fa14_enc_fail_counts as
	select distinct Student_ID, Count(Course) as fail_count
	from fa14_enc_fails
group by Student_ID
order by Student_ID;
quit;

proc sql;
	create table fa14_enc_counts as
	select distinct Student_ID, Count(Course) as course_count
	from fa14_enc_courses
group by Student_ID
order by Student_ID;
quit;


data fa14_enc_outcome;
merge fa14_enc_counts fa14_enc_fail_counts;
By Student_ID;
run;

data fa14_enc_outcome2;
set fa14_enc_outcome;
if course_count < 3 then delete;
run;

data fa14_enc_outcome3;
set fa14_enc_outcome;
if course_count < 3 then output;
run;

/************ end of english first ****/



/**** math and english together *****/

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_both_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course ,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t2.Student_ID in (Select Student_ID from fa14_enc_sids)
			and t2.Student_ID in (select Student_ID from fa14_math_sids)
			

ORDER BY Student_ID;
QUIT;*561;

data fa14_both_fails;
set fa14_both_courses;
if Course_Grade_SCH in ('D+', 'D', 'F');
run;



proc sql;
	create table fa14_both_fail_counts as
	select distinct Student_ID, Count(Course) as fail_count
	from fa14_both_fails
group by Student_ID
order by Student_ID;
quit;

proc sql;
	create table fa14_both_counts as
	select distinct Student_ID, Count(Course) as course_count
	from fa14_both_courses
group by Student_ID
order by Student_ID;
quit;


data fa14_both_outcome;
merge fa14_both_counts fa14_both_fail_counts;
By Student_ID;
run;

data fa14_both_outcome2;
set fa14_both_outcome;
if course_count < 3 then delete;
run;*873;

data fa14_both_outcome3;
set fa14_both_outcome;
if course_count < 3 then output;
run;*873;

/************ end of both ****/

PROC EXPORT DATA=fa14_both_outcome3
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_both_pt2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

PROC EXPORT DATA=fa14_both_outcome2
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_both2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

PROC EXPORT DATA=fa14_math_outcome2
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_math2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

PROC EXPORT DATA=fa14_math_outcome3
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_math_pt2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;
PROC EXPORT DATA=fa14_enc_outcome2
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_enc2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

PROC EXPORT DATA=fa14_enc_outcome3
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_enc_pt2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

/**** all FTIC *****/

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_FTIC_courses AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course ,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				inner join dbo.Daily_Student_Term_Summary as t5
					ON t1.Run_Date = t5.Run_Date 
						and t2.Student_ID = t5.Student_ID
						AND t1.Term_Year = t5.Term_Year 
						AND t1.Term_Number = t5.Term_Number 

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			and t5.FTIC_First_Time_In_College_Flag = 'F'
			

ORDER BY Student_ID;
QUIT;*561;

data fa14_FTIC_fails;
set fa14_FTIC_courses;
if Course_Grade_SCH in ('D+', 'D', 'F');
run;


proc sql;
	create table fa14_FTIC_fail_counts as
	select distinct Student_ID, Count(Course) as fail_count
	from fa14_FTIC_fails
group by Student_ID
order by Student_ID;
quit;

proc sql;
	create table fa14_FTIC_counts as
	select distinct Student_ID, Count(Course) as course_count
	from fa14_FTIC_courses
group by Student_ID
order by Student_ID;
quit;


data fa14_FTIC_outcome;
merge fa14_FTIC_counts fa14_FTIC_fail_counts;
By Student_ID;
run;

data fa14_FTIC_outcome2;
set fa14_FTIC_outcome;
if course_count < 3 then delete;
run;*873;

data fa14_FTIC_outcome3;
set fa14_FTIC_outcome;
if course_count < 3 then output;
run;*873;

PROC EXPORT DATA=fa14_FTIC_outcome2
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_FTIC2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;

PROC EXPORT DATA=fa14_FTIC_outcome3
    OUTFILE="S:\Reports\common\Data Request\Programs\William\data mining\math_enc_combo\fa14_FTIC_pt2.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;


/****************** enc1101 then hum2450 ******************/
*looks at which is better take enc1101 and hum2450 together or subsequent;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_enc1101_pass AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course in ('enc1101')
			and t3.Course_Grade_SCH in ('A+', 'A', 'B+', 'B', 'C+', 'C')
		
		

ORDER BY Student_ID;
QUIT;*1425;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE sp15_HUM2450 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2015' )
			AND (t1.Term_Name = 'Spring')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course in ('HUM2450')
			and t2.Student_ID in (select Student_ID from fa14_enc1101_pass)	

ORDER BY Student_ID;
QUIT;*25;*4 out of 23 wo W's 17.4%;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa14_HUM2450 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID,
				t3.Course,
				t3.Course_Grade_SCH

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section


		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t3.Course in ('HUM2450')
			and t2.Student_ID in (select Student_ID from fa14_enc1101_pass)	

ORDER BY Student_ID;
QUIT;*26 passed enc1101;*2 out of 26 wo W's 7.7%;


