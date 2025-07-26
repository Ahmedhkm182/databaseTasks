-- Customer activity log
CREATE TABLE sales.customer_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    action VARCHAR(50),
    log_date DATETIME DEFAULT GETDATE()
);

-- Price history tracking
CREATE TABLE production.price_history (
    history_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date DATETIME DEFAULT GETDATE(),
    changed_by VARCHAR(100)
);

-- Order audit trail
CREATE TABLE sales.order_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    customer_id INT,
    store_id INT,
    staff_id INT,
    order_date DATE,
    audit_timestamp DATETIME DEFAULT GETDATE()
);

---1----
CREATE NONCLUSTERED INDEX idx_customer_email
ON Sales.Customer (EmailAddress);


---2----
CREATE NONCLUSTERED INDEX idx_product_category_brand
ON Production.Product (ProductSubcategoryID, ProductModelID);


----3----
CREATE NONCLUSTERED INDEX idx_order_date
ON Sales.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID, Status);


----4----
CREATE TRIGGER trg_after_insert_customer
ON Sales.Customer
AFTER INSERT
AS
BEGIN
    INSERT INTO Sales.customer_log (customer_id, action)
    SELECT CustomerID, 'Welcome New Customer'
    FROM inserted;
END;


---5----
CREATE TRIGGER trg_price_change
ON Production.Product
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ListPrice)
    BEGIN
        INSERT INTO Production.price_history (product_id, old_price, new_price, changed_by)
        SELECT
            i.ProductID,
            d.ListPrice,
            i.ListPrice,
            SYSTEM_USER
        FROM inserted i
        JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.ListPrice <> d.ListPrice;
    END
END;



---6----
CREATE TRIGGER trg_prevent_category_delete
ON Production.ProductSubcategory
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Production.Product p
        JOIN deleted d ON p.ProductSubcategoryID = d.ProductSubcategoryID
    )
    BEGIN
        RAISERROR('Cannot delete category with associated products.', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        DELETE FROM Production.ProductSubcategory
        WHERE ProductSubcategoryID IN (SELECT ProductSubcategoryID FROM deleted);
    END
END;

----7----
CREATE TRIGGER trg_reduce_stock
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    UPDATE pi
    SET pi.Quantity = pi.Quantity - i.OrderQty
    FROM Production.ProductInventory pi
    JOIN inserted i ON pi.ProductID = i.ProductID
    WHERE pi.Quantity >= i.OrderQty;
END;


----8----
CREATE TRIGGER trg_log_new_order
ON Sales.SalesOrderHeader
AFTER INSERT
AS
BEGIN
    INSERT INTO Sales.order_audit (order_id, customer_id, staff_id, order_date)
    SELECT
        SalesOrderID,
        CustomerID,
        SalesPersonID, 
        OrderDate
    FROM inserted;
END;
