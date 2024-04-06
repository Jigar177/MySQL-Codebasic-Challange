USE gdb023;

-- Codebasics SQL Challenge

-- Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select * from dim_customer;

select 
	distinct market
from dim_customer 
where customer = "Atliq Exclusive" and region = 'APAC';


-- Q2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

select * from fact_sales_monthly; 

with cte1 as 
(
select 
     count(distinct(case when fiscal_year=2020 then product_code end)) as unique_products_2020,
     count(distinct(case when fiscal_year=2021 then product_code end)) as unique_products_2021 
from fact_sales_monthly
)
select 
       unique_products_2020, 
       unique_products_2021, 
       concat(round(((unique_products_2021 - unique_products_2020) /unique_products_2020)*100,2),'%') as percentage_chg 
from cte1;

-- Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
--  The final output contains 2 fields,
-- segment
-- product_count

select * from dim_product;

select 
	COUNT(distinct product_code ) as product_count ,
    segment 
from dim_product
group by segment 
order by product_count desc;


-- Q4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,

-- segment
-- product_count_2020
-- product_count_2021
-- difference

select * from fact_sales_monthly;
select * from dim_product;

with cte1 as 
(
select 
       pr.segment,
       count(distinct(case when fs.fiscal_year=2020 then pr.product_code end)) as product_count_2020,
       count(distinct(case when fs.fiscal_year=2021 then pr.product_code end)) as product_count_2021
from dim_product pr
join fact_sales_monthly fs on pr.product_code=fs.product_code
group by pr.segment
)
select 
       segment, 
       product_count_2020, 
       product_count_2021, 
       (product_count_2021-product_count_2020) as difference
from cte1
order by difference desc;


-- Q5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost


select 
       fm.product_code, 
       pr.product, 
       round(fm.manufacturing_cost,2) as manufacturing_cost 
from fact_manufacturing_cost fm 
join dim_product as pr 
on fm.product_code = pr.product_code where
manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost) or
manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost);



-- Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for
--  the fiscal year 2021 and in the Indian market. The final output contains these fields,

-- customer_code
-- customer
-- average_discount_percentage

select * from fact_pre_invoice_deductions limit 5;
select * from dim_customer limit 5;

select 
       pi.customer_code, 
       c.customer, 
       concat(round(avg(pi.pre_invoice_discount_pct),4),'%') as average_discount_percentage 
from fact_pre_invoice_deductions pi
join dim_customer c
on pi.customer_code = c.customer_code
where pi.fiscal_year=2021 and c.market='India'
group by pi.customer_code, c.customer
order by average_discount_percentage desc limit 5;


-- Q7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions.
-- The final report contains these columns,

-- Month
-- Year
-- Gross sales Amount

select * from fact_sales_monthly;
select * from dim_customer;


select 
       monthname(fs.date) as Month, 
       year(fs.date) as Year, 
       concat(round(sum(fs.sold_quantity*fg.gross_price)/1000000,2),' Million') as 'Gross sales Amount' 
from fact_sales_monthly fs 
join fact_gross_price fg on fs.product_code=fg.product_code
join dim_customer d on fs.customer_code=d.customer_code
where customer = 'Atliq Exclusive'
group by Month, Year;

-- Q8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity:

-- Quarter
-- total_sold_quantity


select * from fact_sales_monthly;

select
	case
	when  date between '2019-09-01' and '2019-11-01' then 'Q1'
	when  date between '2019-12-01' and '2020-02-01' then 'Q2'
	when  date between '2020-03-01' and '2020-05-01' then 'Q3'
	when  date between '2020-06-01' and '2020-08-01' then "Q4" end as Quarter,
	sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc;


-- Q9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields,

-- channel
-- gross_sales_mln
-- percentage

with cte1 as 
 (
    select 
            c.channel, 
            sum(p.gross_price*f.sold_quantity)/1000000 as gross_sales_mln  
    from fact_sales_monthly f 
		inner join fact_gross_price p on f.product_code=p.product_code
		inner join dim_customer c on f.customer_code=c.customer_code 
    where f.fiscal_year=2021
    group by channel
 ) , 
cte2 as 
 (
select
	sum(p.gross_price*f.sold_quantity)/1000000 as total  
from fact_sales_monthly f 
    inner join fact_gross_price p on f.product_code=p.product_code
	inner join dim_customer c on f.customer_code=c.customer_code 
where f.fiscal_year=2021
 )
select 
       cte1.channel, 
       round(cte1.gross_sales_mln,2) as gross_sales_mln, 
       concat(round((cte1.gross_sales_mln/cte2.total)*100,2),'%') as percentage
from cte1
cross join cte2
order by percentage desc;



-- Q10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields,

-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

select * from fact_sales_monthly;
select * from dim_product;

with cte1 as (
   select 
           p.division, 
           p.product_code, 
           p.product, 
           sum(f.sold_quantity) as total_sold_quantity, 
           dense_rank() over(partition by p.division order by sum(f.sold_quantity) desc) as rank_order 
   from dim_product p
   inner join fact_sales_monthly f on p.product_code=f.product_code 
   where f.fiscal_year=2021
   group by p.division, p.product_code,p.product
)
select * from cte1 where rank_order<4;