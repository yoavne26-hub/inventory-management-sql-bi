/*
------------------------------------------
-- FINAL QUERIES -------------------------
------------------------------------------
------------------------------------------
-- PART 1 --------------------------------
------------------------------------------
------------------------------------------
-- First Query ---------------------------
------------------------------------------

SELECT TOP 5
    sf.Description AS SportCategory,
    SUM(r.PieceQuantity) as [Total Items Sold],
    SUM(r.PieceQuantity * p.UnitPrice) as [Total Earnings]
FROM Orders o
JOIN Carts c ON o.CartID = c.CartID
JOIN Rosters r ON c.CartID = r.CartID
JOIN Designs d ON r.ProductID = d.ProductID AND r.DesignID = d.DesignID
JOIN Products p ON d.ProductID = p.ProductID
JOIN SportFields sf ON p.SportField = sf.SportCode
WHERE YEAR(o.OrderDate) = YEAR(GETDATE())
GROUP BY sf.Description
ORDER BY [Total Earnings] DESC;

------------------------------------------
-- Second Query --------------------------
------------------------------------------

SELECT CS.CustomerID, CS.FirstName+' '+CS.LastName AS [Full Name], 
       COUNT(O.OrderID) as [Number of Orders], 
       SUM(R.PieceQuantity * P.UnitPrice) as [Total Earnings]
FROM Carts CA 
JOIN Orders O ON CA.CartID = O.CartID
JOIN Customers CS on CS.CustomerID = CA.CustomerID
JOIN Rosters R ON CA.CartID = R.CartID
JOIN Products P ON R.ProductID = P.ProductID
WHERE YEAR(O.OrderDate) >= (YEAR(GETDATE())-5) 
GROUP BY CS.CustomerID, CS.FirstName, CS.LastName
HAVING COUNT(O.OrderID) > 1
ORDER BY [Total Earnings] DESC;

------------------------------------------
-- First Nested Query --------------------
------------------------------------------

 SELECT 
    P.ProductID,
    P.ProductName,
    SF.Description AS SportName,
    FORMAT(AVG(CAST(R.StarAmount AS DECIMAL(3,2))), 'N2') AS StarAvg,
    COUNT(R.ProductID) AS [Number Of Reviews]
FROM Products P
JOIN Reviews R ON P.ProductID = R.ProductID
JOIN SportFields SF ON P.SportField = SF.SportCode
GROUP BY P.ProductID, P.ProductName, SF.Description, P.SportField
HAVING AVG(R.StarAmount) < (
    SELECT AVG(R2.StarAmount)
    FROM Products P2
    JOIN Reviews R2 ON P2.ProductID = R2.ProductID
    WHERE P2.SportField = P.SportField
)
ORDER BY [Number Of Reviews] DESC

------------------------------------------
-- Second Nested Query -------------------
------------------------------------------

SELECT 
    T.ProductID,
    P.ProductName,
    T.ShippingCountry,
    T.TotalRevenue
FROM (
    SELECT 
        r.ProductID,
        o.ShippingCountry,
        SUM(p.UnitPrice * r.PieceQuantity) AS TotalRevenue
    FROM Orders o
    JOIN Carts c ON o.CartID = c.CartID
    JOIN Rosters r ON c.CartID = r.CartID
    JOIN Products p ON r.ProductID = p.ProductID
    WHERE YEAR(o.OrderDate) = YEAR(GETDATE())
    GROUP BY r.ProductID, o.ShippingCountry
) AS T
JOIN Products P ON T.ProductID = P.ProductID
WHERE T.TotalRevenue = (
    SELECT TOP 1 TotalRevenue
    FROM (
        SELECT 
            r2.ProductID,
            o2.ShippingCountry,
            SUM(p2.UnitPrice * r2.PieceQuantity) AS TotalRevenue
        FROM Orders o2
        JOIN Carts c2 ON o2.CartID = c2.CartID
        JOIN Rosters r2 ON c2.CartID = r2.CartID
        JOIN Products p2 ON r2.ProductID = p2.ProductID
        WHERE YEAR(o2.OrderDate) = YEAR(GETDATE())
          AND r2.ProductID = T.ProductID
        GROUP BY r2.ProductID, o2.ShippingCountry
    ) AS RevenuePerCountry
)
AND T.TotalRevenue > 1000
ORDER BY T.TotalRevenue DESC;

------------------------------------------
-- First Window Function -----------------
------------------------------------------

SELECT 
    OrderYear AS [Year],
    OrderMonth AS [Month],
    TotalSales AS [Current Month Sales],
    ISNULL(LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth), 0) AS [Previous Month Sales],

   ISNULL(
        AVG(TotalSales) OVER (
            ORDER BY OrderYear, OrderMonth 
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ), 0
    ) AS [Previous 3 Months Avg],

    (TotalSales - ISNULL(LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth), 0)) AS [Change compared to the Previous Months],
    (TotalSales - ISNULL(
        AVG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING), 0
    )) AS [Change compared to the 3-Months Avg]

FROM (
    SELECT
        DATEPART(YEAR, O.OrderDate) AS OrderYear,
        DATEPART(MONTH, O.OrderDate) AS OrderMonth,
        SUM(R.PieceQuantity * P.UnitPrice) AS TotalSales
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Rosters R ON C.CartID = R.CartID

------------------------------------------
-- Second Window Function ----------------
------------------------------------------

SELECT 
    CustomerID,
    FullName,
    TotalSpent,
    RANK() OVER (ORDER BY TotalSpent DESC) AS SpendingRank,
    NTILE(4) OVER (ORDER BY TotalSpent DESC) AS SpendingQuartile
FROM (
    SELECT 
        GS.CustomerID,
        GS.FirstName + ' ' + GS.LastName AS FullName,
        SUM(R.PieceQuantity * P.UnitPrice) AS TotalSpent
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Customers GS ON GS.CustomerID = C.CustomerID
    JOIN Rosters R ON C.CartID = R.CartID
    JOIN Products P ON R.ProductID = P.ProductID
    GROUP BY GS.CustomerID, GS.FirstName, GS.LastName
) AS CustomerTotals
ORDER BY SpendingRank;

------------------------------------------
-- CTE -----------------------------------
------------------------------------------

WITH OrderTotals AS (
    SELECT
        O.OrderID,
        C.CustomerID,
        O.ShippingCountry,
        SUM(R.PieceQuantity * P.UnitPrice) AS OrderTotal
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Rosters R ON C.CartID = R.CartID
    JOIN Products P ON R.ProductID = P.ProductID
    WHERE C.CustomerID IS NOT NULL
    GROUP BY O.OrderID, C.CustomerID, O.ShippingCountry
),

AvgOrder AS (
     SELECT AVG(OrderTotal) AS AvgTotal
    FROM OrderTotals
),

VIPCandidates AS (
    SELECT
        CS.CustomerID,
        CS.FirstName,
        CS.LastName,
        ORD.ShippingCountry,
        COUNT(O.OrderID) AS NumOfOrders,
        SUM(O.OrderTotal) AS TotalSpent
    FROM Customers CS
    JOIN OrderTotals O ON CS.CustomerID = O.CustomerID
    JOIN Carts C ON CS.CustomerID = C.CustomerID
    JOIN Orders ORD ON ORD.CartID = C.CartID
    CROSS JOIN AvgOrder A
    WHERE O.OrderTotal > A.AvgTotal
    GROUP BY CS.CustomerID, CS.FirstName, CS.LastName, ORD.ShippingCountry
    HAVING COUNT(O.OrderID) >= 5
),
TopCountries AS (
    SELECT 
        ShippingCountry,
        COUNT(*) AS NumOfVIPs
    FROM VIPCandidates
    GROUP BY ShippingCountry
    HAVING COUNT(*) >= 3 
)

SELECT 
    ShippingCountry AS Country,
    NumOfVIPs,
    (SELECT MAX(TotalSpent) FROM VIPCandidates VC WHERE VC.ShippingCountry = TC.ShippingCountry) AS MaxSpentInCountry
FROM TopCountries TC
ORDER BY NumOfVIPs DESC;

------------------------------------------
-- PART 2 --------------------------------
------------------------------------------
------------------------------------------
-- Fisrt View ----------------------------
------------------------------------------

GO
CREATE VIEW VIEW_DETAILS_CUSTOMERS AS
SELECT
    CS.CustomerID,
    CS.FirstName + ' ' + CS.LastName AS FullName,
    P.ProductID,
    O.OrderID,
    O.OrderDate,
    R.PieceQuantity * P.UnitPrice AS OrderPrice,
    A.AddressID
FROM Orders O
JOIN Carts C ON O.CartID = C.CartID
JOIN Customers CS ON C.CustomerID = CS.CustomerID
JOIN Rosters R ON C.CartID = R.CartID
JOIN Products P ON R.ProductID = P.ProductID
JOIN UserAddresses UA ON UA.CustomerID=CS.CustomerID
JOIN Addresses A ON A.AddressID = UA.AddressID;

------------------------------------------
-- Second View ---------------------------
------------------------------------------

go
CREATE VIEW VIEW_AbandonedCartsWithItems AS
SELECT 
    C.CartID,
    C.CustomerID,
    C.createdAt,
    COUNT(R.ProductID) AS NumOfItems
FROM Carts C
JOIN Rosters R ON C.CartID = R.CartID
LEFT JOIN Orders O ON C.CartID = O.CartID
WHERE O.CartID IS NULL
GROUP BY C.CartID, C.CustomerID, C.createdAt;

------------------------------------------
-- First Function ------------------------
------------------------------------------

GO
CREATE FUNCTION dbo.fn_CountOrdersUsingSavedAddress
(
    @UserCustomerID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(DISTINCT O.OrderID)
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Customers CU ON C.CustomerID = CU.CustomerID
    JOIN UserCustomers UC ON CU.CustomerID = UC.CustomerID
    JOIN UserAddresses UA ON UA.CustomerID = UC.CustomerID
    JOIN Addresses A ON UA.AddressID = A.AddressID
    WHERE UC.CustomerID = @UserCustomerID
      AND O.ShippingCountry = A.Country
      AND O.ShippingCity = A.City
      AND O.ShippingStreet = A.Street
      AND O.ShippingZipCode = A.ZipCode;

    RETURN @Count;
END
GO

SELECT
    UC.CustomerID,
    UC.UserName,
    (SELECT COUNT(*) FROM UserAddresses UA WHERE UA.CustomerID = UC.CustomerID) AS NumOfSavedAddresses,
    (SELECT COUNT(*) 
     FROM Orders O
     JOIN Carts C ON O.CartID = C.CartID
     WHERE C.CustomerID = UC.CustomerID) AS TotalOrders,
    dbo.fn_CountOrdersUsingSavedAddress(UC.CustomerID) AS OrdersWithSavedAddress,
    CASE 
        WHEN (SELECT COUNT(*) 
              FROM Orders O 
              JOIN Carts C ON O.CartID = C.CartID
              WHERE C.CustomerID = UC.CustomerID) = 0 THEN 0
        ELSE CAST(dbo.fn_CountOrdersUsingSavedAddress(UC.CustomerID) * 100.0 /
                  (SELECT COUNT(*) 
                   FROM Orders O 
                   JOIN Carts C ON O.CartID = C.CartID
                   WHERE C.CustomerID = UC.CustomerID) AS DECIMAL(5,2))
    END AS UsagePercentage
FROM UserCustomers UC
ORDER BY UsagePercentage DESC;

------------------------------------------
-- Second Function -----------------------
------------------------------------------

GO

       CREATE FUNCTION dbo.fn_FindSuspiciousResellers()
RETURNS TABLE
AS
RETURN
(
    WITH SportFieldCounts AS (
        SELECT
            UC.CustomerID,
            COUNT(DISTINCT P.SportField) AS NumOfSports
        FROM VIEW_DETAILS_CUSTOMERS V
        JOIN Products P ON V.ProductID = P.ProductID
        JOIN UserCustomers UC ON V.CustomerID = UC.CustomerID
        GROUP BY UC.CustomerID
    ),
    
    DesignsPerSportField AS (
        SELECT
            UC.CustomerID,
            P.SportField,
            COUNT(DISTINCT D.DesignID) AS NumOfDesigns
        FROM VIEW_DETAILS_CUSTOMERS V
        JOIN Products P ON V.ProductID = P.ProductID
        JOIN Designs D ON V.ProductID = D.ProductID
        JOIN UserCustomers UC ON V.CustomerID = UC.CustomerID
        GROUP BY UC.CustomerID, P.SportField
    ),

    CustomersWithHighDesigns AS (
        SELECT CustomerID
        FROM DesignsPerSportField
        WHERE NumOfDesigns > 4
        GROUP BY CustomerID
    )

    SELECT DISTINCT
        UC.CustomerID,
        UC.UserName,
        SF.NumOfSports,
        ISNULL(HD.HasHighDesigns, 0) AS HasHighDesigns
    FROM UserCustomers UC
    LEFT JOIN SportFieldCounts SF ON UC.CustomerID = SF.CustomerID
    LEFT JOIN (
        SELECT CustomerID, 1 AS HasHighDesigns
        FROM CustomersWithHighDesigns
    ) HD ON UC.CustomerID = HD.CustomerID
    WHERE SF.NumOfSports > 1 OR HD.HasHighDesigns = 1
);
SELECT *
FROM dbo.fn_FindSuspiciousResellers();

------------------------------------------
-- Trigger -------------------------------
------------------------------------------

GO
CREATE TRIGGER trg_ValidateReviewInsert
ON Reviews
AFTER INSERT
AS
BEGIN
    DELETE R
    FROM Reviews R
    INNER JOIN inserted I ON R.CustomerID = I.CustomerID AND R.ProductID = I.ProductID
    LEFT JOIN (
        SELECT DISTINCT CustomerID, ProductID
        FROM VIEW_DETAILS_CUSTOMERS
    ) AS ValidOrders
    ON I.CustomerID = ValidOrders.CustomerID AND I.ProductID = ValidOrders.ProductID
    WHERE ValidOrders.CustomerID IS NULL;
END
GO


INSERT INTO Reviews (CustomerID, ProductID, ReviewDate, StarAmount, ReviewText)
SELECT 1001, 555, GETDATE(), 1, 'Looks like my TAPI 2 exam!'
WHERE NOT EXISTS (
    SELECT 1
    FROM VIEW_DETAILS_CUSTOMERS
    WHERE CustomerID = 1001 AND ProductID = 555

------------------------------------------
-- Procedure -----------------------------
------------------------------------------

-- לבדוק אם נשארו עגלות ישנות בלי הזמנה:
SELECT *
FROM Carts C
LEFT JOIN Orders O ON C.CartID = O.CartID
WHERE O.CartID IS NULL AND C.createdAt < '2025-06-23';

-- לבדוק אם נשארו עגלות ישנות בלי פריטים:
SELECT *
FROM Carts C
LEFT JOIN Rosters R ON C.CartID = R.CartID
WHERE R.CartID IS NULL AND  C.createdAt < '2025-06-23';


CREATE VIEW VIEW_AbandonedCartsWithItems AS
SELECT 
    C.CartID,
    C.CustomerID,
    C.createdAt,
    COUNT(R.ProductID) AS NumOfItems
FROM Carts C
JOIN Rosters R ON C.CartID = R.CartID
LEFT JOIN Orders O ON C.CartID = O.CartID
WHERE O.CartID IS NULL
GROUP BY C.CartID, C.CustomerID, C.createdAt;

	GO
CREATE PROCEDURE CleanAbandonedEmptyCarts
    @CutoffDate DATETIME
AS
BEGIN

    ------------------------------------------------------
    -- Step 1: Handle carts with no roster entries (completely empty)
    ------------------------------------------------------
    DECLARE @CartsWithoutRosters TABLE (CartID INT);

    INSERT INTO @CartsWithoutRosters (CartID)
    SELECT C.CartID
    FROM Carts C
    LEFT JOIN Rosters R ON C.CartID = R.CartID
    WHERE R.CartID IS NULL AND C.createdAt < @CutoffDate;

    PRINT 'Carts without roster entries identified:';
    SELECT * FROM @CartsWithoutRosters;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Step 1a: Delete orders for these carts (not supposed to exsist, but checking just in case)
        DELETE FROM Orders
        WHERE CartID IN (SELECT CartID FROM @CartsWithoutRosters);

        -- Step 1b: Delete the carts
        DELETE FROM Carts
        WHERE CartID IN (SELECT CartID FROM @CartsWithoutRosters);

        COMMIT TRANSACTION;
        PRINT 'Carts without rosters (and related orders) deleted successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error deleting carts without rosters. Transaction rolled back.';
        PRINT ERROR_MESSAGE();
    END CATCH

    ------------------------------------------------------
    -- Step 2: Handle carts that had items (in Rosters) but were never ordered
    -- Using view VIEW_AbandonedCartsWithItems to identify relevant carts
    ------------------------------------------------------
    DECLARE @AbandonedCartsWithItems TABLE (CartID INT);

    INSERT INTO @AbandonedCartsWithItems (CartID)
    SELECT CartID
    FROM VIEW_AbandonedCartsWithItems
    WHERE createdAt < @CutoffDate;

    PRINT 'Carts with items and no orders identified from view:';
    SELECT * FROM @AbandonedCartsWithItems;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Step 2a: Delete roster entries
        DELETE FROM Rosters
        WHERE CartID IN (SELECT CartID FROM @AbandonedCartsWithItems);

        -- Step 2b: Delete the carts
        DELETE FROM Carts
        WHERE CartID IN (SELECT CartID FROM @AbandonedCartsWithItems);

        COMMIT TRANSACTION;
        PRINT 'Carts with items but no orders deleted successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error deleting carts with items but no orders. Transaction rolled back.';
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO

EXEC CleanAbandonedEmptyCarts @CutoffDate = '2025-06-23';

------------------------------------------
-- PART 3 --------------------------------
------------------------------------------
------------------------------------------
-- Fisrt View For BI ---------------------
------------------------------------------

CREATE VIEW SuspiciousResellersSummary AS
SELECT 
    C.CustomerID,
    C.FirstName + ' ' + C.LastName AS FullName,
    COUNT(DISTINCT P.SportField) AS SportFieldCount,
    COUNT(DISTINCT D.DesignID) AS DesignCount,
    COUNT(*) AS TotalItemsOrdered,
    SUM(R.PieceQuantity * P.UnitPrice) AS TotalRevenue,
    MAX(O.OrderDate) AS LastOrderDate
FROM 
    Customers C
    JOIN Carts Ca ON C.CustomerID = Ca.CustomerID
    JOIN Orders O ON O.CartID = Ca.CartID
    JOIN Rosters R ON R.CartID = Ca.CartID
    JOIN Products P ON R.ProductID = P.ProductID
    JOIN Designs D ON R.ProductID = D.ProductID AND R.DesignID = D.DesignID
GROUP BY 
    C.CustomerID, C.FirstName, C.LastName;

------------------------------------------
-- Second View For BI --------------------
------------------------------------------

CREATE VIEW SportRevenue AS
SELECT
    O.OrderDate,
    YEAR(O.OrderDate) AS OrderYear,
    DATEPART(QUARTER, O.OrderDate) AS OrderQuarter,
    MONTH(O.OrderDate) AS OrderMonth,
    DAY(O.OrderDate) AS OrderDay,
    P.SportField,
    P.ProductType,
    SUM(R.PieceQuantity * P.UnitPrice) AS TotalRevenue,
    SUM(R.PieceQuantity) AS TotalQuantity,
    COUNT(DISTINCT O.OrderID) AS TotalOrders
FROM
    Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Rosters R ON R.CartID = C.CartID
    JOIN Products P ON R.ProductID = P.ProductID
GROUP BY
    O.OrderDate,
    YEAR(O.OrderDate),
    DATEPART(QUARTER, O.OrderDate),
    MONTH(O.OrderDate),
    DAY(O.OrderDate),
    P.SportField,
    P.ProductType;

------------------------------------------
-- PART 4 --------------------------------
------------------------------------------
------------------------------------------
-- CTE After AI  -------------------------
------------------------------------------
CREATE INDEX idx_orders_cartid ON Orders (CartID);
CREATE INDEX idx_carts_customerid ON Carts (CustomerID);
CREATE INDEX idx_rosters_cartid ON Rosters (CartID);


WITH OrderTotals AS (
    SELECT
        O.OrderID,
        C.CustomerID,
        O.ShippingCountry,
        SUM(R.PieceQuantity * P.UnitPrice) AS OrderTotal
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Rosters R ON C.CartID = R.CartID
    JOIN Products P ON R.ProductID = P.ProductID
    WHERE C.CustomerID IS NOT NULL
    GROUP BY O.OrderID, C.CustomerID, O.ShippingCountry
),
AvgOrder AS (
     SELECT AVG(OrderTotal) AS AvgTotal
    FROM OrderTotals
),
VIPCandidates AS (
    SELECT
        CS.CustomerID,
        CS.FirstName,
        CS.LastName,
        ORD.ShippingCountry,
        COUNT(O.OrderID) AS NumOfOrders,
        SUM(O.OrderTotal) AS TotalSpent
    FROM Customers CS
    JOIN OrderTotals O ON CS.CustomerID = O.CustomerID
    JOIN Carts C ON CS.CustomerID = C.CustomerID
    JOIN Orders ORD ON ORD.CartID = C.CartID
    CROSS JOIN AvgOrder A
    WHERE O.OrderTotal > A.AvgTotal
    GROUP BY CS.CustomerID, CS.FirstName, CS.LastName, ORD.ShippingCountry
    HAVING COUNT(O.OrderID) >= 5
),
TopCountries AS (
    SELECT 
        ShippingCountry,
        COUNT(*) AS NumOfVIPs
    FROM VIPCandidates
    GROUP BY ShippingCountry
    HAVING COUNT(*) >= 3 
)
SELECT 
    ShippingCountry AS Country,
    NumOfVIPs,
    (SELECT MAX(TotalSpent) FROM VIPCandidates VC WHERE VC.ShippingCountry = TC.ShippingCountry) AS MaxSpentInCountry
FROM TopCountries TC
ORDER BY NumOfVIPs DESC;

------------------------------------------
-- First Window Function After AI --------
------------------------------------------

WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1) AS SaleMonth,
        SUM(R.PieceQuantity * P.UnitPrice) AS TotalSales
    FROM Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN Rosters R ON C.CartID = R.CartID
    JOIN Products P ON R.ProductID = P.ProductID
    WHERE O.OrderDate >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
      AND O.OrderDate < DATEFROMPARTS(YEAR(GETDATE()) + 1, 1, 1)
    GROUP BY DATEFROMPARTS(YEAR(O.OrderDate), MONTH(O.OrderDate), 1)
)
SELECT 
    FORMAT(SaleMonth, 'yyyy') AS [Year],
    FORMAT(SaleMonth, 'MM') AS [Month],
    TotalSales AS [Current Month Sales],
    ISNULL(LAG(TotalSales) OVER (ORDER BY SaleMonth), 0) AS [Previous Month Sales],
    ISNULL(
        AVG(TotalSales) OVER (
            ORDER BY SaleMonth 
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ), 0
    ) AS [Previous 3 Months Avg],
    TotalSales - ISNULL(LAG(TotalSales) OVER (ORDER BY SaleMonth), 0) AS [Change compared to the Previous Month],
    TotalSales - ISNULL(
        AVG(TotalSales) OVER (ORDER BY SaleMonth ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING), 0
    ) AS [Change compared to the 3-Months Avg]
FROM MonthlySales
ORDER BY [Change compared to the 3-Months Avg] DESC;

------------------------------------------
-- PART 5 BONUS --------------------------
------------------------------------------
------------------------------------------
-- CTE With Pivot ------------------------
------------------------------------------

WITH RankedOrders AS (
    SELECT 
        c.CustomerID,
        o.OrderID,
        o.OrderDate,
        SUM(p.UnitPrice * r.PieceQuantity) AS OrderRevenue,
        RANK() OVER (PARTITION BY c.CustomerID ORDER BY o.OrderDate DESC) AS OrderRank
    FROM Orders o
    JOIN Carts c ON o.CartID = c.CartID
    JOIN Rosters r ON c.CartID = r.CartID
    JOIN Products p ON r.ProductID = p.ProductID
    GROUP BY c.CustomerID, o.OrderID, o.OrderDate
),
FilteredOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE OrderRank <= 5
),
Pivoted AS (
    SELECT 
        CustomerID,
        MAX(CASE WHEN OrderRank = 1 THEN OrderRevenue END) AS Order1,
        MAX(CASE WHEN OrderRank = 2 THEN OrderRevenue END) AS Order2,
        MAX(CASE WHEN OrderRank = 3 THEN OrderRevenue END) AS Order3,
        MAX(CASE WHEN OrderRank = 4 THEN OrderRevenue END) AS Order4,
        MAX(CASE WHEN OrderRank = 5 THEN OrderRevenue END) AS Order5,
        AVG(OrderRevenue) AS AverageRevenue,
        COUNT(*) AS OrderCount
    FROM FilteredOrders
    GROUP BY CustomerID
    HAVING COUNT(*) >= 3
)
SELECT 
    CustomerID,
    Order1,
    Order2,
    Order3,
    Order4,
    Order5,
    AverageRevenue
FROM Pivoted
ORDER BY AverageRevenue DESC;

------------------------------------------
-- CTE With JSON -------------------------
------------------------------------------

WITH ReviewCounts AS (
    SELECT 
        ProductID,
        COUNT(*) AS TotalReviews,
        SUM(IIF(StarAmount < 3, 1, 0)) AS BadReviews
    FROM Reviews
    GROUP BY ProductID
)

SELECT 
    R.ProductID,
    CONVERT(DECIMAL(4,2), AVG(CAST(R.StarAmount AS DECIMAL(4,2)))) AS Avg_Stars,
    CONVERT(DECIMAL(4,2), RC.BadReviews * 1.0 / RC.TotalReviews) AS BadReviewRatio,
    (
        SELECT 
            Rsub.ReviewText
        FROM Reviews AS Rsub
        WHERE 
            Rsub.ProductID = R.ProductID AND 
            Rsub.StarAmount < 3
        FOR JSON AUTO
    ) AS LowRatedReviews_JSON
FROM Reviews R
INNER JOIN ReviewCounts RC ON R.ProductID = RC.ProductID
WHERE RC.BadReviews > 0
GROUP BY R.ProductID, RC.BadReviews, RC.TotalReviews
ORDER BY BadReviewRatio DESC;


------------------------------------------
-- END -----------------------------------
------------------------------------------