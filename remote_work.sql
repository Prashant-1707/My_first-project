
--Project on :
--Impact_of_Remote_Work_on_Mental_Health 

-- creating table
create table remote_work(
Employee_ID varchar(15)	,
Age	int ,
Gender varchar(25),
Job_Role varchar(25),
Industry varchar(25),
Years_of_Experience	int ,
Work_Location varchar(15),	
Hours_Worked_Per_Week int ,
Number_of_Virtual_Meetings int , 
Work_Life_Balance_Rating int ,
Stress_Level varchar(20) , 
Mental_Health_Condition	varchar(20) , 
Access_to_Mental_Health_Resources varchar(4), 
Productivity_Change varchar(20)		,
Social_Isolation_Rating	int,
Satisfaction_with_Remote_Work varchar(20) , 
Company_Support_for_Remote_Work int, 	
Physical_Activity  varchar(15), 
Sleep_Quality varchar(15), 
Region varchar(25)
)

--importing the table 

--EDA Process

-- Business problems --
--These problems focus on data analysis, aggregations, and insights related to remote work.

-- Problem 1: Identify the Job Roles with the Most Virtual Meetings.

--Write an SQL query to find the top 5 job roles that have the highest average number of virtual meetings.

WITH AvgMeetingsPerJobRole AS (
    SELECT 
        Job_Role, 
        AVG(Number_of_Virtual_Meetings) AS avg_meetings
    FROM remote_work
    GROUP BY Job_Role
)
SELECT 
    Job_Role, 
    avg_meetings
FROM AvgMeetingsPerJobRole
ORDER BY avg_meetings DESC
LIMIT 5;

--Problem 2: Analyze the Impact of Stress Levels on Work-Life Balance

--Write an SQL query to calculate the average work-life balance rating for each stress level.

select avg(Work_Life_Balance_Rating) as avg_worklife_balance,
Mental_Health_Condition from remote_work
group by Mental_Health_Condition
order by avg_worklife_balance desc

--Problem 3: Correlation Between Hours Worked and Productivity Change

--Write an SQL query to find the average hours worked per week for each type of productivity change
--(Increase, Decrease, No Change).

select avg(hours_worked_per_week) as hours_worked_weekly,productivity_change
from remote_work
group by productivity_change
order by productivity_change desc

--Problem 4: Determine the Satisfaction Level by Work Location

--Write an SQL query to find the average satisfaction level with remote work for each work location
--(Hybrid, Remote, Onsite).

select work_location,
avg(case 
	when Satisfaction_with_Remote_Work = 'Satisfied' then 1
	when Satisfaction_with_Remote_Work = 'Unsatisfied' then 0 
	else null end ) as satisfaction_rate
	from remote_work
group by work_location


--Problem 5: Compare Mental Health Conditions Across Regions

--Write an SQL query to find the percentage of employees with mental health conditions in each region.


select region,
count(case when mental_health_condition != 'None' then 1 else null end)*100/count(*) as mental_healthrate
from remote_work
	group by region

--Problem 6: Calculate the Relationship Between Sleep Quality and Productivity.

--Write an SQL query to find the percentage of employees with good or poor sleep quality 
--for each type of productivity change.

select productivity_change,
count(case when sleep_quality='Good' then 1 else null end)*100 /count(*) as good_sleep_rate,
count(case when sleep_quality='Poor' then 1 else null end )*100 /count(*) bad_sleep_rate
from remote_work 
group by productivity_change


--Problem 7: Employee Satisfaction by Work Location and Department

--Find the average satisfaction rate for remote work across different work locations and departments.
--Also, identify the top 3 work locations with the highest satisfaction rates for each department.

with satisfactionRate as
	(select
	work_location,
	industry,
avg(case
	when satisfaction_with_remote_work = 'Satisfied' then 1
	when Satisfaction_with_Remote_Work = 'Unsatisfied' then  0 else null end) as avg_satis_rate
from remote_work
group by work_location,industry)


select work_location,industry,avg_satis_rate from satisfactionRate
order by industry,work_location,avg_satis_rate desc
limit 3;

--Problem 8: Employee Churn Risk Based on Remote Work Satisfaction

--Identify employees who are “Unsatisfied” with remote work for more than 50% of the recorded,
--months and have a high churn risk. Also, calculate the percentage of such employees
--in the entire dataset.

WITH UnsatisfiedMonths AS (
    SELECT 
        Employee_ID,
        COUNT(CASE 
            WHEN Satisfaction_with_Remote_Work = 'Unsatisfied' THEN 1 END) AS unsatisfied_count,
        COUNT(*) AS total_months
    FROM remote_work
    GROUP BY Employee_ID
),
ChurnRisk AS (
    SELECT 
        Employee_ID,
        unsatisfied_count,
        total_months,
        (unsatisfied_count::float / total_months) * 100 AS unsatisfied_percentage
    FROM UnsatisfiedMonths
    WHERE (unsatisfied_count::float / total_months) > 0.50
)
SELECT 
    Employee_ID, 
    unsatisfied_percentage, 
    (SELECT COUNT(*) FROM ChurnRisk) * 100.0 / (SELECT COUNT(*) FROM remote_work) AS churn_risk_percentage
FROM ChurnRisk;

--Problem 9: Problem 4: Tenure-Based Satisfaction Analysis

--Find out how employee satisfaction with remote work varies based on their tenure. 
--Divide employees into tenure groups (e.g., 0-1 year, 1-3 years, 3-5 years, etc.) and 
--calculate the average satisfaction rate for each group.

WITH TenureGroups AS 
	(select employee_id,years_of_experience,
case when years_of_experience < 1 then '0-1 years'
	 when years_of_experience between 1 and 3  then '1-3 years' 
	 when years_of_experience between 3 and 5  then '3-5 years' 
	 else '5+ years' 
		end as tenure_group,
avg(case when Satisfaction_with_Remote_Work = 'Satisfied' then 1 
	 WHEN Satisfaction_with_Remote_Work = 'Unsatisfied' THEN 0 
            ELSE NULL END) AS avg_satisfaction
	from remote_work
    GROUP BY Employee_ID, years_of_experience)

SELECT 
    tenure_group, 
    AVG(avg_satisfaction) AS avg_satisfaction_rate
FROM TenureGroups
GROUP BY tenure_group
ORDER BY tenure_group;


--Problem 10: Identifying Underperforming Work Locations

--Identify work locations where less than 40% of employees are satisfied with remote work.
--Calculate the percentage of employees in each location who are satisfied.

select * from remote_work 

WITH LocationSatisfaction AS 
	(select work_location, 
count(case when Satisfaction_with_Remote_Work = 'Satisfied' then 1 
	 WHEN Satisfaction_with_Remote_Work = 'Unsatisfied' THEN 0 
            ELSE NULL END) AS satis_count,
	count(*) as total_emp
from remote_work
group by work_location ),

under_perform_loc as 
	(select work_location,(satis_count:: float / total_emp)*100 as satisfaction_rate
from LocationSatisfaction)

SELECT 
    Work_Location, 
    satisfaction_rate
FROM under_perform_loc
WHERE satisfaction_rate < 40;
