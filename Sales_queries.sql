SELECT TOP 10 *
FROM Sales;
 
 --inspect data
 SELECT COUNT (*) AS TotalRows
 FROM Sales;

 Select *
 From INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = 'Sales';

 --CONVERT DATE/TIME2 DATA TYPE TO JUST DATE
 -- ALTER TABLE TO UPDATE IT THE CONFIRM
-- 1. Wipe the slate clean FIRST to resolve the name conflict
ALTER TABLE Sales 
DROP COLUMN IF EXISTS OrderDateClean;

-- 2. Explicitly add the column fresh
ALTER TABLE Sales 
ADD OrderDateClean DATE;

-- 3. Now safely run your conversion logic
UPDATE Sales
SET OrderDateClean = TRY_CONVERT(DATE, ORDERDATE, 101);

-- 4. Confirm the results
SELECT COUNT(*) AS UnconvertedRows
FROM Sales
WHERE ORDERDATE IS NOT NULL AND OrderDateClean IS NULL;

SELECT TOP 10 * FROM Sales;

-- Identify null values
SELECT *
FROM Sales
WHERE Sales IS NULL;

-- data cleaning, missing values
SELECT
    SUM(CASE WHEN ADDRESSLINE2 IS NULL THEN 1 ELSE 0 END) AS Missing_AddressLine2,
    SUM(CASE WHEN STATE IS NULL THEN 1 ELSE 0 END) AS Missing_State,
    SUM(CASE WHEN POSTALCODE IS NULL THEN 1 ELSE 0 END) AS Missing_PostalCode,
    SUM(CASE WHEN TERRITORY IS NULL THEN 1 ELSE 0 END) AS Missing_Territory,
    SUM(CASE WHEN CONTACTFIRSTNAME IS NULL THEN 1 ELSE 0 END) AS Missing_contactlastname,
    SUM(CASE WHEN CONTACTLASTNAME IS NULL THEN 1 ELSE 0 END) AS Missing_contactfirstname,
    SUM(CASE WHEN DEALSIZE IS NULL THEN 1 ELSE 0 END) AS Missing_dealsize,
    SUM(CASE WHEN COUNTRY IS NULL THEN 1 ELSE 0 END) AS Missing_country,
    SUM(CASE WHEN PHONE IS NULL THEN 1 ELSE 0 END) AS Missing_Phone,
    SUM(CASE WHEN CUSTOMERNAME IS NULL THEN 1 ELSE 0 END) AS Missing_Customername,
    SUM(CASE WHEN PRODUCTCODE IS NULL THEN 1 ELSE 0 END) AS Missing_Productcode,
    SUM(CASE WHEN MSRP IS NULL THEN 1 ELSE 0 END) AS Missing_MSRP,
    SUM(CASE WHEN ADDRESSLINE1 IS NULL THEN 1 ELSE 0 END) AS Missing_AddressLine1,
    SUM(CASE WHEN ORDERNUMBER IS NULL THEN 1 ELSE 0 END) AS Missing_ORDERNUMBER,
    SUM(CASE WHEN QUANTITYORDERED IS NULL THEN 1 ELSE 0 END) AS Missing_quantityordered,
    SUM(CASE WHEN ORDERLINENUMBER IS NULL THEN 1 ELSE 0 END) AS Missing_Orderlinenumber,
    SUM(CASE WHEN PRICEEACH IS NULL THEN 1 ELSE 0 END) AS Missing_PRICEEACH,
    SUM(CASE WHEN QTR_ID IS NULL THEN 1 ELSE 0 END) AS Missing_QTR_ID,
    SUM(CASE WHEN MONTH_ID IS NULL THEN 1 ELSE 0 END) AS Missing_MONTH_ID,
    SUM(CASE WHEN SALES IS NULL THEN 1 ELSE 0 END) AS Missing_sales
FROM Sales;

--Replace missing values
UPDATE Sales
SET POSTALCODE = 'Unknown'
WHERE POSTALCODE IS NULL;

UPDATE Sales
Set STATE = 'Unspecified'
WHERE STATE IS NULL;

UPDATE Sales
SET ADDRESSLINE2 = 'Unknown'
WHERE ADDRESSLINE2 IS NULL

-- Trim stray whitespace introduced by the CSV export
UPDATE Sales
SET CUSTOMERNAME = LTRIM(RTRIM(CUSTOMERNAME)),
    COUNTRY = LTRIM(RTRIM(COUNTRY)),
    PRODUCTLINE = LTRIM(RTRIM(PRODUCTLINE));

-- identify duplicates
Select *, Count (*) AS Duplicate_Count
From Sales
GROUP BY
ORDERDATE,
ORDERLINENUMBER,
ORDERNUMBER,
QUANTITYORDERED,
PRICEEACH,
SALES,
STATUS,
QTR_ID,
MONTH_ID,
YEAR_ID,
PRODUCTCODE,
MSRP,
CUSTOMERNAME,
PHONE,
ADDRESSLINE1,
ADDRESSLINE2,
CITY,
OrderDateClean,
PRODUCTLINE,
STATE,
POSTALCODE,
COUNTRY,
TERRITORY,
CONTACTLASTNAME,
CONTACTFIRSTNAME,
DEALSIZE
HAVING COUNT(*) > 1;

--- core queries
--total sales and total orders
SELECT SUM(SALES) AS REVENUE, SUM(QUANTITYORDERED) AS TOTALORDER
FROM Sales;

-- Large, shipped deals in France
SELECT ORDERNUMBER, CUSTOMERNAME, SALES, DEALSIZE, STATUS
FROM Sales
WHERE COUNTRY = 'France' AND DEALSIZE = 'Large' AND STATUS = 'Shipped'
ORDER BY SALES DESC;

--SALES BY PRODUCTLINE
SELECT SALES, PRODUCTLINE
FROM Sales
ORDER BY SALES DESC;

-- Revenue and order count by product line(highest orders should be distinct to remove duplicates ordernumber, average to get hou much 1 was sold and revenue)
SELECT PRODUCTLINE,
       COUNT(DISTINCT ORDERNUMBER) AS Orders,
       SUM(SALES) AS TotalRevenue,
       AVG(SALES) AS AvgLineRevenue
FROM Sales
GROUP BY PRODUCTLINE
ORDER BY TotalRevenue DESC;

-- countries generating over $500,000 in Sales
SELECT COUNTRY, SUM(SALES) AS TOTALREVENUE
FROM Sales
GROUP BY COUNTRY
HAVING SUM(SALES) > '500000'
ORDER BY TOTALREVENUE DESC;

-- Customers whose total spend exceeds the average customer spend
SELECT CUSTOMERNAME, TotalSpend
FROM (
    SELECT CUSTOMERNAME, SUM(SALES) AS TotalSpend
    FROM Sales
    GROUP BY CUSTOMERNAME
) AS CustomerTotals
WHERE TotalSpend > (
    SELECT AVG(CustSales) FROM (
        SELECT SUM(SALES) AS CustSales FROM Sales GROUP BY CUSTOMERNAME
    ) AS AvgCalc
)
ORDER BY TotalSpend DESC;

-- Rank product lines by yearly revenue
SELECT YEAR_ID, PRODUCTLINE, SUM(SALES) AS YearRevenue,
       RANK() OVER (PARTITION BY YEAR_ID ORDER BY SUM(SALES) DESC) AS RevenueRank
FROM Sales
GROUP BY YEAR_ID, PRODUCTLINE
ORDER BY YEAR_ID, RevenueRank;
 
-- Each customer's orders numbered in date order (identifies repeat customers)
SELECT CUSTOMERNAME, ORDERNUMBER, OrderDateClean,
       ROW_NUMBER() OVER (PARTITION BY CUSTOMERNAME ORDER BY OrderDateClean) AS OrderSequence
FROM Sales;

-- Business questions
-- TOP 10 PRODUCTS BY REVENUES
SELECT TOP 10 PRODUCTLINE, PRODUCTCODE, SUM(SALES) AS REVENUE
FROM Sales
GROUP BY PRODUCTCODE, PRODUCTLINE
ORDER BY SUM(SALES) DESC;

-- Quarterly revenue trend across all years
SELECT YEAR_ID, QTR_ID, SUM(SALES) AS QuarterlyRevenue
FROM Sales
GROUP BY YEAR_ID, QTR_ID
ORDER BY YEAR_ID, QTR_ID;

-- Month-over-month growth using a window function
SELECT YEAR_ID, MONTH_ID, MonthlyRevenue,
       MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY YEAR_ID, MONTH_ID) AS ChangeFromPrevMonth
FROM (
    SELECT YEAR_ID, MONTH_ID, SUM(SALES) AS MonthlyRevenue
    FROM Sales
    GROUP BY YEAR_ID, MONTH_ID
) AS Monthly;

-- Simple RFM-style view: recency, frequency, monetary value per customer
SELECT CUSTOMERNAME,
       DATEDIFF(DAY, MAX(OrderDateClean), '2005-05-31') AS DaysSinceLastOrder,
       COUNT(DISTINCT ORDERNUMBER) AS OrderFrequency,
       SUM(SALES) AS MonetaryValue
FROM Sales
GROUP BY CUSTOMERNAME
ORDER BY MonetaryValue DESC;
 
-- Deal size distribution by territory
SELECT TERRITORY, DEALSIZE, COUNT(*) AS DealCount, SUM(SALES) AS Revenue
FROM Sales
GROUP BY TERRITORY, DEALSIZE
ORDER BY TERRITORY, Revenue DESC;

-- CREATE INDEXX
CREATE NONCLUSTERED INDEX IX_SalesData_OrderDateClean 
ON Sales(OrderDateClean);





















