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