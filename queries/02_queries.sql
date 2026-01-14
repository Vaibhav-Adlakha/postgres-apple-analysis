-- Creating Index to help speed up Select queries

CREATE INDEX sales_product_id ON sales(product_id);

CREATE INDEX sales_store_id ON sales(store_id);

CREATE INDEX sales_sale_date ON sales(sale_date);

/* Q1: Find the number of stores in each country */

SELECT
	country,
	COUNT (*) AS number_of_stores
FROM stores
GROUP BY country
ORDER BY number_of_stores DESC;

/* Q2: Calculate the total number of units sold by each store */

SELECT
	sa.store_id,
	st.store_name,
	SUM(sa.quantity) AS units_sold
FROM sales sa
JOIN stores st
ON sa.store_id = st.store_id
GROUP BY sa.store_id, st.store_name;

/* Q3: Identify how many sales occurred in November 2024 */

SELECT COUNT(sale_id) AS number_of_sales
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2024 
AND EXTRACT(Month FROM sale_date) = 11;

/*Q4: Determine how many stores have never had any warranty claim filed */

SELECT COUNT(*) AS no_claim_store_count
FROM stores st
WHERE store_id NOT IN(
						SELECT DISTINCT store_id
						FROM sales sa
						RIGHT JOIN warranty w
						ON sa.sale_id = w.sale_id);


/* Q5: Calculate the percentage of warranty claims marked as REJECTED */ 

SELECT 
	ROUND(COUNT(CASE WHEN repair_status = 'Rejected' THEN 1 END)::Numeric 
	/ COUNT(*) * 100,2) AS void_pct
FROM warranty;

/*Q6: Identify which store had the highest total units sold in 2024 */

SELECT
	st.store_id,
	st.store_name,
	SUM(sa.quantity) AS units_sold 
FROM sales sa
JOIN stores st
ON sa.store_id = st.store_id
WHERE sale_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY st.store_id, st.store_name
ORDER BY units_sold DESC
LIMIT 1;

/* Q7: Count the number of unique products sold in 2024 */

SELECT 
	COUNT(DISTINCT(product_id)) AS unique_products
FROM sales
WHERE EXTRACT(YEAR FROM sale_date) = 2024;

/* Q8: Find the average price of product in each category */

SELECT 
	p.category_id,
	c.category_name,
	ROUND(AVG(price),2) AS average_price
FROM products p
JOIN category c
ON p.category_id = c.category_id
GROUP BY p.category_id, c.category_name
ORDER BY average_price DESC;

/*Q9: How many warranty claims were filed in 2022 */

SELECT 
	COUNT(*) 
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2022;

/* Q10: For each store, identify the best selling day based on highest quantity sold */

WITH uns AS(
		SELECT 
			sa.store_id, 
			st.store_name, 
			sa.sale_date,
			SUM(quantity) AS units_sold
		FROM sales sa
		JOIN stores st
		ON sa.store_id = st.store_id
		GROUP BY sa.store_id, st.store_name, sa.sale_date
	),
ranked_stores AS(
	SELECT
		store_id,
		store_name,
		sale_date,
		units_sold,
		DENSE_RANK() OVER(PARTITION BY store_id ORDER BY units_sold DESC) AS sale_rank
	FROM uns)
SELECT 
	store_id,
	store_name,
	sale_date,
	units_sold
FROM ranked_stores
WHERE sale_rank = 1
ORDER BY units_sold DESC;

/* Q11: Identify the least selling product in each category for each year based on total units sold */

WITH uns AS(
		SELECT 
			c.category_id,
			c.category_name,
			s.product_id,
			EXTRACT(YEAR FROM sale_date) AS sale_year,
			SUM(quantity) AS units_sold
		FROM sales s
		JOIN products p
		ON s.product_id = p.product_id
		JOIN category c
		ON p.category_id = c.category_id
		GROUP BY c.category_id, c.category_name, s.product_id, EXTRACT(YEAR FROM sale_date)
	),
rns AS(
	SELECT 
		category_id,
		category_name,
		product_id,
		units_sold,
		sale_year,
		DENSE_RANK() OVER(PARTITION BY category_id, sale_year ORDER BY units_sold) AS sell_rank
	FROM uns)
SELECT 
	category_id,
	category_name,
	product_id,
	sale_year,
	units_sold
FROM rns
WHERE sell_rank = 1;

/* Q12: Calculate how many warranty claims were filed within 180 days of a product sale */ 

SELECT 
	COUNT(*) AS warranty_claims
FROM sales s
JOIN warranty w
ON s.sale_id = w.sale_id
WHERE w.claim_date BETWEEN s.sale_date AND s.sale_date + INTERVAL '180 Days';

/* Q13: Determine how many warranty claims were filed within 2 years of a product's launch? */

SELECT
	COUNT(*)
FROM products p
JOIN sales s
ON p.product_id = s.product_id
JOIN warranty w
ON w.sale_id = s.sale_id
WHERE w.claim_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '2 Years';

/* Q13.2 Determine how many warranty claims were filed for the products that were launched in the 
last 2 years */

SELECT
	COUNT(*)
FROM products p
JOIN sales s
ON p.product_id = s.product_id
JOIN warranty w
ON w.sale_id = s.sale_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 Years';

/* Q14: List the months in the last three years where sales exceeded 5000 units in the USA */

SELECT
	EXTRACT(MONTH FROM sa.sale_date) AS sale_month,
	EXTRACT(YEAR FROM sa.sale_date) AS sale_year,
	st.country,
	SUM(sa.quantity) AS units_sold
FROM sales sa
JOIN stores st
ON sa.store_id = st.store_id
WHERE st.country = 'United States' AND sa.sale_date >= CURRENT_DATE - INTERVAL '3 Years'
GROUP BY EXTRACT(MONTH FROM sa.sale_date), EXTRACT(YEAR FROM sa.sale_date), st.country
HAVING SUM(sa.quantity) > 5000
ORDER BY sale_year;

/* Q15: Identify the product category with the most warranty claims filed in the last 2024 */

SELECT 
	c.category_id,
	c.category_name,
	COUNT(w.claim_id) AS claim_data
FROM category c
JOIN products p
	ON c.category_id = p.category_id
JOIN sales s
	ON p.product_id = s.product_id
JOIN warranty w
	ON w.sale_id = s.sale_id
WHERE EXTRACT(YEAR FROM w.claim_date) = 2024
GROUP BY c.category_id, c.category_name
ORDER BY claim_data DESC
LIMIT 1;

/* Q16: Determine the percentage chance of recieving warranty claims after 
each purchase for each country */

WITH c_t AS(
	SELECT
		st.country,
		COUNT(sa.sale_id) AS total_sales,
		COUNT(w.claim_id) AS total_claims
	FROM sales sa
	LEFT JOIN warranty w
	ON sa.sale_id = w.sale_id
	JOIN stores st
	ON sa.store_id = st.store_id
	GROUP BY st.country
)
SELECT 
	country,
	total_sales,
	total_claims,
	ROUND(100 * total_claims / total_sales, 2) AS perc_of_claim
FROM c_t;


/* Q17: Analyse the year by year growth ratio for each store */

WITH yearly_sale AS(
	SELECT
		sa.store_id,
		st.store_name,
		EXTRACT(YEAR from sa.sale_date) AS sale_year,
		SUM(sa.quantity) AS current_year_sale
	FROM sales sa
	JOIN stores st
	ON sa.store_id = st.store_id
	GROUP BY EXTRACT(YEAR from sa.sale_date), sa.store_id, st.store_name
	),
prev_sales AS(
	SELECT 
		store_id,
		store_name,
		sale_year,
		current_year_sale,
		LAG(current_year_sale) OVER(PARTITION BY store_id ORDER BY sale_year) AS prev_year_sale
	FROM yearly_sale
)
SELECT
	store_id,
	store_name,
	sale_year,
	current_year_sale,
	prev_year_sale,
	ROUND(100 * (current_year_sale - prev_year_sale) / prev_year_sale, 2) AS yearly_growth
FROM prev_sales;

/* Q18: Identify the store with the highest percentage of "pending" claims relative to 
total claims filed */

WITH claim_numbers AS(
	SELECT
		st.store_id,
		st.store_name,
		COUNT(CASE 
			WHEN w.repair_status = 'Pending' THEN 1 END) AS pending_claims, 
		COUNT(w.claim_id) AS total_claims
	FROM
		stores st
	JOIN sales sa
		ON st.store_id = sa.store_id
	JOIN warranty w
		ON sa.sale_id = w.sale_id
	GROUP BY st.store_id, st.store_name
)
SELECT 
	store_id,
	store_name,
	pending_claims,
	total_claims,
	ROUND(100 * pending_claims / total_claims, 2) AS percentage_of_pending_claims
FROM claim_numbers;

/* Q19: Calculate the monthly running total of sales for each store over the past four years and compare
trends during this period */

WITH m_totals AS(
	SELECT
		sa.store_id,
		st.store_name,
		DATE_TRUNC('month', sa.sale_date) AS sale_month,
		SUM(sa.quantity * p.price) AS monthly_sale_value
	FROM sales sa
	JOIN stores st
		ON sa.store_id = st.store_id
	JOIN products p
		ON sa.product_id = p.product_id
	WHERE sa.sale_date >= CURRENT_DATE - INTERVAL '4 Years'
	GROUP BY sa.store_id, st.store_name, DATE_TRUNC('month', sa.sale_date)
)
SELECT 
	store_id,
	store_name,
	sale_month,
	monthly_sale_value,
	SUM(monthly_sale_value) OVER (PARTITION BY store_id ORDER BY sale_month ROWS UNBOUNDED PRECEDING) AS running_total
FROM m_totals;

/* Q20: Create a PostgreSQL stored procedure that updates warranty status.
The procedure should:
1. Take sale_id as input
2. Check if a warranty claim exists for that sale
3. If it exists → update repair_status to 'Processed'
4. If it does not exist → RAISE NOTICE 'No warranty claim found' */

SELECT * FROM warranty;

CREATE OR REPLACE PROCEDURE update_warranty_status(
	p_sale_id VARCHAR(25))

LANGUAGE plpgsql
AS $$
DECLARE
v_repair_status VARCHAR(25);

BEGIN
	SELECT
		repair_status
	INTO v_repair_status
	FROM warranty
	WHERE sale_id = p_sale_id;
	
	IF v_repair_status IS NULL THEN
		RAISE NOTICE 'No warranty claim found for %', p_sale_id;
		RETURN;
	END IF;

	UPDATE warranty
		SET repair_status = 'Processed'
		WHERE sale_id = p_sale_id;
		
		RAISE NOTICE 'Repair status updated for %', p_sale_id;
END;
$$;

CALL update_warranty_status('JG-46890');