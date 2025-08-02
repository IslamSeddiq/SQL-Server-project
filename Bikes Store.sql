USE Bikes_Store;

----> DATA EXPLORATION
SELECT TABLE_NAME,
	   COLUMN_NAME,
	   DATA_TYPE,
	   IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Sales', 'Products', 'Product_Categories', 'Product_Subcategories',
					 'Customers', 'Calendar', 'Returns', 'Territories')

SELECT * FROM Sales
SELECT * FROM Products
SELECT * FROM Product_Categories
SELECT * FROM Product_Subcategories
SELECT * FROM Customers
SELECT * FROM Calendar
SELECT * FROM [Returns]
SELECT * FROM Territories

----> 1) TOTAL REVENUES
SELECT SUM(S.OrderQuantity * P.ProductPrice) TotalRevenues
FROM Sales S
JOIN Products P ON S.ProductKey = P.ProductKey

----> 2) TOTAL REVENUES BY CATEGORY (THE COMPONENTS HAVE NO REVENUES)
SELECT C.CategoryName, ISNULL(SUM(S.OrderQuantity * P.ProductPrice), 0) TotalRevenues
FROM Product_Categories C
LEFT JOIN Product_Subcategories SC ON C.ProductcategoryKey = SC.ProductcategoryKey
LEFT JOIN Products P ON SC.ProductSubcategoryKey = P.ProductSubcategoryKey
LEFT JOIN Sales S ON P.ProductKey = S.ProductKey
GROUP BY CategoryName
ORDER BY TotalRevenues DESC

----> 3) TOTAL PROFIT
SELECT SUM(S.OrderQuantity * P.ProductPrice) - SUM(ProductCost) TotalProfit
FROM Sales S
JOIN Products P ON S.ProductKey = P.ProductKey

----> 4) THE MOST EXPENSIVE PRODUCTS WITH THEIR Subcategory AND Category
SELECT P.ProductName, P.ProductPrice, S.SubcategoryName, C.CategoryName
FROM Products P
JOIN Product_Subcategories S ON P.ProductSubcategoryKey = S.ProductSubcategoryKey
JOIN Product_Categories C ON S.ProductCategoryKey = C.ProductCategoryKey
WHERE ProductPrice = (SELECT MAX(ProductPrice) FROM Products)

----> 5) Top 5 Selling PRODUCTS
SELECT TOP 5 
	P.ProductName, 
	P.ProductPrice, 
	SUM(S.OrderQuantity) TotalSold, 
	SUM(S.OrderQuantity * P.ProductPrice) TotalRevenues
FROM Products P
JOIN Sales S ON P.ProductKey = S.ProductKey
GROUP BY P.ProductName, ProductPrice
ORDER BY TotalSold DESC

----> 6) YEARLY REVENUES TREND
SELECT YEAR(S.OrderDate) Year,
	   SUM(S.OrderQuantity * P.ProductPrice) YearlyRevenues
FROM SALES S
JOIN Products P ON S.ProductKey = P.ProductKey
GROUP BY YEAR(S.OrderDate)
ORDER BY YearlyRevenues DESC

----> 7) HIGH-VALUE CUSTOMERS
SELECT TOP 5
	   C.CustomerName, 
	   SUM(S.OrderQuantity * P.ProductPrice) TotalRevenues
FROM Sales S
JOIN Customers C ON S.CustomerKey = C.CustomerKey
JOIN Products P ON S.ProductKey = P.ProductKey
GROUP BY CustomerName
ORDER BY TotalRevenues DESC

----> 8) THE QUANTITY SOLD OF MOUNTAIN PRODUCTS
SELECT P.ProductName, SUM(S.OrderQuantity) QuantitySold
FROM Products P
JOIN Sales S ON P.ProductKey = S.ProductKey
WHERE P.ProductName LIKE ('%Mountain%')
GROUP BY ProductName
ORDER BY QuantitySold

----> 9) THE QUANTITY SOLD OF ROAD PRODUCTS IN EACH YEAR
SELECT 
    ProductName,
    ISNULL([2015], 0) AS [2015],
    ISNULL([2016], 0) AS [2016],
    ISNULL([2017], 0) AS [2017]
FROM (
    SELECT 
        P.ProductName, 
        YEAR(S.OrderDate) AS SalesYear,
        S.OrderQuantity
    FROM Products P
    JOIN Sales S ON P.ProductKey = S.ProductKey
    WHERE P.ProductName LIKE '%Road%'
) AS SourceTable
PIVOT (
    SUM(OrderQuantity)
    FOR SalesYear IN ([2015], [2016], [2017])
) AS PivotTable

----> 10) TOTAL REVENUES FOR EACH REGION
SELECT T.Region, SUM(S.OrderQuantity * P.ProductPrice) TotalRevenues
FROM Sales S
JOIN Products P ON S.ProductKey = P.ProductKey
JOIN Territories T ON S.TerritoryKey = T.SalesTerritoryKey
GROUP BY T.Region
ORDER BY TotalRevenues DESC

----> 11) THE RETURN RATE
SELECT 
    CONCAT(
        CAST(
            ROUND(
                CAST(SUM(ReturnQuantity) AS DECIMAL(10,2)) /
                CAST((SELECT SUM(OrderQuantity) FROM Sales) AS DECIMAL(10,2)) * 100, 
            2) AS FLOAT
        ), '%'
    ) AS ReturnRate
FROM [Returns]

----> 12) THE MOST 10 PRODUCTS THAT WERE RETURNED
SELECT TOP 10
    P.ProductName,
    SUM(S.OrderQuantity) AS QuantitySold,
    (
        SELECT SUM(R.ReturnQuantity)
        FROM Returns R
        WHERE R.ProductKey = P.ProductKey
    ) QuantityReturn
FROM Sales S
JOIN Products P ON S.ProductKey = P.ProductKey
GROUP BY P.ProductName, P.ProductKey
ORDER BY QuantityReturn DESC

----> 13) TOTAL COUNTRIES OF THE STORE 
SELECT COUNT(DISTINCT Country) TotalCountries
FROM Territories

----> 14) TOTAL REVENUES OF EACH COUNTRY
SELECT T.Country, SUM(P.ProductPrice * S.OrderQuantity) TotalRevenues
FROM Sales S
JOIN Products P ON S.ProductKey = P.ProductKey
JOIN Territories T ON S.TerritoryKey = T.SalesTerritoryKey
GROUP BY T.Country
ORDER BY TotalRevenues

----> 15) TOTAL REVENUES BY SUBCATEGORY (THERE ARE SOME SUBCATEGORIES THAT HAVE NO SALES)
--------> ALL BIKES CATEGORY PRODUCTS HAVE SALES
SELECT SC.SubcategoryName, 
	   C.CategoryName, 
	   ISNULL(SUM(S.OrderQuantity * P.ProductPrice), 0) TotalRevenues
FROM Product_Subcategories SC
LEFT JOIN Product_Categories C ON SC.ProductCategoryKey = C.ProductCategoryKey
LEFT JOIN Products P ON SC.ProductSubcategoryKey = P.ProductSubcategoryKey
LEFT JOIN Sales S ON P.ProductKey = S.ProductKey
GROUP BY SC.SubcategoryName, C.CategoryName
ORDER BY TotalRevenues DESC

----> 16) THE QAUNTITY SOLD BY CATEGORY
SELECT C.CategoryName, ISNULL(SUM(S.OrderQuantity), 0) QuantitySold
FROM Product_Categories C
LEFT JOIN Product_Subcategories SC ON C.ProductCategoryKey = SC.ProductCategoryKey
LEFT JOIN Products P ON SC.ProductSubcategoryKey = P.ProductSubcategoryKey
LEFT JOIN Sales S ON P.ProductKey = S.ProductKey
GROUP BY C.CategoryName
ORDER BY QuantitySold