Select Top 10 *
From Customer;
GO

Select Top 10 * 
FROM Artist;
GO

SELECT TOP 10 *
FROM Employee;
GO

SELECT TOP 10 *
FROM Album;
Go

SELECT TOP 10 *
FROM Genre;
GO

SELECT TOP 10 *
FROM Invoice;
GO

SELECT TOP 10 *
FROM InvoiceLine
GO

SELECT TOP 10 *
FROM MediaType;
GO

SELECT TOP 10 *
FROM Playlist;
GO

SELECT TOP 10 *
FROM PlaylistTrack;
GO

SELECT TOP 10 *
FROM Track;
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- count customer table
SELECT COUNT (*)
FROM Customer;

-- Display Customer names
SELECT FirstName, LastName
From Customer;
GO

-- customers from brazil
Select *
From Customer
Where Country = 'Brazil';

-- Customers based in canada
SELECT Customerid, firstname, lastname, country, city, Phone
FROM Customer
Where Country = 'Canada'
ORDER BY lastname asc;

--- SORT Milliseconds on tracks
SELECT name, Milliseconds, UnitPrice, Composer
FROM Track
Where Milliseconds > 300000
Order by UnitPrice desc;

-- Count Customer by Country
Select Country, count(*) as Total_customers
From Customer
Group by Country
Order by Total_customers desc;

-- Calculate average invoice
SELECT
AVG(Total) AS AverageInvoice
FROM Invoice;

-- Total Revenue
SELECT Sum(Total) AS Revenue
FROM Invoice;

-- countries generating over $100
SELECT BillingCountry, SUM(Total) AS Revenue
FROM Invoice
Group By BillingCountry
Having SUM(Total) > 100;

--ADVANCED SQL PROGRAME
-- JOIN TABLES CUSTOMER AND INVOICE
---Find out customer information and invoice 
Select c.firstname, c.lastname, i.Invoicedate, i.Total
FROM Customer c
JOIN Invoice i
ON c.customerid = i.customerid;

-- Multiple Join
SELECT

c.FirstName,
a.Title,
t.Name

FROM Customer c

JOIN Invoice i

ON c.CustomerId=i.CustomerId

JOIN InvoiceLine il

ON i.InvoiceId=il.InvoiceId

JOIN Track t

ON il.TrackId=t.TrackId

JOIN Album a

ON t.AlbumId=a.AlbumId;

--subquery
SELECT *

FROM Invoice

WHERE Total=

(
SELECT MAX(Total)

FROM Invoice
);

-- Ranking windows
SELECT
CustomerId,
SUM(Total) Revenue,
RANK() OVER
(ORDER BY SUM(Total) DESC)
AS Ranking
FROM Invoice
GROUP BY CustomerId;

--- ROW NUMBER
SELECT
TrackId,
Name,
ROW_NUMBER()
OVER(ORDER BY UnitPrice DESC)
AS RowNum
FROM Track;

-- Partition by
SELECT
BillingCountry,
InvoiceId,
Total,
RANK()
OVER
(PARTITION BY BillingCountry
ORDER BY Total DESC)
AS CountryRank
FROM Invoice;

--- Business Questions
SELECT TOP 10 

c.FirstName,
c.LastName,
SUM(i.Total) Revenue
FROM Customer c
JOIN Invoice i
ON c.CustomerId=i.CustomerId
GROUP BY
c.FirstName,
c.LastName
ORDER BY Revenue DESC;

-- Top 10 best-selling tracks by quantity
SELECT TOP 10 

t.Name AS Track, 
ar.Name AS Artist, 
SUM(il.Quantity) AS UnitsSold
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Album al ON t.AlbumId = al.AlbumId
JOIN Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY t.Name, ar.Name
ORDER BY UnitsSold DESC;

-- Monthly revenue trend
SELECT YEAR(InvoiceDate) AS InvoiceYear, MONTH(InvoiceDate) AS InvoiceMonth,
       SUM(Total) AS MonthlyRevenue
FROM Invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY InvoiceYear, InvoiceMonth;

-- Average order value and order count per country
SELECT BillingCountry,
       COUNT(InvoiceId) AS OrderCount,
       AVG(Total) AS AvgOrderValue
FROM Invoice
GROUP BY BillingCountry
ORDER BY AvgOrderValue DESC;
 
-- Most popular genre per customer (uses a window function)
SELECT CustomerId, Genre, GenreUnits FROM (
    SELECT i.CustomerId, g.Name AS Genre, SUM(il.Quantity) AS GenreUnits,
           ROW_NUMBER() OVER (PARTITION BY i.CustomerId ORDER BY SUM(il.Quantity) DESC) AS rn
    FROM InvoiceLine il
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN Track t ON il.TrackId = t.TrackId
    JOIN Genre g ON t.GenreId = g.GenreId
    GROUP BY i.CustomerId, g.Name
) ranked
WHERE rn = 1;

--- Create Indexx
CREATE INDEX IX_Invoice_Customer
ON Invoice(CustomerId);

CREATE INDEX IX_InvoiceLine_TrackId 
ON InvoiceLine(TrackId);



 

 


