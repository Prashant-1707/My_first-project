CREATE TABLE EmployeeRecords (
    EmployeeID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Department VARCHAR(50),
    Salary DECIMAL(10, 2),
    HireDate DATE,
    ManagerID INT,
    PerformanceScore INT,
    ProjectCount INT
);

INSERT INTO EmployeeRecords (EmployeeID, FirstName, LastName, Department, Salary, HireDate, ManagerID, PerformanceScore, ProjectCount)
VALUES
(1, 'John', 'Doe', 'Sales', 75000.00, '2018-01-15', 3, 85, 5),
(2, 'Jane', 'Smith', 'Engineering', 90000.00, '2017-03-22', 4, 90, 7),
(3, 'Emily', 'Johnson', 'Sales', 60000.00, '2020-05-13', NULL, 70, 3),
(4, 'Michael', 'Brown', 'Engineering', 95000.00, '2016-07-30', NULL, 88, 9),
(5, 'Sarah', 'Davis', 'Marketing', 82000.00, '2019-08-12', 6, 75, 4),
(6, 'David', 'Wilson', 'Marketing', 78000.00, '2018-11-01', NULL, 80, 6),
(7, 'Laura', 'Taylor', 'HR', 65000.00, '2019-12-10', 8, 65, 2),
(8, 'Robert', 'Anderson', 'HR', 70000.00, '2015-09-18', NULL, 78, 3),
(9, 'Linda', 'Thomas', 'Engineering', 98000.00, '2016-03-14', 4, 95, 10),
(10, 'James', 'Lee', 'Sales', 72000.00, '2021-01-25', 3, 82, 4);



--Find the top 3 highest-paid employees in each department

With cte as (select firstname,department,salary,rank() over(partition by department order by salary desc) as rn
from EmployeeRecords)

select firstname,department,salary from cte
where rn<=3

--Calculate the year-over-year salary growth for each employee who has been in the company 
--for more than 3 years.

SELECT 
    EmployeeID, FirstName, LastName, Department, Salary, HireDate,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(NOW(), HireDate)) > 3 
        THEN Salary - LAG(Salary) OVER (ORDER BY HireDate)
        ELSE NULL 
    END AS YearOverYearSalaryGrowth
FROM 
    EmployeeRecords;

--Determine the average performance score for employees managed by each manager.

select managerid,avg(performancescore) from EmployeeRecords
where managerid is not null 
group by managerid

--Identify the department with the highest average project count per employee, 
--but only consider departments with more than 2 employees.


with cte as (select department,count(*) as employeecount,avg(projectcount) as avgprojectcount from EmployeeRecords
group by department 
having count(*)>2)

select department,avgprojectcount from cte 
order by avgprojectcount desc
limit 1

--List all employees who have a performance score greater than the average performance score
--of their department.



select firstname,lastname, department ,performancescore from EmployeeRecords
where performancescore>(select avg(performancescore) as avgperformancescore from EmployeeRecords)

--Generate a report showing the total salary and average performance score
--for employees hired in each year. 



select firstname,lastname,extract(year from hiredate) as hireyear,
avg(performancescore) as avgscore,sum(salary)as TotalSalary from EmployeeRecords
group by hiredate,firstname,lastname

--Find the employees who have never been assigned a project, 
-- and list their department and manager’s name.

select e.EmployeeID, e.FirstName, e.LastName, e.Department,
m.FirstName AS ManagerFirstName, m.LastName AS ManagerLastName from EmployeeRecords as e
left join EmployeeRecords as m
ON e.ManagerID = m.EmployeeID
where e.projectcount=0


--Calculate the median salary for each department.

select department ,percentile_cont(0.5) within group (order by salary) as medianSalary 
from EmployeeRecords
group by department

--Create a query to determine which employees are eligible for a bonus,where eligibility is 
--defined as having a performance score above 85 and working on at least 5 projects.

select firstname,lastname
from EmployeeRecords
where performancescore>85 and projectcount>=5


--Write a query to find the department with the highest total salary expense and 
--list all employees in that department.

with DepartmentSalary as (select department,sum(salary) as TotalSalary,
max(salary) over() as MaxTotalSalary  from EmployeeRecords
group by department,salary)
	
select e.employeeid,e.firstname,e.lastname,e.department,e.salary from EmployeeRecords as e
join  DepartmentSalary as d 
on e.department = d.department
where d.MaxTotalSalary=d.TotalSalary


--Write a query to list all employees who earn more than the average salary of their 
--respective departments.


with cte as (select department,avg(salary) as avgsalary from EmployeeRecords
group by department)

select e.FirstName, e.LastName, e.Department, e.Salary from EmployeeRecords as e 
join cte as c1
on e.department = c1.department
where e.salary>c1.avgsalary

--Write a query to rank employees by salary within their respective departments.


select FirstName,LastName,salary,department,
rank() over(partition by department order by salary desc) as rn
from EmployeeRecords


--Write a query to find out which department has the highest total salary


select department, sum(salary) from EmployeeRecords
group by department 
order by sum(salary) desc
limit 1

--Write a query to find employees who had the largest salary increase year-over-year.

with cte as (
select EmployeeID, FirstName, LastName, Salary,lag(salary) over(order by hiredate) as previousyearsalary
from EmployeeRecords)

select EmployeeID, FirstName, LastName,(salary-previousyearsalary) as salaryincrease from cte
where previousyearsalary is not null 
order by salaryincrease desc
limit 1

--Write a query to calculate the total compensation (salary) for each manager, 
--including their own salary and the salaries of all their direct subordinates.
select * from EmployeeRecords

with managersalary as (
	select managerid,sum(salary) as subordinatesalary from EmployeeRecords
where managerid is not null
group by managerid)

select e.firstname,e.lastname,ma.managerid,e.salary,ma.firstname,ma.lastname,ma.managerstotal 
from EmployeeRecords as e
join managersalary as ma
on e.employeeid=ma.managerid 
where ma.managerid is not null

WITH ManagerCompensation AS (
    SELECT 
        ManagerID, SUM(Salary) AS SubordinateSalary
    FROM 
        EmployeeRecords
    WHERE 
        ManagerID IS NOT NULL
    GROUP BY 
        ManagerID
)
SELECT 
    e.EmployeeID, e.FirstName, e.LastName, e.Salary + COALESCE(m.SubordinateSalary, 0) AS TotalCompensation
FROM 
    EmployeeRecords e
LEFT JOIN 
    ManagerCompensation m ON e.EmployeeID = m.ManagerID
WHERE 
    e.ManagerID IS NULL;  -- Only select managers
















