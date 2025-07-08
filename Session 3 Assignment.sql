---List all products with list price greater than 1000
SELECT * 
FROM production.products
WHERE list_price > 1000;

--Get customers from "CA" or "NY" states
SELECT * 
FROM sales.customers
WHERE state IN ('CA', 'NY');

--Retrieve all orders placed in 2023
SELECT * 
FROM sales.orders
WHERE YEAR(order_date) = 2023;

-- Show customers whose emails end with @gmail.com
SELECT * 
FROM sales.customers
WHERE email LIKE '%@gmail.com';


--Show all inactive staff
SELECT * 
FROM sales.staffs
WHERE active = 0;


--List top 5 most expensive products
SELECT TOP 5 * 
FROM production.products
ORDER BY list_price DESC;


--Show latest 10 orders sorted by date
SELECT TOP 10 * 
FROM sales.orders
ORDER BY order_date DESC;

-- Retrieve the first 3 customers alphabetically by last name
SELECT TOP 3 * 
FROM sales.customers
ORDER BY last_name ASC;


--Find customers who did not provide a phone number
SELECT * 
FROM sales.customers
WHERE phone IS NULL OR phone = '';

--Show all staff who have a manager assigned
SELECT * 
FROM sales.staffs
WHERE manager_id IS NOT NULL;


--Count number of products in each category
SELECT category_id, COUNT(*) AS product_count
FROM production.products
GROUP BY category_id;


--Count number of customers in each state
SELECT state, COUNT(*) AS customer_count
FROM sales.customers
GROUP BY state;


--Get average list price of products per brand
SELECT brand_id, AVG(list_price) AS avg_price
FROM production.products
GROUP BY brand_id;


-- Show number of orders per staff
SELECT staff_id, COUNT(*) AS order_count
FROM sales.orders
GROUP BY staff_id;


--Find customers who made more than 2 orders
SELECT customer_id, COUNT(*) AS order_count
FROM sales.orders
GROUP BY customer_id
HAVING COUNT(*) > 2;


--Products priced between 500 and 1500
SELECT * 
FROM production.products
WHERE list_price BETWEEN 500 AND 1500;


--Customers in cities starting with "S"
SELECT * 
FROM sales.customers
WHERE city LIKE 'S%';


--Orders with order_status either 2 or 4
SELECT * 
FROM sales.orders
WHERE order_status IN (2, 4);


--Products from category_id IN (1, 2, 3)
SELECT * 
FROM production.products
WHERE category_id IN (1, 2, 3);


-- Staff working in store_id = 1 OR without phone number
SELECT * 
FROM sales.staffs
WHERE store_id = 1 OR phone IS NULL OR phone = '';

