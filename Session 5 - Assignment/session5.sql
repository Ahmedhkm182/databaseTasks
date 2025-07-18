--1.Write a query that classifies all products into price categories:

--Products under $300: "Economy"
--Products $300-$999: "Standard"
--Products $1000-$2499: "Premium"
--Products $2500 and above: "Luxury"

SELECT 
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Economy'
        WHEN list_price BETWEEN 300 AND 999 THEN 'Standard'
        WHEN list_price BETWEEN 1000 AND 2499 THEN 'Premium'
        WHEN list_price >= 2500 THEN 'Luxury'
    END AS price_category
FROM 
    production.products;



--2.Create a query that shows order processing information with user-friendly status descriptions:

--Status 1: "Order Received"
--Status 2: "In Preparation"
--Status 3: "Order Cancelled"
--Status 4: "Order Delivered"
--Also add a priority level:

--Orders with status 1 older than 5 days: "URGENT"
--Orders with status 2 older than 3 days: "HIGH"
--All other orders: "NORMAL"

SELECT 
    order_id,
    customer_id,
    order_date,
    order_status,
    CASE 
        WHEN order_status = 1 THEN 'Order Received'
        WHEN order_status = 2 THEN 'In Preparation'
        WHEN order_status = 3 THEN 'Order Cancelled'
        WHEN order_status = 4 THEN 'Order Delivered'
        ELSE 'Unknown Status'
    END AS status_description,
    CASE 
        WHEN order_status = 1 AND DATEDIFF(DAY, order_date, GETDATE()) > 5 THEN 'URGENT'
        WHEN order_status = 2 AND DATEDIFF(DAY, order_date, GETDATE()) > 3 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS priority_level
FROM 
    sales.orders;



--3.Write a query that categorizes staff based on the number of orders they've handled:

--0 orders: "New Staff"
--1-10 orders: "Junior Staff"
--11-25 orders: "Senior Staff"
--26+ orders: "Expert Staff"

SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    COUNT(o.order_id) AS total_orders,
    CASE 
        WHEN COUNT(o.order_id) = 0 THEN 'New Staff'
        WHEN COUNT(o.order_id) BETWEEN 1 AND 10 THEN 'Junior Staff'
        WHEN COUNT(o.order_id) BETWEEN 11 AND 25 THEN 'Senior Staff'
        ELSE 'Expert Staff'
    END AS staff_level
FROM 
    sales.staffs s
LEFT JOIN 
    sales.orders o ON s.staff_id = o.staff_id
GROUP BY 
    s.staff_id, s.first_name, s.last_name;



--	4.Create a query that handles missing customer contact information:

--Use ISNULL to replace missing phone numbers with "Phone Not Available"
--Use COALESCE to create a preferred_contact field (phone first, then email, then "No Contact Method")
--Show complete customer information

SELECT 
    customer_id,
    first_name,
    last_name,
    ISNULL(phone, 'Phone Not Available') AS phone,
    email,
    COALESCE(phone, email, 'No Contact Method') AS preferred_contact
FROM 
    sales.customers;




--	5.Write a query that safely calculates price per unit in stock:

--Use NULLIF to prevent division by zero when quantity is 0
--Use ISNULL to show 0 when no stock exists
--Include stock status using CASE WHEN
--Only show products from store_id = 1

SELECT 
    p.product_id,
    p.product_name,
    p.list_price,
    s.quantity,
    ISNULL(p.list_price / NULLIF(s.quantity, 0), 0) AS price_per_unit,
    CASE 
        WHEN s.quantity = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    production.products p
JOIN 
    production.stocks s ON p.product_id = s.product_id
WHERE 
    s.store_id = 1;






--6.Create a query that formats complete addresses safely:

--Use COALESCE for each address component
--Create a formatted_address field that combines all components
--Handle missing ZIP codes gracefully

SELECT 
    customer_id,
    first_name,
    last_name,
    COALESCE(street, '') AS street,
    COALESCE(city, '') AS city,
    COALESCE(state, '') AS state,
    COALESCE(zip_code, 'ZIP Not Provided') AS zip_code,
    CONCAT_WS(', ',
        COALESCE(street, ''),
        COALESCE(city, ''),
        COALESCE(state, ''),
        COALESCE(zip_code, 'ZIP Not Provided')
    ) AS formatted_address
FROM 
    sales.customers;





--	7.Use a CTE to find customers who have spent more than $1,500 total:

--Create a CTE that calculates total spending per customer
--Join with customer information
--Show customer details and spending
--Order by total_spent descending

WITH customer_spending AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        o.customer_id
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    s.total_spent
FROM 
    customer_spending s
JOIN 
    sales.customers c ON s.customer_id = c.customer_id
WHERE 
    s.total_spent > 1500
ORDER BY 
    s.total_spent DESC;




--	8.Create a multi-CTE query for category analysis:

--CTE 1: Calculate total revenue per category
--CTE 2: Calculate average order value per category
--Main query: Combine both CTEs
--Use CASE to rate performance: >$50000 = "Excellent", >$20000 = "Good", else = "Needs Improvement"

WITH revenue_per_category AS (
    SELECT 
        p.category_id,
        c.category_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    JOIN 
        production.products p ON oi.product_id = p.product_id
    JOIN 
        production.categories c ON p.category_id = c.category_id
    GROUP BY 
        p.category_id, c.category_name
),
avg_order_value_per_category AS (
    SELECT 
        p.category_id,
        AVG(oi.quantity * oi.list_price * (1 - oi.discount)) AS avg_order_value
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    JOIN 
        production.products p ON oi.product_id = p.product_id
    GROUP BY 
        p.category_id
)
SELECT 
    r.category_name,
    r.total_revenue,
    a.avg_order_value,
    CASE 
         WHEN r.total_revenue > 50000 THEN 'Excellent'
        WHEN r.total_revenue > 20000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_rating
FROM 
    revenue_per_category r
JOIN 
    avg_order_value_per_category a ON r.category_id = a.category_id;


--	9.Use CTEs to analyze monthly sales trends:

--CTE 1: Calculate monthly sales totals
--CTE 2: Add previous month comparison
--Show growth percentage

WITH monthly_sales AS (
    SELECT 
        FORMAT(o.order_date, 'yyyy-MM') AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS monthly_total
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        FORMAT(o.order_date, 'yyyy-MM')
),
monthly_comparison AS (
    SELECT 
        month,
        monthly_total,
        LAG(monthly_total) OVER (ORDER BY month) AS previous_month_total
    FROM 
        monthly_sales
)
SELECT 
    month,
    monthly_total,
    previous_month_total,
    ROUND(
        CASE 
            WHEN previous_month_total = 0 THEN NULL
            ELSE (monthly_total - previous_month_total) * 100.0 / previous_month_total
        END, 2
    ) AS growth_percentage
FROM 
    monthly_comparison;



--10.Create a query that ranks products within each category:

--Use ROW_NUMBER() to rank by price (highest first)
--Use RANK() to handle ties
--Use DENSE_RANK() for continuous ranking
--Only show top 3 products per category

SELECT *
FROM (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.list_price,
        ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS row_num,
        RANK() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS rank_num,
        DENSE_RANK() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS dense_rank_num
    FROM 
        production.products p
    JOIN 
        production.categories c ON p.category_id = c.category_id
) AS ranked
WHERE 
    row_num <= 3;





--	11.Rank customers by their total spending:

--Calculate total spending per customer
--Use RANK() for customer ranking
--Use NTILE(5) to divide into 5 spending groups
--Use CASE for tiers: 1="VIP", 2="Gold", 3="Silver", 4="Bronze", 5="Standard"

WITH customer_spending AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spent
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        o.customer_id
),
ranked_customers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank,
        NTILE(5) OVER (ORDER BY cs.total_spent DESC) AS spending_group
    FROM 
        customer_spending cs
    JOIN 
        sales.customers c ON cs.customer_id = c.customer_id
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_spent,
    spending_rank,
    spending_group,
    CASE 
        WHEN spending_group = 1 THEN 'VIP'
        WHEN spending_group = 2 THEN 'Gold'
        WHEN spending_group = 3 THEN 'Silver'
        WHEN spending_group = 4 THEN 'Bronze'
        ELSE 'Standard'
    END AS spending_tier
FROM 
    ranked_customers;






--	12.Create a comprehensive store performance ranking:

--Rank stores by total revenue
--Rank stores by number of orders
--Use PERCENT_RANK() to show percentile performance

WITH store_metrics AS (
    SELECT 
        o.store_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        o.store_id
)
SELECT 
    s.store_id,
    s.total_revenue,
    s.total_orders,
    RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY s.total_orders DESC) AS order_rank,
    PERCENT_RANK() OVER (ORDER BY s.total_revenue) AS revenue_percentile
FROM 
    store_metrics s;



--	13.Create a PIVOT table showing product counts by category and brand:

--Rows: Categories
--Columns: Top 4 brands (Electra, Haro, Trek, Surly)
--Values: Count of products

SELECT 
    category_name,
    ISNULL([Electra], 0) AS Electra,
    ISNULL([Haro], 0) AS Haro,
    ISNULL([Trek], 0) AS Trek,
    ISNULL([Surly], 0) AS Surly
FROM (
    SELECT 
        c.category_name,
        b.brand_name
    FROM 
        production.products p
    JOIN 
        production.categories c ON p.category_id = c.category_id
    JOIN 
        production.brands b ON p.brand_id = b.brand_id
    WHERE 
        b.brand_name IN ('Electra', 'Haro', 'Trek', 'Surly')
) AS source
PIVOT (
    COUNT(brand_name)
    FOR brand_name IN ([Electra], [Haro], [Trek], [Surly])
) AS pivot_table;



--14.Create a PIVOT showing monthly sales revenue by store:

--Rows: Store names
--Columns: Months (Jan through Dec)
--Values: Total revenue
--Add a total column

SELECT 
    store_name,
    ISNULL([Jan], 0) AS Jan,
    ISNULL([Feb], 0) AS Feb,
    ISNULL([Mar], 0) AS Mar,
    ISNULL([Apr], 0) AS Apr,
    ISNULL([May], 0) AS May,
    ISNULL([Jun], 0) AS Jun,
    ISNULL([Jul], 0) AS Jul,
    ISNULL([Aug], 0) AS Aug,
    ISNULL([Sep], 0) AS Sep,
    ISNULL([Oct], 0) AS Oct,
    ISNULL([Nov], 0) AS Nov,
    ISNULL([Dec], 0) AS Dec,
    -- حساب المجموع الكلي للإيرادات
    ISNULL([Jan],0)+ISNULL([Feb],0)+ISNULL([Mar],0)+ISNULL([Apr],0)+ISNULL([May],0)+
    ISNULL([Jun],0)+ISNULL([Jul],0)+ISNULL([Aug],0)+ISNULL([Sep],0)+ISNULL([Oct],0)+
    ISNULL([Nov],0)+ISNULL([Dec],0) AS Total
FROM (
    SELECT 
        s.store_name,
        LEFT(DATENAME(MONTH, o.order_date), 3) AS month,
        oi.quantity * oi.list_price * (1 - oi.discount) AS revenue
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    JOIN 
        sales.stores s ON o.store_id = s.store_id
) AS source
PIVOT (
    SUM(revenue)
    FOR month IN ([Jan], [Feb], [Mar], [Apr], [May], [Jun], [Jul], [Aug], [Sep], [Oct], [Nov], [Dec])
) AS pivot_table;





--15.PIVOT order statuses across stores:

--Rows: Store names
--Columns: Order statuses (Pending, Processing, Completed, Rejected)
--Values: Count of orders

SELECT 
    store_name,
    ISNULL([Pending], 0) AS Pending,
    ISNULL([Processing], 0) AS Processing,
    ISNULL([Completed], 0) AS Completed,
    ISNULL([Rejected], 0) AS Rejected
FROM (
    SELECT 
        s.store_name,
        CASE o.order_status 
            WHEN 1 THEN 'Pending'
            WHEN 2 THEN 'Processing'
            WHEN 3 THEN 'Completed'
            WHEN 4 THEN 'Rejected'
        END AS status_name
    FROM 
        sales.orders o
    JOIN 
        sales.stores s ON o.store_id = s.store_id
) AS source
PIVOT (
    COUNT(status_name) 
    FOR status_name IN ([Pending], [Processing], [Completed], [Rejected])
) AS pivot_table;




--16.Create a PIVOT comparing sales across years:

--Rows: Brand names
--Columns: Years (2016, 2017, 2018)
--Values: Total revenue
--Include percentage growth calculations
WITH yearly_sales AS (
    SELECT 
        b.brand_name AS brand,
        YEAR(o.order_date) AS year,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    JOIN 
        production.products p ON oi.product_id = p.product_id
    JOIN 
        production.brands b ON p.brand_id = b.brand_id
    GROUP BY 
        b.brand_name, YEAR(o.order_date)
)
SELECT 
    brand,
    ISNULL([2016], 0) AS sales_2016,
    ISNULL([2017], 0) AS sales_2017,
    ISNULL([2018], 0) AS sales_2018,
    CASE 
        WHEN ISNULL([2017], 0) = 0 THEN NULL
        ELSE ROUND(((ISNULL([2018], 0) - ISNULL([2017], 0)) * 100.0 / NULLIF([2017], 0)), 2)
    END AS growth_percent
FROM 
    yearly_sales
PIVOT (
    SUM(revenue) FOR year IN ([2016], [2017], [2018])
) AS pivot_table;


--17.Use UNION to combine different product availability statuses:

--Query 1: In-stock products (quantity > 0)
--Query 2: Out-of-stock products (quantity = 0 or NULL)
--Query 3: Discontinued products (not in stocks table)


-- المنتجات الموجودة فعليًا في المخزون ولها كمية > 0
SELECT 
    p.product_id, 
    p.product_name, 
    'In Stock' AS status
FROM 
    production.products p
JOIN 
    production.stocks s ON p.product_id = s.product_id
WHERE 
    s.quantity > 0

UNION

-- المنتجات الموجودة لكن كميتها صفر أو NULL
SELECT 
    p.product_id, 
    p.product_name, 
    'Out of Stock' AS status
FROM 
    production.products p
JOIN 
    production.stocks s ON p.product_id = s.product_id
WHERE 
    s.quantity = 0 OR s.quantity IS NULL

UNION

-- المنتجات التي لا توجد لها أي سجلات في جدول المخزون (أي لم تُسجل في المخازن)
SELECT 
    p.product_id, 
    p.product_name, 
    'Discontinued' AS status
FROM 
    production.products p
LEFT JOIN 
    production.stocks s ON p.product_id = s.product_id
WHERE 
    s.product_id IS NULL;





--18.Use INTERSECT to find loyal customers:

--Find customers who bought in both 2017 AND 2018
--Show their purchase patterns

SELECT customer_id
FROM sales.orders
WHERE YEAR(order_date) = 2017

INTERSECT

SELECT customer_id
FROM sales.orders
WHERE YEAR(order_date) = 2018;






--19.Use multiple set operators to analyze product distribution:

--INTERSECT: Products available in all 3 stores
--EXCEPT: Products available in store 1 but not in store 2
--UNION: Combine above results with different labels


-- المنتجات الموجودة في جميع الفروع (Store 1, 2, و3)
SELECT product_id 
FROM production.stocks 
WHERE store_id = 1

INTERSECT

SELECT product_id 
FROM production.stocks 
WHERE store_id = 2

INTERSECT

SELECT product_id 
FROM production.stocks 
WHERE store_id = 3

UNION

-- المنتجات الموجودة في Store 1 فقط وليست في Store 2
SELECT product_id 
FROM production.stocks 
WHERE store_id = 1

EXCEPT

SELECT product_id 
FROM production.stocks 
WHERE store_id = 2;




--20.Complex set operations for customer retention:

--Find customers who bought in 2016 but not in 2017 (lost customers)
--Find customers who bought in 2017 but not in 2016 (new customers)
--Find customers who bought in both years (retained customers)
--Use UNION ALL to combine all three groups


SELECT customer_id, 'Lost' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2016
EXCEPT
SELECT customer_id, 'Lost'
FROM sales.orders
WHERE YEAR(order_date) = 2017

UNION ALL


SELECT customer_id, 'New' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2017
EXCEPT
SELECT customer_id, 'New'
FROM sales.orders
WHERE YEAR(order_date) = 2016

UNION ALL


SELECT customer_id, 'Retained' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2016
INTERSECT
SELECT customer_id, 'Retained'
FROM sales.orders
WHERE YEAR(order_date) = 2017;
