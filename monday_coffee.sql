-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

create table city (
	city_id	int primary key,
	city_name varchar(10),
	population bigint,
	estimated_rent	float,
	city_rank int 	
)

create table customers (
	customer_id	int primary key,
	customer_name varchar(18),
	city_id int ,    -- fk 
	constraint fk_city foreign key (city_id) references city(city_id)
)

create table products (
	product_id	int primary key,
	product_name varchar(35),	
	price float 
	
)

create table sales (
	sale_id	int primary key, 
	sale_date date ,
	product_id	int , -- fk
	customer_id	int ,-- fk 
	total int ,
	rating float ,
	constraint fk_product foreign key (product_id) references products(product_id),
	constraint fk_customer foreign key (customer_id) references customers(customer_id)

)

-- End of schemas  

-- Monday Coffee -- Data Analysis 


SELECT * FROM sales;
SELECT * FROM products;
SELECT * FROM city;
SELECT * FROM customers;



SELECT * FROM sales;


-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name, 
round((population*0.25)/1000000,2) as popu,city_rank
from city 
order by 2 desc

-- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


select ci.city_name, 
	sum(s.total) as total_revenue 
	from sales as s 
	join customers as c 
on s.customer_id = c.customer_id 
	join city as ci
	on ci.city_id = c.city_id
where extract(year from s.sale_date) = 2023
	and extract(quarter from s.sale_date)=4
group by 1
order by 2 desc

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?


select p.product_name,count(s.sale_id) as total_orders from products as p 
left join sales as s 
on p.product_id=s.product_id
group by 1
order by 2 desc

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?


	select ci.city_name,sum(s.total) as total_rev,
	count(distinct c.customer_id) as total_cx ,
	round(sum(s.total)::numeric/count(c.customer_id)::numeric,2) as avg_sale_pr_cx
	from sales as s
	join customers as c 
	on s.customer_id = c.customer_id
	join city as ci 
	on ci.city_id = c.city_id
	group by 1

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
	
customers_table
AS (
	select ci.city_name,
		count(DISTINCT c.customer_id) as unique_cx
from customers as c
join city as ci
On ci.city_id = c.city_id
group by 1 )


SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?


with cte as (
	select ci.city_name,p.product_name,count(s.sale_id) as total_orders,
	dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc ) as ranking
from sales as s 
join products as p 
on s.product_id= p.product_id
join customers as cx
on cx.customer_id = s.customer_id 
join city as ci
on ci.city_id = cx.city_id
group by 1,2
order by 1,3 desc ) 


select city_name,product_name,total_orders,ranking from cte 
where ranking <=3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?


select count(distinct c.customer_id),ci.city_name 
from city as ci
left join customers as c
on c.city_id=ci.city_id
join sales as s 
on s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 2

-- Q.8
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthly_sales as 
(select ci.city_name,extract(month from s.sale_date) as month,
extract(year from s.sale_date) as year_,
sum(s.total) as total_sales
from sales as s 
join customers as c 
on s.customer_id=c.customer_id
join city as ci 
on ci.city_id = c.city_id
group by 1,2,3
order by 1,3,2 )
,

previous_monthsale as 
(
select city_name,month,year_,total_sales,
lag(total_sales) over (partition by city_name order by year_,month) as previous_month_sale
from monthly_sales 
)

select city_name,month,year_,total_sales,previous_month_sale,
round((total_sales::numeric-previous_month_sale::numeric)/previous_month_sale::numeric*100,2) as growth_ratio
from previous_monthsale
where 
previous_month_sale is not null 


-- Q.9
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
