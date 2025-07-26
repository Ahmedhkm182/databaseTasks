--1.1
SELECT 
    e.BusinessEntityID AS EmployeeID,
    p.FirstName,
    p.LastName,
    e.HireDate
FROM 
    HumanResources.Employee e
JOIN 
    Person.Person p
    ON e.BusinessEntityID = p.BusinessEntityID
WHERE 
    e.HireDate > '2012-01-01'
ORDER BY 
    e.HireDate DESC;




	-------1.2-----
	SELECT 
    ProductID,
    [Name],
    ListPrice,
    ProductNumber
FROM 
    Production.Product
WHERE 
    ListPrice BETWEEN 100 AND 500
ORDER BY 
    ListPrice ASC;




	--1.3--


	SELECT 
    c.CustomerID,
    p.FirstName,
    p.LastName,
    a.City
FROM 
    Sales.Customer c
JOIN 
    Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN 
    Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
JOIN 
    Person.Address a ON bea.AddressID = a.AddressID
WHERE 
    a.City IN ('Seattle', 'Portland');



	-----1.4-----
SELECT TOP 15
    p.Name AS ProductName,
    p.ListPrice,
    p.ProductNumber,
    pc.Name AS CategoryName
FROM 
    Production.Product p
JOIN 
    Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory  pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE 
    p.ListPrice > 0
    AND p.SellEndDate IS NULL 
ORDER BY 
    p.ListPrice DESC;

	-------2.1-------

SELECT 
    ProductID,
    Name,
    Color,
    ListPrice
FROM 
    Production.Product
WHERE 
    Name LIKE '%Mountain%'
    AND Color = 'Black';




    ------2.2----
SELECT 
    p.FirstName + ' ' + p.LastName AS FullName,
    e.BirthDate,
    DATEDIFF(YEAR, e.BirthDate, GETDATE()) AS AgeInYears
FROM 
    HumanResources.Employee e
JOIN 
    Person.Person AS p
    ON e.BusinessEntityID = p.BusinessEntityID
WHERE 
    e.BirthDate BETWEEN '1970-01-01' AND '1985-12-31'
ORDER BY 
    e.BirthDate;


	-----3.1------
	SELECT 
    pc.Name AS CategoryName,
    COUNT(p.ProductID) AS ProductCount
FROM 
    Production.Product p
JOIN 
    Production.ProductSubcategory  ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory  pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    pc.Name
ORDER BY 
    ProductCount DESC;


	----3.2----

SELECT 
    ps.Name AS SubcategoryName,
    AVG(p.ListPrice) AS AvgListPrice,
    COUNT(p.ProductID) AS ProductCount
FROM 
    Production.Product AS p
JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
GROUP BY 
    ps.Name
HAVING 
    COUNT(p.ProductID) > 5
ORDER BY 
    AvgListPrice DESC;




	---3.3-----
	SELECT TOP 10
    c.CustomerID,
    COALESCE(p.FirstName + ' ' + p.LastName, c.CompanyName) AS CustomerName,
    COUNT(soh.SalesOrderID) AS TotalOrders
FROM 
    Sales.Customer AS c
JOIN 
    Sales.SalesOrderHeader AS soh
        ON c.CustomerID = soh.CustomerID
LEFT JOIN 
    Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
GROUP BY 
    c.CustomerID, p.FirstName, p.LastName, c.CompanyName
ORDER BY 
    TotalOrders DESC;


	----3.4-----
	SELECT 
    DATENAME(MONTH, OrderDate) AS MonthName,
    SUM(TotalDue) AS TotalSales
FROM 
    Sales.SalesOrderHeader
WHERE 
    YEAR(OrderDate) = 2013
GROUP BY 
    MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY 
    MONTH(OrderDate);




	------4.1------
	SELECT 
    ProductID,
    Name,
    SellStartDate,
    YEAR(SellStartDate) AS LaunchYear
FROM 
    Production.Product
WHERE 
    YEAR(SellStartDate) = (
        SELECT YEAR(SellStartDate)
        FROM Production.Product
        WHERE Name = 'Mountain-100 Black, 42'
    );




	------4.2-------
	SELECT 
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    e.HireDate,
    c.HireCount
FROM 
    HumanResources.Employee e
JOIN 
    Person.Person p 
        ON e.BusinessEntityID = p.BusinessEntityID
JOIN (
    SELECT HireDate, COUNT(*) AS HireCount
    FROM HumanResources.Employee
    GROUP BY HireDate
    HAVING COUNT(*) > 1
) AS c
    ON e.HireDate = c.HireDate
ORDER BY 
    e.HireDate, EmployeeName;




	-----5.1------
	CREATE TABLE Sales.ProductReviews
(
    ReviewID INT IDENTITY(1,1) PRIMARY KEY, 
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),  
    ReviewDate DATE NOT NULL DEFAULT (GETDATE()),             
    ReviewText NVARCHAR(2000) NULL,                          
    VerifiedPurchase BIT NOT NULL DEFAULT (0),               
    HelpfulVotes INT NOT NULL DEFAULT (0) CHECK (HelpfulVotes >= 0),

   
    CONSTRAINT UQ_Product_Customer UNIQUE (ProductID, CustomerID),

   
    CONSTRAINT FK_ProductReviews_Product FOREIGN KEY (ProductID)
        REFERENCES Production.Product(ProductID),
    CONSTRAINT FK_ProductReviews_Customer FOREIGN KEY (CustomerID)
        REFERENCES Sales.Customer(CustomerID)
);


------6.1------
ALTER TABLE Production.Product
ADD LastModifiedDate DATETIME NOT NULL DEFAULT (GETDATE());


-----6.2-----
CREATE NONCLUSTERED INDEX IX_Person_LastName
ON Person.Person (LastName)
INCLUDE (FirstName, MiddleName);


------6.3------
ALTER TABLE Production.Product
ADD CONSTRAINT CK_Product_ListPrice_StandardCost
CHECK (ListPrice > StandardCost);

-----7.1--------
INSERT INTO Sales.ProductReviews (ProductID, CustomerID, Rating, ReviewText, VerifiedPurchase, HelpfulVotes)
VALUES
(680, 30001, 5, N'Excellent quality and very durable product. Highly recommended!', 1, 10),
(707, 30002, 4, N'Good product, but the packaging could be better.', 1, 4),
(712, 30003, 3, N'Average quality, not as expected for the price.', 0, 2);


------7.2------

INSERT INTO Production.ProductCategory (Name)
VALUES ('Electronics');


INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name)
VALUES (SCOPE_IDENTITY(), 'Smartphones');


-----7.3-----
CREATE TABLE Sales.DiscontinuedProducts
(
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(50),
    ProductNumber NVARCHAR(25),
    Color NVARCHAR(15),
    StandardCost MONEY,
    ListPrice MONEY,
    SellStartDate DATE,
    SellEndDate DATE
);

INSERT INTO Sales.DiscontinuedProducts (ProductID, Name, ProductNumber, Color, StandardCost, ListPrice, SellStartDate, SellEndDate)
SELECT 
    ProductID,
    Name,
    ProductNumber,
    Color,
    StandardCost,
    ListPrice,
    SellStartDate,
    SellEndDate
FROM 
    Production.Product
WHERE 
    SellEndDate IS NOT NULL;



	-------8.1------
	UPDATE Production.Product
SET ModifiedDate = GETDATE()
WHERE ListPrice > 1000
  AND SellEndDate IS NULL;


  -------8.2-------
  UPDATE p
SET 
    p.ListPrice = p.ListPrice * 1.15,
    p.ModifiedDate = GETDATE()
FROM 
    Production.Product AS p
JOIN 
    Production.ProductSubcategory AS ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory AS pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE 
    pc.Name = 'Bikes';


	-------8.3--------
	UPDATE HumanResources.Employee
SET JobTitle = 'Senior ' + JobTitle
WHERE HireDate < '2010-01-01';



-----9.1------
DELETE FROM Sales.ProductReviews
WHERE Rating = 1
  AND HelpfulVotes = 0;



  -----9.2------
DELETE FROM Production.Product
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.SalesOrderDetail AS sod
    WHERE sod.ProductID = Production.Product.ProductID
);


----9.3------
DELETE poh
FROM Purchasing.PurchaseOrderHeader AS poh
JOIN Purchasing.Vendor AS v
    ON poh.VendorID = v.BusinessEntityID
WHERE v.ActiveFlag = 0;  


--------10.1------
SELECT 
    YEAR(OrderDate) AS SalesYear,
    SUM(TotalDue) AS TotalSales,
    AVG(TotalDue) AS AvgOrderValue,
    COUNT(SalesOrderID) AS OrderCount
FROM 
    Sales.SalesOrderHeader
WHERE 
    YEAR(OrderDate) BETWEEN 2011 AND 2014
GROUP BY 
    YEAR(OrderDate)
ORDER BY 
    SalesYear;



	-------10.2-------
	SELECT 
    c.CustomerID,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    SUM(soh.TotalDue) AS TotalAmount,
    AVG(soh.TotalDue) AS AvgOrderValue,
    MIN(soh.OrderDate) AS FirstOrderDate,
    MAX(soh.OrderDate) AS LastOrderDate
FROM 
    Sales.Customer AS c
JOIN 
    Sales.SalesOrderHeader AS soh
        ON c.CustomerID = soh.CustomerID
GROUP BY 
    c.CustomerID
ORDER BY 
    TotalAmount DESC;


---------10.3---------
SELECT TOP 20
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    SUM(sod.OrderQty) AS TotalQuantitySold,
    SUM(sod.LineTotal) AS TotalRevenue
FROM 
    Sales.SalesOrderDetail AS sod
JOIN 
    Production.Product AS p
        ON sod.ProductID = p.ProductID
LEFT JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.Name, pc.Name
ORDER BY 
    TotalRevenue DESC;



	---12.1----------
	SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    ps.Name AS SubcategoryName,
    v.Name AS VendorName
FROM 
    Production.Product AS p
JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
JOIN 
    Purchasing.ProductVendor AS pv
        ON p.ProductID = pv.ProductID
JOIN 
    Purchasing.Vendor AS v
        ON pv.BusinessEntityID = v.BusinessEntityID
ORDER BY 
    CategoryName, SubcategoryName, ProductName;




	------12.2-------
	SELECT 
    soh.SalesOrderID,
    COALESCE(custPerson.FirstName + ' ' + custPerson.LastName, c.CompanyName) AS CustomerName,
    sp.FirstName + ' ' + sp.LastName AS SalesPersonName,
    st.Name AS TerritoryName,
    p.Name AS ProductName,
    sod.OrderQty,
    sod.LineTotal
FROM 
    Sales.SalesOrderHeader AS soh
JOIN 
    Sales.Customer AS c
        ON soh.CustomerID = c.CustomerID
LEFT JOIN 
    Person.Person AS custPerson
        ON c.PersonID = custPerson.BusinessEntityID
LEFT JOIN 
    Person.Person AS sp
        ON soh.SalesPersonID = sp.BusinessEntityID
JOIN 
    Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
JOIN 
    Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    Production.Product AS p
        ON sod.ProductID = p.ProductID
ORDER BY 
    soh.SalesOrderID;




	--------12.3-------

	SELECT 
    pp.FirstName + ' ' + pp.LastName AS EmployeeName,
    e.JobTitle,
    st.Name AS TerritoryName,
    st.[Group] AS TerritoryGroup,
    sp.SalesYTD
FROM 
    HumanResources.Employee AS e
JOIN 
    Person.Person AS pp
        ON e.BusinessEntityID = pp.BusinessEntityID
JOIN 
    Sales.SalesPerson AS sp
        ON e.BusinessEntityID = sp.BusinessEntityID
JOIN 
    Sales.SalesTerritory AS st
        ON sp.TerritoryID = st.TerritoryID
ORDER BY 
    EmployeeName;



----13.1------
SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    ISNULL(SUM(sod.OrderQty), 0) AS TotalQuantitySold,
    ISNULL(SUM(sod.LineTotal), 0) AS TotalRevenue
FROM 
    Production.Product AS p
LEFT JOIN 
    Sales.SalesOrderDetail AS sod
    ON p.ProductID = sod.ProductID
LEFT JOIN 
    Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN 
    Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.Name, pc.Name
ORDER BY 
    TotalRevenue DESC;

	--------13.2------
	SELECT 
    st.Name AS TerritoryName,
    pp.FirstName + ' ' + pp.LastName AS EmployeeName,
    sp.SalesYTD
FROM 
    Sales.SalesTerritory AS st
LEFT JOIN 
    Sales.SalesPerson AS sp
        ON st.TerritoryID = sp.TerritoryID
LEFT JOIN 
    Person.Person AS pp
        ON sp.BusinessEntityID = pp.BusinessEntityID
ORDER BY 
    TerritoryName, EmployeeName;



	------13.3--------
	SELECT 
    v.Name AS VendorName,
    pc.Name AS CategoryName
FROM 
    Purchasing.Vendor AS v
FULL OUTER JOIN 
    Purchasing.ProductVendor AS pv
        ON v.BusinessEntityID = pv.BusinessEntityID
FULL OUTER JOIN 
    Production.Product AS p
        ON pv.ProductID = p.ProductID
FULL OUTER JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
FULL OUTER JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
ORDER BY 
    VendorName, CategoryName;




-----14.1-------
SELECT 
    ProductID,
    Name,
    ListPrice,
    ListPrice - (SELECT AVG(ListPrice) FROM Production.Product) AS PriceDifference
FROM 
    Production.Product
WHERE 
    ListPrice > (SELECT AVG(ListPrice) FROM Production.Product)
ORDER BY 
    ListPrice DESC;




	--------14.2--------
	SELECT 
    COALESCE(pp.FirstName + ' ' + pp.LastName, c.CompanyName) AS CustomerName,
    COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
    SUM(sod.LineTotal) AS TotalAmountSpent
FROM 
    Sales.Customer AS c
JOIN 
    Sales.SalesOrderHeader AS soh
        ON c.CustomerID = soh.CustomerID
JOIN 
    Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    Production.Product AS p
        ON sod.ProductID = p.ProductID
JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN 
    Person.Person AS pp
        ON c.PersonID = pp.BusinessEntityID
WHERE 
    pc.Name = 'Mountain'
GROUP BY 
    pp.FirstName, pp.LastName, c.CompanyName
ORDER BY 
    TotalAmountSpent DESC;





	----14.3------
	SELECT 
    p.Name AS ProductName,
    pc.Name AS CategoryName,
    COUNT(DISTINCT soh.CustomerID) AS UniqueCustomerCount
FROM 
    Production.Product AS p
JOIN 
    Sales.SalesOrderDetail AS sod
        ON p.ProductID = sod.ProductID
JOIN 
    Sales.SalesOrderHeader AS soh
        ON sod.SalesOrderID = soh.SalesOrderID
LEFT JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.Name, pc.Name
HAVING 
    COUNT(DISTINCT soh.CustomerID) > 100
ORDER BY 
    UniqueCustomerCount DESC;



	-----15.1-----
	CREATE VIEW vw_ProductCatalog AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    pc.Name AS CategoryName,
    ps.Name AS SubcategoryName,
    p.ListPrice,
    p.StandardCost,
    CASE 
        WHEN p.ListPrice > 0 
        THEN ROUND(((p.ListPrice - p.StandardCost) / p.ListPrice) * 100, 2)
        ELSE 0
    END AS ProfitMarginPercentage,
    ISNULL(pi.Quantity, 0) AS InventoryLevel,
    CASE 
        WHEN p.SellEndDate IS NULL THEN 'Active'
        ELSE 'Discontinued'
    END AS Status
FROM 
    Production.Product AS p
LEFT JOIN 
    Production.ProductSubcategory AS ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN 
    Production.ProductCategory AS pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
LEFT JOIN 
    Production.ProductInventory AS pi
        ON p.ProductID = pi.ProductID;



		----15.2------
		CREATE VIEW vw_SalesAnalysis AS
WITH MonthlySales AS (
    SELECT 
        YEAR(soh.OrderDate) AS SalesYear,
        MONTH(soh.OrderDate) AS SalesMonth,
        st.Name AS Territory,
        SUM(soh.TotalDue) AS TotalSales,
        COUNT(DISTINCT soh.SalesOrderID) AS OrderCount,
        AVG(soh.TotalDue) AS AvgOrderValue
    FROM 
        Sales.SalesOrderHeader AS soh
    JOIN 
        Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY 
        YEAR(soh.OrderDate),
        MONTH(soh.OrderDate),
        st.Name
),
TopProduct AS (
    SELECT 
        YEAR(soh.OrderDate) AS SalesYear,
        MONTH(soh.OrderDate) AS SalesMonth,
        st.Name AS Territory,
        p.Name AS TopProduct,
        ROW_NUMBER() OVER (PARTITION BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), st.Name ORDER BY SUM(sod.LineTotal) DESC) AS rn
    FROM 
        Sales.SalesOrderHeader AS soh
    JOIN 
        Sales.SalesOrderDetail AS sod
        ON soh.SalesOrderID = sod.SalesOrderID
    JOIN 
        Production.Product AS p
        ON sod.ProductID = p.ProductID
    JOIN 
        Sales.SalesTerritory AS st
        ON soh.TerritoryID = st.TerritoryID
    GROUP BY 
        YEAR(soh.OrderDate),
        MONTH(soh.OrderDate),
        st.Name,
        p.Name
)
SELECT 
    ms.SalesYear,
    ms.SalesMonth,
    ms.Territory,
    ms.TotalSales,
    ms.OrderCount,
    ms.AvgOrderValue,
    tp.TopProduct
FROM 
    MonthlySales ms
LEFT JOIN 
    TopProduct tp
        ON ms.SalesYear = tp.SalesYear
        AND ms.SalesMonth = tp.SalesMonth
        AND ms.Territory = tp.Territory
        AND tp.rn = 1;



		-----15.3-----
		CREATE VIEW vw_EmployeeDirectory AS
SELECT 
    p.FirstName + ' ' + ISNULL(p.MiddleName + ' ', '') + p.LastName AS FullName,
    e.JobTitle,
    d.Name AS Department,
    mgr.FirstName + ' ' + mgr.LastName AS ManagerName,
    e.HireDate,
    DATEDIFF(YEAR, e.HireDate, GETDATE()) AS YearsOfService,
    ea.EmailAddress,
    ph.PhoneNumber
FROM 
    HumanResources.Employee AS e
JOIN 
    Person.Person AS p
        ON e.BusinessEntityID = p.BusinessEntityID
JOIN 
    HumanResources.EmployeeDepartmentHistory AS edh
        ON e.BusinessEntityID = edh.BusinessEntityID
JOIN 
    HumanResources.Department AS d
        ON edh.DepartmentID = d.DepartmentID
LEFT JOIN 
    HumanResources.Employee AS m
        ON e.BusinessEntityID = m.BusinessEntityID
LEFT JOIN 
    Person.Person AS mgr
        ON m.BusinessEntityID = mgr.BusinessEntityID
LEFT JOIN 
    Person.EmailAddress AS ea
        ON p.BusinessEntityID = ea.BusinessEntityID
LEFT JOIN 
    Person.PersonPhone AS ph
        ON p.BusinessEntityID = ph.BusinessEntityID
WHERE 
    edh.EndDate IS NULL;

	-------15.4--------
	SELECT ProductID, ProductName, ListPrice, ProfitMarginPercentage
FROM vw_ProductCatalog
WHERE ProfitMarginPercentage > 30
ORDER BY ProfitMarginPercentage DESC;



SELECT SalesYear, SalesMonth, Territory, TotalSales, TopProduct
FROM vw_SalesAnalysis
WHERE SalesYear = 2013 AND Territory = 'Northwest'
ORDER BY SalesMonth;



SELECT FullName, JobTitle, Department, YearsOfService, ManagerName
FROM vw_EmployeeDirectory
WHERE YearsOfService > 10
ORDER BY YearsOfService DESC;


-------16.1------
SELECT 
    CASE
        WHEN ListPrice > 500 THEN 'Premium'
        WHEN ListPrice BETWEEN 100 AND 500 THEN 'Standard'
        ELSE 'Budget'
    END AS PriceCategory,
    COUNT(*) AS ProductCount,
    AVG(ListPrice) AS AvgPrice
FROM 
    Production.Product
WHERE 
    ListPrice > 0
GROUP BY 
    CASE
        WHEN ListPrice > 500 THEN 'Premium'
        WHEN ListPrice BETWEEN 100 AND 500 THEN 'Standard'
        ELSE 'Budget'
    END
ORDER BY 
    AvgPrice DESC;



	-----16.2-----
	SELECT 
    CASE
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 10 THEN 'Veteran'
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 5 THEN 'Experienced'
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 2 THEN 'Regular'
        ELSE 'New'
    END AS ServiceCategory,
    COUNT(*) AS EmployeeCount,
    MIN(eph.Rate) AS MinSalary,
    MAX(eph.Rate) AS MaxSalary,
    AVG(eph.Rate) AS AvgSalary
FROM 
    HumanResources.Employee AS e
JOIN 
    HumanResources.EmployeePayHistory AS eph
        ON e.BusinessEntityID = eph.BusinessEntityID
GROUP BY 
    CASE
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 10 THEN 'Veteran'
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 5 THEN 'Experienced'
        WHEN DATEDIFF(YEAR, e.HireDate, GETDATE()) >= 2 THEN 'Regular'
        ELSE 'New'
    END
ORDER BY 
    AvgSalary DESC;




	------16.3-------
	WITH OrderClass AS (
    SELECT 
        CASE
            WHEN TotalDue > 5000 THEN 'Large'
            WHEN TotalDue BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Small'
        END AS OrderSize
    FROM 
        Sales.SalesOrderHeader
)
SELECT 
    OrderSize,
    COUNT(*) AS OrderCount,
    CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM OrderClass) AS DECIMAL(5,2)) AS Percentage
FROM 
    OrderClass
GROUP BY 
    OrderSize
ORDER BY 
    Percentage DESC;




	-----17.1-----
	SELECT 
    Name AS ProductName,
    ISNULL(CAST(Weight AS VARCHAR), 'Not Specified') AS Weight,
    ISNULL(Size, 'Standard') AS Size,
    ISNULL(Color, 'Natural') AS Color
FROM 
    Production.Product;


	-----17.2-----
	SELECT 
    c.CustomerID,
    COALESCE(ea.EmailAddress, ph.PhoneNumber, a.AddressLine1) AS BestContactMethod
FROM 
    Sales.Customer AS c
LEFT JOIN 
    Person.Person AS p
        ON c.PersonID = p.BusinessEntityID
LEFT JOIN 
    Person.EmailAddress AS ea
        ON p.BusinessEntityID = ea.BusinessEntityID
LEFT JOIN 
    Person.PersonPhone AS ph
        ON p.BusinessEntityID = ph.BusinessEntityID
LEFT JOIN 
    Person.BusinessEntityAddress AS bea
        ON p.BusinessEntityID = bea.BusinessEntityID
LEFT JOIN 
    Person.Address AS a
        ON bea.AddressID = a.AddressID;




		-----17.3------
		
SELECT ProductID, Name, Size, Weight
FROM Production.Product
WHERE Weight IS NULL AND Size IS NOT NULL;


SELECT ProductID, Name, Size, Weight
FROM Production.Product
WHERE Weight IS NULL AND Size IS NULL;

   ----19.1---
   SELECT 
    c.Name AS Category,
    p.Name AS Product,
    SUM(od.LineTotal) AS SalesAmount,
    RANK() OVER (PARTITION BY c.Name ORDER BY SUM(od.LineTotal) DESC) AS SalesRank,
    DENSE_RANK() OVER (PARTITION BY c.Name ORDER BY SUM(od.LineTotal) DESC) AS DenseRank,
    ROW_NUMBER() OVER (PARTITION BY c.Name ORDER BY SUM(od.LineTotal) DESC) AS RowNum
FROM 
    Sales.SalesOrderDetail od
JOIN 
    Production.Product p ON od.ProductID = p.ProductID
JOIN 
    Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN 
    Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
GROUP BY 
    c.Name, p.Name;


	----19.2----
	WITH MonthlySales AS (
    SELECT 
        FORMAT(OrderDate, 'yyyy-MM') AS Month,
        SUM(TotalDue) AS MonthlyTotal
    FROM 
        Sales.SalesOrderHeader
    WHERE 
        YEAR(OrderDate) = 2013
    GROUP BY 
        FORMAT(OrderDate, 'yyyy-MM')
)
SELECT 
    Month,
    MonthlyTotal,
    SUM(MonthlyTotal) OVER (ORDER BY Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal,
    ROUND(
        100.0 * SUM(MonthlyTotal) OVER (ORDER BY Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
        / SUM(MonthlyTotal) OVER (), 2
    ) AS YTDPercentage
FROM 
    MonthlySales;


	----19.3----
	WITH TerritorySales AS (
    SELECT 
        t.Name AS Territory,
        FORMAT(h.OrderDate, 'yyyy-MM') AS Month,
        SUM(h.TotalDue) AS Sales
    FROM 
        Sales.SalesOrderHeader h
    JOIN 
        Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
    GROUP BY 
        t.Name, FORMAT(h.OrderDate, 'yyyy-MM')
)
SELECT 
    Territory,
    Month,
    Sales,
    ROUND(
        AVG(Sales) OVER (
            PARTITION BY Territory 
            ORDER BY Month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS MovingAverage
FROM 
    TerritorySales;


	---19.4----
	WITH MonthlySales AS (
    SELECT 
        FORMAT(OrderDate, 'yyyy-MM') AS Month,
        SUM(TotalDue) AS Sales
    FROM 
        Sales.SalesOrderHeader
    GROUP BY 
        FORMAT(OrderDate, 'yyyy-MM')
)
SELECT 
    Month,
    Sales,
    LAG(Sales) OVER (ORDER BY Month) AS PreviousMonthSales,
    Sales - LAG(Sales) OVER (ORDER BY Month) AS GrowthAmount,
    ROUND(
        100.0 * (Sales - LAG(Sales) OVER (ORDER BY Month)) / NULLIF(LAG(Sales) OVER (ORDER BY Month), 0), 
        2
    ) AS GrowthPercentage
FROM 
    MonthlySales;



	---19.5----
	WITH CustomerPurchases AS (
    SELECT 
        c.CustomerID,
        p.FirstName + ' ' + p.LastName AS CustomerName,
        SUM(h.TotalDue) AS TotalPurchases
    FROM 
        Sales.Customer c
    JOIN 
        Sales.SalesOrderHeader h ON c.CustomerID = h.CustomerID
    JOIN 
        Person.Person p ON c.PersonID = p.BusinessEntityID
    GROUP BY 
        c.CustomerID, p.FirstName, p.LastName
),
Quartiles AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY TotalPurchases DESC) AS Quartile
    FROM 
        CustomerPurchases
)
SELECT 
    CustomerName,
    TotalPurchases,
    Quartile,
    AVG(TotalPurchases) OVER (PARTITION BY Quartile) AS QuartileAverage
FROM 
    Quartiles;



    -----20.1-------
	SELECT 
    category_name,
    ISNULL([2011], 0) AS [2011],
    ISNULL([2012], 0) AS [2012],
    ISNULL([2013], 0) AS [2013],
    ISNULL([2014], 0) AS [2014],
    ISNULL([2011],0) + ISNULL([2012],0) + ISNULL([2013],0) + ISNULL([2014],0) AS Total
FROM (
    SELECT 
        c.Name AS category_name,
        YEAR(h.OrderDate) AS order_year,
        d.LineTotal
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
    JOIN Production.Product p ON d.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
    WHERE YEAR(h.OrderDate) BETWEEN 2011 AND 2014
) AS src
PIVOT (
    SUM(LineTotal) FOR order_year IN ([2011], [2012], [2013], [2014])
) AS pvt;



  ----20.2----
SELECT 
    Department,
    ISNULL([M], 0) AS Male,
    ISNULL([F], 0) AS Female
FROM (
    SELECT 
        e.Gender,
        dept.Name AS Department
    FROM HumanResources.Employee e
    JOIN HumanResources.EmployeeDepartmentHistory edh 
        ON e.BusinessEntityID = edh.BusinessEntityID
    JOIN HumanResources.Department dept 
        ON edh.DepartmentID = dept.DepartmentID
    WHERE edh.EndDate IS NULL 
) AS src
PIVOT (
    COUNT(Gender) FOR Gender IN ([M], [F])
) AS pivot_table;



 ----20.3----
 DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);


SELECT @columns = STRING_AGG(QUOTENAME(QuarterYear), ', ')
FROM (
    SELECT DISTINCT 
        'Q' + CAST(DATEPART(QUARTER, OrderDate) AS VARCHAR) + '_' + CAST(YEAR(OrderDate) AS VARCHAR) AS QuarterYear
    FROM Sales.SalesOrderHeader
) AS q;


SET @sql = '
SELECT CustomerID, ' + @columns + '
FROM (
    SELECT 
        CustomerID,
        ''Q'' + CAST(DATEPART(QUARTER, OrderDate) AS VARCHAR) + ''_'' + CAST(YEAR(OrderDate) AS VARCHAR) AS QuarterYear,
        TotalDue
    FROM Sales.SalesOrderHeader
) AS src
PIVOT (
    SUM(TotalDue) FOR QuarterYear IN (' + @columns + ')
) AS pvt;';


EXEC sp_executesql @sql;


----22.1----
DECLARE @CurrentYear INT = YEAR(GETDATE());
DECLARE @TotalSales MONEY;
DECLARE @AvgOrderValue MONEY;

SELECT 
    @TotalSales = SUM(TotalDue),
    @AvgOrderValue = AVG(TotalDue)
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = @CurrentYear;

PRINT 'Year: ' + CAST(@CurrentYear AS VARCHAR(4));
PRINT 'Total Sales: $' + CAST(@TotalSales AS VARCHAR(20));
PRINT 'Average Order Value: $' + CAST(@AvgOrderValue AS VARCHAR(20));


----22.2----
DECLARE @ProductID INT = 707;  

IF EXISTS (
    SELECT 1 FROM Production.ProductInventory WHERE ProductID = @ProductID AND Quantity > 0
)
BEGIN
    SELECT ProductID, Quantity FROM Production.ProductInventory WHERE ProductID = @ProductID;
END
ELSE
BEGIN
    PRINT 'Product not in stock. Suggesting alternatives:';
    SELECT TOP 5 p.ProductID, p.Name, i.Quantity
    FROM Production.Product p
    JOIN Production.ProductInventory i ON p.ProductID = i.ProductID
    WHERE p.ProductID <> @ProductID AND i.Quantity > 0;
END;


----22.3----
DECLARE @Month INT = 1;

WHILE @Month <= 12
BEGIN
    DECLARE @StartDate DATE = DATEFROMPARTS(2013, @Month, 1);
    DECLARE @EndDate DATE = EOMONTH(@StartDate);

    PRINT 'Month: ' + DATENAME(MONTH, @StartDate);

    SELECT 
        SUM(TotalDue) AS MonthlySales
    FROM Sales.SalesOrderHeader
    WHERE OrderDate BETWEEN @StartDate AND @EndDate;

    SET @Month += 1;
END;



---22.4---
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ProductID INT = 707;
    DECLARE @NewPrice MONEY = 550.00;

   
    DECLARE @OldPrice MONEY;
    SELECT @OldPrice = ListPrice FROM Production.Product WHERE ProductID = @ProductID;

   
    UPDATE Production.Product
    SET ListPrice = @NewPrice
    WHERE ProductID = @ProductID;

    
    INSERT INTO production.price_history (product_id, old_price, new_price, changed_by)
    VALUES (@ProductID, @OldPrice, @NewPrice, SYSTEM_USER);

    COMMIT TRANSACTION;
    PRINT 'Price updated successfully.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;



----23.1----
CREATE FUNCTION dbo.fn_CustomerLifetimeValue (
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE,
    @ActivityWeight FLOAT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @TotalSpent FLOAT = 0;
    DECLARE @RecentActivityWeight FLOAT = 0;

 
    SELECT @TotalSpent = SUM(TotalDue)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID AND OrderDate BETWEEN @StartDate AND @EndDate;

   
    SELECT @RecentActivityWeight = COUNT(*)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID AND OrderDate >= DATEADD(MONTH, -3, @EndDate);

    RETURN ISNULL(@TotalSpent, 0) + (@RecentActivityWeight * @ActivityWeight);
END;



-----23.2----
CREATE FUNCTION dbo.fn_GetProductsByRangeAndCategory (
    @MinPrice decimal(10,2),
    @MaxPrice decimal(10,2),
    @CategoryID INT
)
RETURNS @Products TABLE (
    ProductID INT,
    Name NVARCHAR(100),
    ListPrice decimal(10,2),
    CategoryID INT
)
AS
BEGIN
    IF @MinPrice < 0 OR @MaxPrice < 0 OR @MinPrice > @MaxPrice
    BEGIN
        RETURN;  -- تجاهل القيم غير الصالحة
    END

    INSERT INTO @Products
    SELECT ProductID, Name, ListPrice, ProductSubcategoryID
    FROM Production.Product
    WHERE ListPrice BETWEEN @MinPrice AND @MaxPrice
      AND ProductSubcategoryID = @CategoryID;

    RETURN;
END;



----23.3----


---24.1---
CREATE PROCEDURE dbo.sp_GetProductsByCategory
    @CategoryName NVARCHAR(100),
    @MinPrice MONEY,
    @MaxPrice MONEY
AS
BEGIN
    BEGIN TRY
        IF @MinPrice < 0 OR @MaxPrice < 0 OR @MinPrice > @MaxPrice
        BEGIN
            RAISERROR('Invalid price range.', 16, 1);
            RETURN;
        END

        SELECT 
            p.ProductID,
            p.Name,
            p.ListPrice,
            c.Name AS Category
        FROM Production.Product p
        JOIN Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID
        JOIN Production.ProductCategory c ON s.ProductCategoryID = c.ProductCategoryID
        WHERE c.Name = @CategoryName
          AND p.ListPrice BETWEEN @MinPrice AND @MaxPrice;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;


----24.2-----
CREATE PROCEDURE dbo.sp_UpdateProductPrice
    @ProductID INT,
    @NewPrice MONEY,
    @ChangedBy NVARCHAR(100)
AS
BEGIN
    DECLARE @OldPrice MONEY;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @OldPrice = ListPrice FROM Production.Product WHERE ProductID = @ProductID;

        IF @NewPrice <= 0
        BEGIN
            RAISERROR('New price must be greater than zero.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Production.Product
        SET ListPrice = @NewPrice
        WHERE ProductID = @ProductID;

        INSERT INTO production.price_history (product_id, old_price, new_price, changed_by)
        VALUES (@ProductID, @OldPrice, @NewPrice, @ChangedBy);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;


----25.1----
CREATE TRIGGER trg_UpdateInventoryAfterInsert
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    BEGIN TRY
        UPDATE p
        SET p.SafetyStockLevel = p.SafetyStockLevel - i.OrderQty
        FROM Production.Product p
        JOIN inserted i ON p.ProductID = i.ProductID;

       
    END TRY
    BEGIN CATCH
        RAISERROR('Inventory update failed.', 16, 1);
        ROLLBACK TRANSACTION;
    END CATCH
END;


-----25.2-----
CREATE VIEW vw_EmployeeDetails
AS
SELECT 
    e.BusinessEntityID,
    p.FirstName,
    p.LastName,
    e.JobTitle
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID;

GO

CREATE TRIGGER trg_InsertIntoEmployeeView
ON vw_EmployeeDetails
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Person.Person (FirstName, LastName, PersonType)
    SELECT FirstName, LastName, 'EM' FROM inserted;

    INSERT INTO HumanResources.Employee (BusinessEntityID, JobTitle)
    SELECT SCOPE_IDENTITY(), JobTitle FROM inserted;
END;



----25.3----
CREATE TRIGGER trg_AuditProductPriceChange
ON Production.Product
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ListPrice)
    BEGIN
        INSERT INTO dbo.PriceAuditLog (ProductID, OldPrice, NewPrice, ChangedDate, ChangedBy)
        SELECT 
            d.ProductID,
            d.ListPrice,
            i.ListPrice,
            GETDATE(),
            SYSTEM_USER
        FROM deleted d
        JOIN inserted i ON d.ProductID = i.ProductID;
    END
END;


----26----

CREATE NONCLUSTERED INDEX IX_ActiveProducts
ON Production.Product (Name)
WHERE SellEndDate IS NULL;


CREATE NONCLUSTERED INDEX IX_RecentOrders
ON Sales.SalesOrderHeader (OrderDate)
WHERE OrderDate >= '2023-07-23';
