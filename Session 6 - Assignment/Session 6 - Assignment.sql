--1. Customer Spending Analysis#
--Write a query that uses variables to find the total amount spent by 
--customer ID1. Display a message showing whether they are a 
--VIP customer (spent > $5000) or regular customer.
DECLARE @CustomerId INT = 1;
DECLARE @TotalSpent MONEY;
DECLARE @Status VARCHAR(20);

SELECT @TotalSpent = SUM(oi.quantity * oi.list_price * (1 - oi.discount))
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.customer_id = @CustomerId;

SET @Status = 
    CASE 
        WHEN @TotalSpent > 5000 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END;

PRINT 'Customer ID: ' + CAST(@CustomerId AS VARCHAR);
PRINT 'Total Spent: $' + CAST(@TotalSpent AS VARCHAR);
PRINT 'Status: ' + @Status;



--2. Product Price Threshold Report#
--Create a query using variables to count how many products cost more than $1500. 
--Store the threshold price in a variable and display both the threshold and count in a formatted message.

DECLARE @Threshold MONEY = 1500;
DECLARE @ProductCount INT;

SELECT @ProductCount = COUNT(*)
FROM production.products
WHERE list_price > @Threshold;

PRINT 'Threshold Price: $' + CAST(@Threshold AS VARCHAR);
PRINT 'Number of Products Above Threshold: ' + CAST(@ProductCount AS VARCHAR);



--3. Staff Performance Calculator#
--Write a query that calculates the total sales for staff member ID 2 in the year 2017. Use variables to
--store the staff ID, year, and calculated total. Display the results with appropriate labels.

DECLARE @StaffId INT = 2;
DECLARE @TargetYear INT = 2017;
DECLARE @TotalSales MONEY;

SELECT @TotalSales = SUM(oi.quantity * oi.list_price * (1 - oi.discount))
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.staff_id = @StaffId AND YEAR(o.order_date) = @TargetYear;

PRINT 'Staff ID: ' + CAST(@StaffId AS VARCHAR);
PRINT 'Year: ' + CAST(@TargetYear AS VARCHAR);
PRINT 'Total Sales: $' + CAST(@TotalSales AS VARCHAR);




--4. Global Variables Information#
--Create a query that displays the current server name, SQL Server version, and
--the number of rows affected by the last statement. Use appropriate global variables.

SELECT 
    @@SERVERNAME AS server_name,
    @@VERSION AS sql_server_version,
    @@ROWCOUNT AS last_statement_rows;




--	5.Write a query that checks the inventory level for product ID 1 in store ID 1. Use IF statements to display different messages based on stock levels:#
--If quantity > 20: Well stocked
--If quantity 10-20: Moderate stock
--If quantity < 10: Low stock - reorder needed

DECLARE @Quantity INT;

SELECT @Quantity = quantity
FROM production.stocks
WHERE product_id = 1 AND store_id = 1;

IF @Quantity > 20
    PRINT 'Well stocked';
ELSE IF @Quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE IF @Quantity < 10
    PRINT 'Low stock - reorder needed';
ELSE
    PRINT 'Product not found or no stock data';




	--6.Create a WHILE loop that updates low-stock items (quantity < 5) in batches of 3 products at a time.
	--Add 10 units to each product and display progress messages after each batch.

	DECLARE @BatchSize INT = 3;
DECLARE @Counter INT = 0;

WHILE EXISTS (
    SELECT 1 FROM production.stocks 
    WHERE quantity < 5
)
BEGIN
    UPDATE TOP (@BatchSize) production.stocks
    SET quantity = quantity + 10
    WHERE quantity < 5;

    SET @Counter = @Counter + 1;
    PRINT 'Batch ' + CAST(@Counter AS VARCHAR) + ' updated.';
END;




--7. Product Price Categorization#
--Write a query that categorizes all products using CASE WHEN based on their list price:

--Under $300: Budget
--$300-$800: Mid-Range
--$801-$2000: Premium
--Over $2000: Luxury

SELECT 
    product_id,
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_category
FROM 
    production.products;




--	8. Customer Order Validation#
--Create a query that checks if customer ID 5 exists in the database.
--If they exist, show their order count. If not, display an appropriate message.

IF EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = 5)
BEGIN
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*) FROM sales.orders WHERE customer_id = 5;
    PRINT 'Customer ID 5 exists. Order count: ' + CAST(@OrderCount AS VARCHAR);
END
ELSE
BEGIN
    PRINT 'Customer ID 5 does not exist.';
END;





--9. Shipping Cost Calculator Function#
--Create a scalar function named CalculateShipping that takes an order total as input and returns shipping cost:

--Orders over $100: Free shipping ($0)
--Orders $50-$99: Reduced shipping ($5.99)
--Orders under $50: Standard shipping ($12.99)

CREATE FUNCTION dbo.CalculateShipping(@OrderTotal decimal(10,2))
RETURNS MONEY
AS
BEGIN
    RETURN 
        CASE 
            WHEN @OrderTotal > 100 THEN 0
            WHEN @OrderTotal BETWEEN 50 AND 99.99 THEN 5.99
            ELSE 12.99
        END;
END;




--10. Product Category Function#
--Create an inline table-valued function named GetProductsByPriceRange that accepts minimum and maximum price parameters and returns all products within that price range with their brand and category information.


CREATE FUNCTION dbo.GetProductsByPriceRange(@MinPrice decimal(10,2), @MaxPrice  decimal(10,2))
RETURNS TABLE
AS
RETURN (
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        b.brand_name,
        c.category_name
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice
);



--11. Customer Sales Summary Function#
--Create a multi-statement function named GetCustomerYearlySummary that takes a customer ID and returns a table with yearly sales data including total orders, total spent, and average order value for each year.

CREATE FUNCTION dbo.GetCustomerYearlySummary(@CustomerId INT)
RETURNS @Summary TABLE (
    Year INT,
    TotalOrders INT,
    TotalSpent MONEY,
    AvgOrderValue MONEY
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(o.order_date) AS Year,
        COUNT(DISTINCT o.order_id) AS TotalOrders,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS TotalSpent,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) / COUNT(DISTINCT o.order_id) AS AvgOrderValue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerId
    GROUP BY YEAR(o.order_date);

    RETURN;
END;





--12. Discount Calculation Function#
--Write a scalar function named CalculateBulkDiscount that determines discount percentage based on quantity:

--1-2 items: 0% discount
--3-5 items: 5% discount
--6-9 items: 10% discount
--10+ items: 15% discount

CREATE FUNCTION dbo.CalculateBulkDiscount(@Quantity INT)
RETURNS INT
AS
BEGIN
    RETURN
        CASE 
            WHEN @Quantity BETWEEN 1 AND 2 THEN 0
            WHEN @Quantity BETWEEN 3 AND 5 THEN 5
            WHEN @Quantity BETWEEN 6 AND 9 THEN 10
            ELSE 15
        END;
END;




--13. Customer Order History Procedure#
--Create a stored procedure named sp_GetCustomerOrderHistory that accepts a customer ID and optional start/end dates. Return the customer's order history with order totals calculated.
CREATE PROCEDURE sp_GetCustomerOrderHistory
    @CustomerId INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_amount
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerId
      AND (@StartDate IS NULL OR o.order_date >= @StartDate)
      AND (@EndDate IS NULL OR o.order_date <= @EndDate)
    GROUP BY o.order_id, o.order_date
    ORDER BY o.order_date;
END;



--14. Inventory Restock Procedure#
--Write a stored procedure named sp_RestockProduct with input parameters for store ID, product ID, and restock quantity. Include output parameters for old quantity, new quantity, and success status.

CREATE PROCEDURE sp_RestockProduct
    @StoreId INT,
    @ProductId INT,
    @RestockQty INT,
    @OldQty INT OUTPUT,
    @NewQty INT OUTPUT,
    @Status VARCHAR(50) OUTPUT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM production.stocks 
        WHERE store_id = @StoreId AND product_id = @ProductId
    )
    BEGIN
        SELECT @OldQty = quantity 
        FROM production.stocks 
        WHERE store_id = @StoreId AND product_id = @ProductId;

        UPDATE production.stocks
        SET quantity = quantity + @RestockQty
        WHERE store_id = @StoreId AND product_id = @ProductId;

        SELECT @NewQty = quantity 
        FROM production.stocks 
        WHERE store_id = @StoreId AND product_id = @ProductId;

        SET @Status = 'Restock successful';
    END
    ELSE
    BEGIN
        SET @OldQty = NULL;
        SET @NewQty = NULL;
        SET @Status = 'Stock record not found';
    END
END;



--16. Dynamic Product Search Procedure#
--Write a stored procedure named sp_SearchProducts that builds dynamic SQL based on optional parameters: product name search term, category ID, minimum price, maximum price, and sort column.

CREATE PROCEDURE sp_SearchProducts
    @NameTerm NVARCHAR(100) = NULL,
    @CategoryId INT = NULL,
    @MinPrice MONEY = NULL,
    @MaxPrice MONEY = NULL,
    @SortColumn NVARCHAR(50) = 'product_name'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    SELECT product_id, product_name, list_price, category_id 
    FROM production.products
    WHERE 1 = 1';

    IF @NameTerm IS NOT NULL
        SET @SQL += ' AND product_name LIKE ''%' + @NameTerm + '%''';

    IF @CategoryId IS NOT NULL
        SET @SQL += ' AND category_id = ' + CAST(@CategoryId AS VARCHAR);

    IF @MinPrice IS NOT NULL
        SET @SQL += ' AND list_price >= ' + CAST(@MinPrice AS VARCHAR);

    IF @MaxPrice IS NOT NULL
        SET @SQL += ' AND list_price <= ' + CAST(@MaxPrice AS VARCHAR);

    SET @SQL += ' ORDER BY ' + QUOTENAME(@SortColumn);

    EXEC sp_executesql @SQL;
END;




--17. Staff Bonus Calculation System#
--Create a complete solution that calculates quarterly bonuses for all staff members. Use variables to store date ranges and bonus rates. Apply different bonus percentages based on sales performance tiers.

DECLARE @StartDate DATE = '2017-01-01';
DECLARE @EndDate DATE = '2017-03-31';

SELECT 
    s.staff_id,
    s.first_name,
    s.last_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 50000 THEN '20%'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 25000 THEN '10%'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN '5%'
        ELSE '0%'
    END AS bonus_percentage
FROM 
    sales.staffs s
JOIN 
    sales.orders o ON s.staff_id = o.staff_id
JOIN 
    sales.order_items oi ON o.order_id = oi.order_id
WHERE 
    o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY 
    s.staff_id, s.first_name, s.last_name;



--	18. Smart Inventory Management#
--Write a complex query with nested IF statements that manages inventory restocking. Check current stock levels and apply different reorder quantities based on product categories and current stock levels.

SELECT 
    s.product_id,
    p.category_id,
    s.quantity,
    CASE 
        WHEN s.quantity < 5 AND p.category_id = 1 THEN 'Reorder 20 units'
        WHEN s.quantity < 5 AND p.category_id = 2 THEN 'Reorder 15 units'
        WHEN s.quantity BETWEEN 5 AND 10 THEN 'Monitor Stock'
        ELSE 'Stock OK'
    END AS restock_action
FROM 
    production.stocks s
JOIN 
    production.products p ON s.product_id = p.product_id;




--	19. Customer Loyalty Tier Assignment#
--Create a comprehensive solution that assigns loyalty tiers to customers based on their total spending. Handle customers with no orders appropriately and use proper NULL checking.

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS total_spent,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) IS NULL THEN 'No Orders'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN 'Platinum'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 5000 THEN 'Gold'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier
FROM 
    sales.customers c
LEFT JOIN 
    sales.orders o ON c.customer_id = o.customer_id
LEFT JOIN 
    sales.order_items oi ON o.order_id = oi.order_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name;



--	20. Product Lifecycle Management#
--Write a stored procedure that handles product discontinuation including checking for pending orders, optional product replacement in existing orders, clearing inventory, and providing detailed status messages.


CREATE PROCEDURE sp_DiscontinueProduct
    @ProductId INT,
    @ReplacementProductId INT = NULL
AS
BEGIN
    -- التحقق من وجود طلبات نشطة للمنتج
    IF EXISTS (
        SELECT 1
        FROM sales.order_items oi
        JOIN sales.orders o ON oi.order_id = o.order_id
        WHERE oi.product_id = @ProductId
          AND o.order_status IN (1, 2) -- غير مكتملة
    )
    BEGIN
        PRINT ' Cannot discontinue product. It has pending or processing orders.';
        RETURN;
    END

    -- إذا في منتج بديل
    IF @ReplacementProductId IS NOT NULL
    BEGIN
        UPDATE sales.order_items
        SET product_id = @ReplacementProductId
        WHERE product_id = @ProductId;

        PRINT ' Product replaced in existing orders.';
    END

    -- حذف من المخزون
    DELETE FROM production.stocks 
    WHERE product_id = @ProductId;

    PRINT ' Product discontinued successfully.';
END;



