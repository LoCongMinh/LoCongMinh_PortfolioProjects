---Analyze Sale Performance Overtime by Year

SELECT
	YEAR(order_date) AS order_year,
	SUM(sales_amount) AS Total_sales,
	COUNT(DISTINCT(customer_key)) AS Total_customer,
	SUM(quantity) AS Total_quantity
FROM		gold.fact_sales
WHERE		order_date IS NOT NULL
GROUP BY	YEAR(order_date)
ORDER BY	YEAR(order_date) DESC

---Analyze Sale Performance Overtime by Month

SELECT
	DATETRUNC(month,order_date) AS order_month,
	SUM(sales_amount) AS Total_sales,
	COUNT(DISTINCT(customer_key)) AS Total_customer,
	SUM(quantity) AS Total_quantity
FROM		gold.fact_sales
WHERE		order_date IS NOT NULL
GROUP BY	DATETRUNC(month,order_date)
ORDER BY	DATETRUNC(month,order_date) DESC

---Calculate the total sale per month

SELECT
	DATETRUNC(MONTH,order_date) AS order_month,
	SUM(sales_amount) AS total_sales
FROM		gold.fact_sales
WHERE		order_date IS NOT NULL
GROUP BY	DATETRUNC(MONTH,order_date)
ORDER BY	DATETRUNC(MONTH,order_date) DESC


---Calculate the running total sale, moving average sale over time (Cummulative Analysis)
---Using window function will keep the original total sales for each month instead of using CTE

SELECT
	order_month,
	total_sales,
	SUM(total_sales) OVER(ORDER BY order_month) AS cumulative_sales,
	AVG(average_sale) OVER(ORDER BY order_month) AS moving_average_sales
FROM (
SELECT
	DATETRUNC(MONTH,order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	AVG(sales_amount) AS average_sale
FROM		gold.fact_sales
WHERE		order_date IS NOT NULL
GROUP BY	DATETRUNC(MONTH, order_date)
)t

--- CTE

WITH monthly_sales AS (
    SELECT
        DATETRUNC(MONTH, order_date) AS order_month,
        SUM(sales_amount) AS total_sales,
		AVG(sales_amount) AS average_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_month) AS cumulative_sales,
	AVG(average_sales) OVER (ORDER BY order_month) AS moving_average_sales
FROM monthly_sales
ORDER BY order_month;

--- Calculate the running total sale, moving average sale over divided by 1 year group (Cummulative Analysis)
--- PARTITION BY 1 year

SELECT
	order_year,
	order_month,
	total_sales,
	SUM(total_sales) OVER(PARTITION BY order_year ORDER BY order_month) AS cumulative_sales,
	AVG(average_sales) OVER (PARTITION BY order_year ORDER BY order_month) AS moving_average_sales
FROM (
SELECT
	DATETRUNC(MONTH,order_date) AS order_month,
	YEAR(order_date) AS order_year,
	SUM(sales_amount) AS total_sales,
	AVG(sales_amount) AS average_sales
FROM		gold.fact_sales
WHERE		order_date IS NOT NULL
GROUP BY	DATETRUNC(MONTH, order_date), YEAR(order_date)
)t

/* Performance Analysis --- Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales
using CTE and LAG() */

--- Year over Year analysis for longterm change

WITH yearly_product_sale AS
(
SELECT	
		d.product_key,
		YEAR(order_date) AS order_year,
		product_name,
		SUM(sales_amount) AS total_sale
FROM		gold.fact_sales f
LEFT JOIN	gold.dim_products d
ON			f.product_key = d.product_key
WHERE		order_date IS NOT NULL
GROUP BY	d.product_key, product_name, YEAR(order_date)
)

SELECT	
		product_key,
		order_year,
		product_name,
		total_sale,
		AVG(total_sale) OVER (PARTITION BY product_name) AS average_sales,
		total_sale - AVG(total_sale) OVER (PARTITION BY product_name) AS diff_avg,
			CASE	WHEN total_sale - AVG(total_sale) OVER (PARTITION BY product_name) > 0 THEN 'above_avg'
					WHEN total_sale - AVG(total_sale) OVER (PARTITION BY product_name) < 0 THEN 'below_avg'
					ELSE '=avg'
			END avg_change,
		total_sale - LAG(total_sale) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_year_change,
			CASE	WHEN total_sale - LAG(total_sale) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
					WHEN total_sale - LAG(total_sale) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
					ELSE 'No Change'
			END previous_year_change
FROM	yearly_product_sale
ORDER BY	product_name, order_year

--- Which categories contribute the most to overall sales?

WITH category_sale AS(
SELECT
		p.category,
		SUM(sales_amount) AS total_sale
FROM	gold.dim_products p
LEFT JOIN	gold.fact_sales f
ON			p.product_key = f.product_key
WHERE	order_date IS NOT NULL
GROUP BY	p.category
)
SELECT
		category,
		total_sale,
		SUM(total_sale) OVER () AS overall_sale,
		CONCAT(ROUND((CAST(total_sale AS FLOAT) / SUM(total_sale) OVER ()) *100, 2), '%') AS percentage
FROM	category_sale
ORDER BY total_sale DESC


/*Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segments AS (
SELECT
	product_key,
	product_name,
	cost,
		CASE WHEN cost < 100 THEN 'Below 100'
			 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			 ELSE 'Above 1000'
		END cost_range
FROM	gold.dim_products
)
SELECT 
		cost_range,
		COUNT(product_key) AS total_products
FROM		product_segments
GROUP BY	cost_range
ORDER BY	total_products DESC


/*Group customers into three segments based on their spending behavior:
- VIP: customers with at least 12 months of history and spending more than 5,000
- Regular: Customers with at least 12 months of history but spending 5,000 or less.
- New: customer with a lifespan less than 12 months.
And find the total number of each group */

WITH customer_spending AS(
SELECT 
		c.customer_key,
		c.customer_id,
		MIN(s.order_date) AS Farest_order_date,
		MAX(s.order_date) AS Nearest_order_date,	
		SUM(s.sales_amount) AS total_spending,
		DATEDIFF(MONTH,MIN(s.order_date),MAX(s.order_date)) AS lifespan
FROM		gold.dim_customers c
LEFT JOIN	gold.fact_sales s
ON			c.customer_key = s.customer_key
GROUP BY c.customer_key, c.customer_id
)

SELECT 
		customer_segment,
		COUNT(customer_key) AS total_customer
FROM	(
	SELECT
			customer_key,
			customer_id,
			total_spending,
			lifespan,
			CASE	WHEN Lifespan >= 12 AND  total_spending > 5000 THEN 'VIP'
					WHEN Lifespan >= 12 AND  total_spending <= 5000 THEN 'Regular'
					ELSE 'NEW'
			END AS customer_segment
	FROM customer_spending
)t
GROUP BY customer_segment
ORDER BY total_customer


/* ====================================================
Customer report
=======================================================
Purpose: 
	- This report consolidates key customer metrics and behaviors

Highlight:
	1. Gathers essential fields such as names, ages and transaction details.
	2. Segment customers into catagories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- Total orders
		- Total sales
		- Total quantity purchased
		- Total products
		- Lifespan (in months)
	4. Calculate valuable KPIs: 
		- Recency (month since last order)
		- Average order value
		- Average monthly spend

======================================================= */


CREATE VIEW gold.report_customers AS

/*-----------------------------------------------------
1) Base Queries: Retrieve core columns from tables
----------------------------------------------------*/
WITH base_query AS(
SELECT 
			c.customer_key,
			c.customer_id,
			s.order_date,
			s.sales_amount,
			s.order_number,
			s.quantity,
			s.product_key,
			CONCAT(first_name,' ',last_name) AS customer_name,
			DATEDIFF(YEAR,birthdate,GETDATE()) AS Age
FROM		gold.dim_customers c
LEFT JOIN	gold.fact_sales s
ON			c.customer_key = s.customer_key
WHERE		order_date IS NOT NULL
)
,customer_aggregation AS (
SELECT
			customer_key,
			customer_id,
			customer_name,
			Age,
			COUNT(DISTINCT(order_number)) AS Total_order,
			SUM(sales_amount) AS Total_sale,
			SUM(quantity) AS Total_quantity,
			COUNT(DISTINCT(product_key)) AS Total_product,
			MAX(order_date) AS last_order_date, 
			DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
FROM		base_query
GROUP BY	customer_key, customer_id, customer_name, Age
)
SELECT 
			customer_key, 
			customer_id, 
			customer_name, 
			Age,

			CASE	
				WHEN age < 20 THEN 'Under 20'
				WHEN age BETWEEN 20 AND 29 THEN '20-29'
				WHEN age BETWEEN 30 AND 39 THEN '30-39'
				WHEN age BETWEEN 40 AND 49 THEN '40-49'
				ELSE 'Above 50'
			END	age_categories,

			CASE	
				WHEN lifespan >= 12 AND Total_sale > 5000 THEN 'VIP'
				WHEN lifespan >= 12 AND Total_sale < 5000 THEN 'Regular'
				ELSE 'New'
			END customer_tier,

			Total_order,
			Total_sale,
			Total_quantity,
			Total_product,
			last_order_date,
			lifespan,
			DATEDIFF(MONTH,last_order_date,GETDATE()) AS recency,

			--- Compute average order value (AVO)
			CASE	WHEN total_order = 0 THEN 0
					ELSE Total_sale / Total_order
			END AS average_order_value,

			--- Compute average monthly spend
			CASE	WHEN lifespan = 0 THEN Total_sale
					ELSE Total_sale / lifespan
			END	AS	average_monthly_spend
FROM		customer_aggregation

SELECT * FROM gold.report_customers

