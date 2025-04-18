## **Solving Business Problems**




1. Identifying Underperforming Products
Challenge: Determine which products have low sales despite being in stock.


'''sql
SELECT p.product_id, p.product_name, 
       i.stock_quantity, 
       COALESCE(SUM(od.quantity), 0) AS total_sold
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name, i.stock_quantity
ORDER BY total_sold ASC
LIMIT 10;
'''


2. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.

```sql
SELECT 
	oi.product_id,
	p.product_name,
	SUM(oi.total_sale) as total_sale,
	COUNT(o.order_id)  as total_orders
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON p.product_id = oi.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10
```

3.Customer Churn Prediction

 Challenge:Identify customers who haven not  made a purchase in the last 6 months.


'''sql

SELECT customer_id, MAX(order_date) AS last_purchase_date
FROM orders
GROUP BY customer_id
HAVING MAX(order_date) < NOW() - INTERVAL '6 months';
Stockout Risk Analysis
'''



4.High-Value Customers with Recency, Frequency, and Monetary (RFM) Analysis
Challenge : Rank customers based on their recent purchases, frequency of purchases, and total spending to create targeted marketing campaigns.


'''sql

WITH rfm AS (
    SELECT customer_id,
           RANK() OVER (ORDER BY MAX(order_date) DESC) AS recency_rank,
           RANK() OVER (ORDER BY COUNT(order_id) DESC) AS frequency_rank,
           RANK() OVER (ORDER BY SUM(order_amount) DESC) AS monetary_rank
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, 
       recency_rank, 
       frequency_rank, 
       monetary_rank,
       (recency_rank + frequency_rank + monetary_rank) AS rfm_score
FROM rfm
ORDER BY rfm_score ASC  -- Lower score indicates high-value customers
LIMIT 10;
'''


5 Identifying Peak Sales Hours for Better Inventory Management
Challenge: Find the most profitable hours of the day to optimize staffing and inventory.

'''
sql
Copy
Edit
SELECT EXTRACT(HOUR FROM order_date) AS order_hour,
       SUM(order_amount) AS total_revenue,
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY total_revenue DESC;
'''

6. Customer Refund Rate Analysis
Challenge: Identify customers who frequently request refunds and analyze the impact on revenue.



'''sql

SELECT o.customer_id, 
       COUNT(r.refund_id) AS total_refunds, 
       COUNT(o.order_id) AS total_orders,
       (COUNT(r.refund_id) * 100.0 / COUNT(o.order_id)) AS refund_rate
FROM orders o
LEFT JOIN refunds r ON o.order_id = r.order_id
GROUP BY o.customer_id
ORDER BY refund_rate DESC
LIMIT 10;
'''

7. Identifying Underperforming Products
Challenge: Determine which products have low sales despite being in stock.


'''sql
SELECT p.product_id, p.product_name, 
       i.stock_quantity, 
       COALESCE(SUM(od.quantity), 0) AS total_sold
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name, i.stock_quantity
ORDER BY total_sold ASC
LIMIT 10;
'''

8. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.

```sql
SELECT 
	p.category_id,
	c.category_name,
	SUM(oi.total_sale) as total_sale,
	SUM(oi.total_sale)/
					(SELECT SUM(total_sale) FROM order_items) 
					* 100
	as contribution
FROM order_items as oi
JOIN
products as p
ON p.product_id = oi.product_id
LEFT JOIN category as c
ON c.category_id = p.category_id
GROUP BY 1, 2
ORDER BY 3 DESC
```




9.Problem: Find product pairs that are frequently bought together.



'''
SELECT a.product_id AS product_1, 
       b.product_id AS product_2, 
       COUNT(*) AS frequency
FROM order_details a
JOIN order_details b ON a.order_id = b.order_id AND a.product_id <> b.product_id
GROUP BY product_1, product_2
ORDER BY frequency DESC
LIMIT 10;

'''








10. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.

```sql
SELECT 
	c.customer_id,
	CONCAT(c.first_name, ' ',  c.last_name) as full_name,
	SUM(total_sale)/COUNT(o.order_id) as AOV,
	COUNT(o.order_id) as total_orders --- filter
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
HAVING  COUNT(o.order_id) > 5
```

11. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!

```sql
SELECT 
	year,
	month,
	total_sale as current_month_sale,
	LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale
FROM ---
(
SELECT 
	EXTRACT(MONTH FROM o.order_date) as month,
	EXTRACT(YEAR FROM o.order_date) as year,
	ROUND(
			SUM(oi.total_sale::numeric)
			,2) as total_sale
FROM orders as o
JOIN
order_items as oi
ON oi.order_id = o.order_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY year, month
) as t1
```


12. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.

```sql
Approach 1
SELECT *
	-- reg_date - CURRENT_DATE
FROM customers
WHERE customer_id NOT IN (SELECT 
					DISTINCT customer_id
				FROM orders
				);
```
```sql
-- Approach 2
SELECT *
FROM customers as c
LEFT JOIN
orders as o
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL
```

13. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.

```sql
WITH ranking_table
AS
(
SELECT 
	c.state,
	cat.category_name,
	SUM(oi.total_sale) as total_sale,
	RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sale) ASC) as rank
FROM orders as o
JOIN 
customers as c
ON o.customer_id = c.customer_id
JOIN
order_items as oi
ON o.order_id = oi. order_id
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN
category as cat
ON cat.category_id = p.category_id
GROUP BY 1, 2
)
SELECT 
*
FROM ranking_table
WHERE rank = 1
```


14. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.

```sql
SELECT 
	c.customer_id,
	CONCAT(c.first_name, ' ',  c.last_name) as full_name,
	SUM(total_sale) as CLTV,
	DENSE_RANK() OVER( ORDER BY SUM(total_sale) DESC) as cx_ranking
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
```


15. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.

```sql
SELECT 
	i.inventory_id,
	p.product_name,
	i.stock as current_stock_left,
	i.last_stock_date,
	i.warehouse_id
FROM inventory as i
join 
products as p
ON p.product_id = i.product_id
WHERE stock < 10
```

16. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.

```sql
SELECT 
	c.*,
	o.*,
	s.shipping_providers,
s.shipping_date - o.order_date as days_took_to_ship
FROM orders as o
JOIN
customers as c
ON c.customer_id = o.customer_id
JOIN 
shippings as s
ON o.order_id = s.order_id
WHERE s.shipping_date - o.order_date > 3
```

17. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).

```sql
SELECT 
	p.payment_status,
	COUNT(*) as total_cnt,
	COUNT(*)::numeric/(SELECT COUNT(*) FROM payments)::numeric * 100
FROM orders as o
JOIN
payments as p
ON o.order_id = p.order_id
GROUP BY 1
```

18. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.

```sql
WITH top_sellers
AS
(SELECT 
	s.seller_id,
	s.seller_name,
	SUM(oi.total_sale) as total_sale
FROM orders as o
JOIN
sellers as s
ON o.seller_id = s.seller_id
JOIN 
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5
),

sellers_reports
AS
(SELECT 
	o.seller_id,
	ts.seller_name,
	o.order_status,
	COUNT(*) as total_orders
FROM orders as o
JOIN 
top_sellers as ts
ON ts.seller_id = o.seller_id
WHERE 
	o.order_status NOT IN ('Inprogress', 'Returned')
	
GROUP BY 1, 2, 3
)
SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	SUM(total_orders)::numeric * 100 as successful_orders_percentage
	
FROM sellers_reports
GROUP BY 1, 2
```


19. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/


```sql
SELECT 
	product_id,
	product_name,
	profit_margin,
	DENSE_RANK() OVER( ORDER BY profit_margin DESC) as product_ranking
FROM
(SELECT 
	p.product_id,
	p.product_name,
	-- SUM(total_sale - (p.cogs * oi.quantity)) as profit,
	SUM(total_sale - (p.cogs * oi.quantity))/sum(total_sale) * 100 as profit_margin
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
GROUP BY 1, 2
) as t1
```

20. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.

```sql
SELECT 
	p.product_id,
	p.product_name,
	COUNT(*) as total_unit_sold,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returned,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric/COUNT(*)::numeric * 100 as return_percentage
FROM order_items as oi
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN orders as o
ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 DESC
```

21. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.

```sql
WITH cte1 -- as these sellers has not done any sale in last 6 month
AS
(SELECT * FROM sellers
WHERE seller_id NOT IN (SELECT seller_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '6 month')
)

SELECT 
o.seller_id,
MAX(o.order_date) as last_sale_date,
MAX(oi.total_sale) as last_sale_amount
FROM orders as o
JOIN 
cte1
ON cte1.seller_id = o.seller_id
JOIN order_items as oi
ON o.order_id = oi.order_id
GROUP BY 1
```


22. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns

```sql
SELECT 
c_full_name as customers,
total_orders,
total_return,
CASE
	WHEN total_return > 5 THEN 'Returning_customers' ELSE 'New'
END as cx_category
FROM
(SELECT 
	CONCAT(c.first_name, ' ', c.last_name) as c_full_name,
	COUNT(o.order_id) as total_orders,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_return	
FROM orders as o
JOIN 
customers as c
ON c.customer_id = o.customer_id
JOIN
order_items as oi
ON oi.order_id = o.order_id
GROUP BY 1)
```


23. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
```sql
SELECT * FROM 
(SELECT 
	c.state,
	CONCAT(c.first_name, ' ', c.last_name) as customers,
	COUNT(o.order_id) as total_orders,
	SUM(total_sale) as total_sale,
	DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) as rank
FROM orders as o
JOIN 
order_items as oi
ON oi.order_id = o.order_id
JOIN 
customers as c
ON 
c.customer_id = o.customer_id
GROUP BY 1, 2
) as t1
WHERE rank <=5
```

24.Identifying Most Profitable Payment Methods
Challenge: Determine which payment methods contribute the most revenue and whether any payment method has a high failure or refund rate.


'''sql
SELECT o.payment_method, 
       COUNT(o.order_id) AS total_orders, 
       SUM(o.order_amount) AS total_revenue,
       COUNT(r.refund_id) AS total_refunds,
       (COUNT(r.refund_id) * 100.0 / COUNT(o.order_id)) AS refund_rate
FROM orders o
LEFT JOIN refunds r ON o.order_id = r.order_id
GROUP BY o.payment_method
ORDER BY total_revenue DESC;
'''






---

---

