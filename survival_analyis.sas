OPTIONS S=72  MISSING= ' ' NOSOURCE NOCENTER PS=9999;
DM "log; clear; ";
dm 'odsresults; clear';
libname dbo ODBC DSN=SFCC_DW UID=SFCC_DW_IR PWD=R3ad_0n!y  SCHEMA=DBO;


Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa12_degree_sids AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID, T1.Term_Year, t1.Term_Name

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
			AND (t1.Term_Year = '2012' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t5.FTIC_First_Time_In_College_Flag = 'F'
		

ORDER BY Student_ID;
QUIT;*1793;



Proc SQL;                                                                                                                                                                    
      CREATE TABLE cy13_17 AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t2.Student_ID, Max(t1.Term_Year) as year_last_attended, max(t1.Term_Number) as last_term, 
				t5.Graduation_Term_Year, t5.Graduation_Term_Name

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

				left outer join dbo.Student_Graduation_History as t5
					on t2.Student_ID = t5.Student_ID  

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			AND (t1.Term_Year in ('2013', '2014', '2015', '2016', '2017' ))
			and t2.student_ID in (select student_ID from fa12_degree_sids)
		
Group by t2.Student_ID
ORDER BY Student_ID, year_last_attended, last_term;
QUIT;*1565;

/*

data cy13_17_2;
set cy13_17;
format graduated $4.;
yrs= year_last_attended - 2012;
grd_yrs = Graduation_term_Year - 2012;
if Graduation_Term_Year in ('2013', '2014', '2015', '2016', '2017') then graduated = 'yes';
else graduated = 'no';
run;

*/

data cy13_17_2;
set cy13_17;
if Graduation_Term_Year in ('2013', '2014', '2015', '2016', '2017') then delete;
keep student_ID year_last_attended;
run;


data cy13_17_3;
set cy13_17_2;
yrs= year_last_attended - 2012;
keep student_ID yrs;
run; *970;

Proc SQL;                                                                                                                                                                    
      CREATE TABLE fa12_demo AS    
	
     	SELECT DISTINCT 
				t2.Student_ID, 
				t4.Student_Race_Code, 
				t4.State_Name, 
				t7.Student_Age_At_Beginning_Of_Term, 
				t7.FTIC_First_Time_In_College_Flag, 
				t7.Student_Credit_Hours_For_Term,
				t9.GPA_All_College,
				t4.County_Code,
				t4.Country_Name

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				 INNER JOIN
                      dbo.Daily_Course_Snapshot AS t3 
					ON t2.Run_Date = t3.Run_Date 
						AND t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Session_Code = t3.Session_Code 
						AND t2.Course = t3.Course 
						AND t2.Course_Section = t3.Course_Section

				left Join dbo.Daily_Student_Term_Summary as t7
					on t2.Student_ID = t7.Student_ID
						and t1.Run_Date = t7.Run_Date
						and t1.Term_Year = t7.Term_Year
						and t1.Term_Name = t7.Term_Name

				left Join dbo.Student_term_GPA as t9
					on t2.Student_ID = t9.Student_ID
						and t1.Term_Year = t9.Term_year
						and t1.Term_Name = t9.Term_Name

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t2.Enrollment_Status_Code <> 'D')  
			AND (t1.Term_Year = '2012' )
			AND (t1.Term_Name = 'Fall')
			AND t4.Degree IN ('AA', 'AS', 'AAS')
			and t7.FTIC_First_Time_In_College_Flag = 'F'
			and t2.student_ID in (select student_ID from cy13_17_3)
		
order by Student_ID;
QUIT; *970;


data fa12_data;
merge cy13_17_3 fa12_demo ;
by Student_ID;
run;

PROC EXPORT DATA=fa12_data
    OUTFILE="S:\Reports\common\Data Request\Programs\William\survival_analysis\fa12_data.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;