-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name, rtrim(ltrim(substr(product_name, instr(product_name, '-') + 1, length(product_name)))) description
FROM product 
WHERE instr(product_name,'-')


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_name, product_size
FROM product 
WHERE product_size REGEXP('\d+')

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

CREATE TEMPORARY TABLE IF NOT EXISTS temp_best_sales AS 
select market_date, quantity * cost_to_customer_per_qty total_sales
from customer_purchases
GROUP by market_date
ORDER by total_sales DESC LIMIT 1

CREATE TEMPORARY TABLE IF NOT EXISTS temp_worst_sales AS 
select market_date, quantity * cost_to_customer_per_qty total_sales
from customer_purchases
GROUP by market_date
ORDER by total_sales LIMIT 1

select * from temp_best_sales UNION select * from temp_worst_sales

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

select vendor_name, product_name, round(sum(sales_amount),2) sales_by_product 
FROM 
	(
		select *, 5 quantity, 5 * original_price sales_amount
		FROM 
			(SELECT customer_id FROM customer)
			CROSS JOIN 
			(select DISTINCT vendor_name, product_name, original_price 
			 FROM vendor_inventory
			 JOIN vendor ON vendor_inventory.vendor_id = vendor.vendor_id
			 JOIN product ON vendor_inventory.product_id = product.product_id)
	)
GROUP by vendor_name, product_name

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units AS 
SELECT *, CURRENT_TIMESTAMP snapshot_timestamp 
FROM product 
WHERE product_qty_type = 'unit'

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units VALUES ( 24 ,'Apple pie - Organic', 'large', 3, 'unit', CURRENT_TIMESTAMP)

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units WHERE product_id = 24

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

CREATE TEMP TABLE IF NOT EXISTS current_inventory AS 
SELECT * FROM
( SELECT product_id, ifnull(quantity, 0) quantity, dense_rank() OVER (PARTITION BY product_id ORDER BY market_date DESC) AS rank_no
FROM (SELECT P.product_id, quantity, market_date FROM  product P LEFT OUTER JOIN vendor_inventory V ON P.product_id = V.product_id)
)
WHERE rank_no = 1

UPDATE product_units AS prd SET current_quantity = inv.quantity
FROM (select * FROM current_inventory) AS inv
WHERE prd.product_id = inv.product_id
