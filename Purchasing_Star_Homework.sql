-- Databricks notebook source
-- Purchasing star homework: SQL version of Purchasing_Star_Homework.ipynb.
-- Adapted from the notebook by Bala Sai Kiran Reddy Telluri.
-- Run in order on Databricks SQL or Runtime 13.3 LTS+ with Unity Catalog.
-- Needs the same raw volume and existing Lecture 1 Bronze tables:
-- adventureworks.bronze.product, salesterritory and salesorderdetail.
-- Existing tables are never overwritten. As in the Python notebook, the first
-- purchase-detail CREATE fails if its Bronze table already exists. If already
-- loaded, run its checks and continue without that CREATE statement.
-- Result counts mentioned in the Python notebook depend on its source dataset.

-- COMMAND ----------

-- 1. Inspect the source files

LIST '/Volumes/adventureworks/default/raw_data';

-- COMMAND ----------

-- 2. Bronze: load headerless, tab-separated files as strings

CREATE OR REPLACE TEMP VIEW raw_purchase_detail AS
SELECT _c0, _c1, _c2, _c3, _c4, _c5, _c6, _c7, _c8, _c9, _c10
FROM read_files(
    '/Volumes/adventureworks/default/raw_data/PurchaseOrderDetail.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING, _c8 STRING, _c9 STRING, _c10 STRING'
);

SELECT COUNT(*) AS Rows, 11 AS Columns FROM raw_purchase_detail;
DESCRIBE TABLE raw_purchase_detail;
SELECT * FROM raw_purchase_detail LIMIT 5;

CREATE TABLE adventureworks.bronze.stg_purchase_order_detail USING DELTA AS
SELECT * FROM raw_purchase_detail;

SELECT COUNT(*) AS SavedRows FROM adventureworks.bronze.stg_purchase_order_detail;
DESCRIBE TABLE adventureworks.bronze.stg_purchase_order_detail;

CREATE OR REPLACE TEMP VIEW raw_purchase_header AS
SELECT _c0, _c1, _c2, _c3, _c4, _c5, _c6, _c7, _c8, _c9, _c10, _c11, _c12
FROM read_files(
    '/Volumes/adventureworks/default/raw_data/PurchaseOrderHeader.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING, _c8 STRING, _c9 STRING, _c10 STRING, _c11 STRING, _c12 STRING'
);

SELECT COUNT(*) AS Rows, 13 AS Columns FROM raw_purchase_header;
DESCRIBE TABLE raw_purchase_header;
SELECT * FROM raw_purchase_header LIMIT 5;

CREATE TABLE IF NOT EXISTS adventureworks.bronze.stg_purchase_order_header USING DELTA AS
SELECT * FROM raw_purchase_header;

SELECT COUNT(*) AS SavedRows FROM adventureworks.bronze.stg_purchase_order_header;
DESCRIBE TABLE adventureworks.bronze.stg_purchase_order_header;

CREATE OR REPLACE TEMP VIEW raw_vendor AS
SELECT _c0, _c1, _c2, _c3, _c4, _c5, _c6, _c7
FROM read_files(
    '/Volumes/adventureworks/default/raw_data/Vendor.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING'
);

SELECT COUNT(*) AS Rows, 8 AS Columns FROM raw_vendor;
DESCRIBE TABLE raw_vendor;
SELECT * FROM raw_vendor LIMIT 5;

CREATE TABLE IF NOT EXISTS adventureworks.bronze.dim_vendor USING DELTA AS
SELECT * FROM raw_vendor;

SELECT COUNT(*) AS SavedRows FROM adventureworks.bronze.dim_vendor;
DESCRIBE TABLE adventureworks.bronze.dim_vendor;

CREATE OR REPLACE TEMP VIEW raw_sales_header AS
SELECT _c0, _c1, _c2, _c3, _c4, _c5, _c6, _c7, _c8, _c9, _c10, _c11, _c12, _c13, _c14, _c15, _c16, _c17, _c18, _c19, _c20, _c21, _c22, _c23, _c24, _c25
FROM read_files(
    '/Volumes/adventureworks/default/raw_data/SalesOrderHeader.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING, _c8 STRING, _c9 STRING, _c10 STRING, _c11 STRING, _c12 STRING, _c13 STRING, _c14 STRING, _c15 STRING, _c16 STRING, _c17 STRING, _c18 STRING, _c19 STRING, _c20 STRING, _c21 STRING, _c22 STRING, _c23 STRING, _c24 STRING, _c25 STRING'
);

SELECT COUNT(*) AS Rows, 26 AS Columns FROM raw_sales_header;
DESCRIBE TABLE raw_sales_header;
SELECT * FROM raw_sales_header LIMIT 5;

CREATE TABLE IF NOT EXISTS adventureworks.bronze.stg_sales_order_header USING DELTA AS
SELECT * FROM raw_sales_header;

SELECT COUNT(*) AS SavedRows FROM adventureworks.bronze.stg_sales_order_header;
DESCRIBE TABLE adventureworks.bronze.stg_sales_order_header;

-- COMMAND ----------

-- 3. Silver: names, types and checks

CREATE SCHEMA IF NOT EXISTS adventureworks.silver;

SELECT CAST(_c6 AS DECIMAL(19,4)) AS LineTotal,
       CAST(_c5 AS DECIMAL(19,4)) AS UnitPrice
FROM adventureworks.bronze.stg_purchase_order_detail LIMIT 3;

CREATE OR REPLACE TEMP VIEW purchase_detail AS
SELECT
    cast(_c0 as int) as PurchaseOrderID,
    cast(_c1 as int) as PurchaseOrderDetailID,
    cast(_c2 as timestamp) as DueDate,
    cast(_c3 as smallint) as OrderQty,
    cast(_c4 as int) as ProductID,
    cast(_c5 as decimal(19,4)) as UnitPrice,
    cast(_c6 as decimal(19,4)) as LineTotal,
    cast(_c7 as decimal(8,2)) as ReceivedQty,
    cast(_c8 as decimal(8,2)) as RejectedQty,
    cast(_c9 as decimal(8,2)) as StockedQty,
    cast(_c10 as timestamp) as ModifiedDate
FROM adventureworks.bronze.stg_purchase_order_detail;

DESCRIBE TABLE purchase_detail;
SELECT * FROM purchase_detail LIMIT 5;

-- Keep NULL LineTotal; only remove missing ProductID or negative LineTotal.
CREATE OR REPLACE TEMP VIEW purchase_detail_clean AS
SELECT * FROM purchase_detail
WHERE ProductID IS NOT NULL
  AND (LineTotal IS NULL OR LineTotal >= CAST(0 AS DECIMAL(19,4)));

SELECT (SELECT COUNT(*) FROM purchase_detail) AS Before,
       (SELECT COUNT(*) FROM purchase_detail_clean) AS After,
       (SELECT COUNT(*) FROM purchase_detail)
         - (SELECT COUNT(*) FROM purchase_detail_clean) AS Dropped;

CREATE TABLE IF NOT EXISTS adventureworks.silver.stg_purchase_order_detail USING DELTA AS
SELECT * FROM purchase_detail_clean;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.stg_purchase_order_detail;
DESCRIBE TABLE adventureworks.silver.stg_purchase_order_detail;

-- COMMAND ----------

-- purchase header

CREATE OR REPLACE TEMP VIEW purchase_header AS
SELECT
    cast(_c0 as int) as PurchaseOrderID,
    cast(_c1 as tinyint) as RevisionNumber,
    cast(_c2 as tinyint) as Status,
    cast(_c3 as int) as EmployeeID,
    cast(_c4 as int) as VendorID,
    cast(_c5 as int) as ShipMethodID,
    cast(_c6 as timestamp) as OrderDate,
    cast(_c7 as timestamp) as ShipDate,
    cast(_c8 as decimal(19,4)) as SubTotal,
    cast(_c9 as decimal(19,4)) as TaxAmt,
    cast(_c10 as decimal(19,4)) as Freight,
    cast(_c11 as decimal(19,4)) as TotalDue,
    cast(_c12 as timestamp) as ModifiedDate
FROM adventureworks.bronze.stg_purchase_order_header;

SELECT assert_true((SELECT COUNT(*) FROM purchase_header WHERE PurchaseOrderID IS NULL OR VendorID IS NULL OR OrderDate IS NULL) = 0, 'Missing header key or date');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT PurchaseOrderID FROM purchase_header)) = (SELECT COUNT(*) FROM purchase_header), 'Duplicate PurchaseOrderID');

CREATE TABLE IF NOT EXISTS adventureworks.silver.stg_purchase_order_header USING DELTA AS
SELECT * FROM purchase_header;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.stg_purchase_order_header;
DESCRIBE TABLE adventureworks.silver.stg_purchase_order_header;

-- COMMAND ----------

-- vendor

CREATE OR REPLACE TEMP VIEW vendor AS
SELECT
    cast(_c0 as int) as BusinessEntityID,
    _c1 as AccountNumber,
    _c2 as Name,
    cast(_c3 as tinyint) as CreditRating,
    cast(_c4 as boolean) as PreferredVendorStatus,
    cast(_c5 as boolean) as ActiveFlag,
    _c6 as PurchasingWebServiceURL,
    cast(_c7 as timestamp) as ModifiedDate
FROM adventureworks.bronze.dim_vendor;

SELECT assert_true((SELECT COUNT(*) FROM vendor WHERE BusinessEntityID IS NULL OR CreditRating IS NULL OR PreferredVendorStatus IS NULL OR ActiveFlag IS NULL OR ModifiedDate IS NULL) = 0, 'Vendor type check failed');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT BusinessEntityID FROM vendor)) = (SELECT COUNT(*) FROM vendor), 'Duplicate BusinessEntityID');

CREATE TABLE IF NOT EXISTS adventureworks.silver.dim_vendor USING DELTA AS
SELECT * FROM vendor;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.dim_vendor;
DESCRIBE TABLE adventureworks.silver.dim_vendor;

-- COMMAND ----------

-- sales header

CREATE OR REPLACE TEMP VIEW sales_header AS
SELECT
    cast(_c0 as int) as SalesOrderID,
    cast(_c1 as tinyint) as RevisionNumber,
    cast(_c2 as timestamp) as OrderDate,
    cast(_c3 as timestamp) as DueDate,
    cast(_c4 as timestamp) as ShipDate,
    cast(_c5 as tinyint) as Status,
    cast(_c6 as boolean) as OnlineOrderFlag,
    _c7 as SalesOrderNumber,
    _c8 as PurchaseOrderNumber,
    _c9 as AccountNumber,
    cast(_c10 as int) as CustomerID,
    cast(_c11 as int) as SalesPersonID,
    cast(_c12 as int) as TerritoryID,
    cast(_c13 as int) as BillToAddressID,
    cast(_c14 as int) as ShipToAddressID,
    cast(_c15 as int) as ShipMethodID,
    cast(_c16 as int) as CreditCardID,
    _c17 as CreditCardApprovalCode,
    cast(_c18 as int) as CurrencyRateID,
    cast(_c19 as decimal(19,4)) as SubTotal,
    cast(_c20 as decimal(19,4)) as TaxAmt,
    cast(_c21 as decimal(19,4)) as Freight,
    cast(_c22 as decimal(19,4)) as TotalDue,
    _c23 as Comment,
    _c24 as rowguid,
    cast(_c25 as timestamp) as ModifiedDate
FROM adventureworks.bronze.stg_sales_order_header;

SELECT assert_true((SELECT COUNT(*) FROM sales_header WHERE SalesOrderID IS NULL OR OrderDate IS NULL OR TerritoryID IS NULL) = 0, 'Missing sales header key/date');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT SalesOrderID FROM sales_header)) = (SELECT COUNT(*) FROM sales_header), 'Duplicate SalesOrderID');

CREATE TABLE IF NOT EXISTS adventureworks.silver.stg_sales_order_header USING DELTA AS
SELECT * FROM sales_header;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.stg_sales_order_header;
DESCRIBE TABLE adventureworks.silver.stg_sales_order_header;

-- COMMAND ----------

-- product dim

CREATE OR REPLACE TEMP VIEW product_dim AS
SELECT
    cast(ProductID as int) as ProductID,
    Name,
    ProductNumber,
    cast(MakeFlag as boolean) as MakeFlag,
    cast(FinishedGoodsFlag as boolean) as FinishedGoodsFlag,
    Color,
    cast(SafetyStockLevel as smallint) as SafetyStockLevel,
    cast(ReorderPoint as smallint) as ReorderPoint,
    cast(StandardCost as decimal(19,4)) as StandardCost,
    cast(ListPrice as decimal(19,4)) as ListPrice,
    Size,
    SizeUnitMeasureCode,
    WeightUnitMeasureCode,
    cast(nullif(trim(cast(Weight as string)), '') as decimal(8,2)) as Weight,
    cast(DaysToManufacture as int) as DaysToManufacture,
    ProductLine,
    Class,
    Style,
    cast(nullif(trim(cast(ProductSubcategoryID as string)), '') as int) as ProductSubcategoryID,
    cast(nullif(trim(cast(ProductModelID as string)), '') as int) as ProductModelID,
    cast(SellStartDate as timestamp) as SellStartDate,
    cast(nullif(trim(cast(SellEndDate as string)), '') as timestamp) as SellEndDate,
    cast(nullif(trim(cast(DiscontinuedDate as string)), '') as timestamp) as DiscontinuedDate,
    rowguid,
    cast(ModifiedDate as timestamp) as ModifiedDate
FROM adventureworks.bronze.product;

SELECT assert_true((SELECT COUNT(*) FROM product_dim WHERE ProductID IS NULL OR Name IS NULL) = 0, 'Missing product key/name');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT ProductID FROM product_dim)) = (SELECT COUNT(*) FROM product_dim), 'Duplicate ProductID');

CREATE TABLE IF NOT EXISTS adventureworks.silver.dim_product USING DELTA AS
SELECT * FROM product_dim;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.dim_product;
DESCRIBE TABLE adventureworks.silver.dim_product;

-- COMMAND ----------

-- territory dim

CREATE OR REPLACE TEMP VIEW territory_dim AS
SELECT
    cast(TerritoryID as int) as TerritoryID,
    Name,
    CountryRegionCode,
    `Group`,
    cast(SalesYTD as decimal(19,4)) as SalesYTD,
    cast(SalesLastYear as decimal(19,4)) as SalesLastYear,
    cast(CostYTD as decimal(19,4)) as CostYTD,
    cast(CostLastYear as decimal(19,4)) as CostLastYear,
    rowguid,
    cast(ModifiedDate as timestamp) as ModifiedDate
FROM adventureworks.bronze.salesterritory;

SELECT assert_true((SELECT COUNT(*) FROM territory_dim WHERE TerritoryID IS NULL OR Name IS NULL OR CountryRegionCode IS NULL OR `Group` IS NULL OR SalesYTD IS NULL OR SalesLastYear IS NULL OR CostYTD IS NULL OR CostLastYear IS NULL OR ModifiedDate IS NULL) = 0, 'Territory type check failed');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT TerritoryID FROM territory_dim)) = (SELECT COUNT(*) FROM territory_dim), 'Duplicate TerritoryID');

CREATE TABLE IF NOT EXISTS adventureworks.silver.dim_sales_territory USING DELTA AS
SELECT * FROM territory_dim;

SELECT COUNT(*) AS SavedRows FROM adventureworks.silver.dim_sales_territory;
DESCRIBE TABLE adventureworks.silver.dim_sales_territory;

-- COMMAND ----------

-- 4. Gold: purchasing fact, one row per purchase-order line

CREATE SCHEMA IF NOT EXISTS adventureworks.gold;

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT PurchaseOrderID FROM adventureworks.silver.stg_purchase_order_header)) = (SELECT COUNT(*) FROM adventureworks.silver.stg_purchase_order_header), 'Duplicate header keys');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT PurchaseOrderID, PurchaseOrderDetailID FROM adventureworks.silver.stg_purchase_order_detail)) = (SELECT COUNT(*) FROM adventureworks.silver.stg_purchase_order_detail), 'Duplicate purchase lines');

CREATE OR REPLACE TEMP VIEW fact_purchases AS
SELECT d.*, h.VendorID, h.OrderDate
FROM adventureworks.silver.stg_purchase_order_detail d
INNER JOIN adventureworks.silver.stg_purchase_order_header h
    ON d.PurchaseOrderID = h.PurchaseOrderID;

SELECT assert_true((SELECT COUNT(*) FROM fact_purchases) = (SELECT COUNT(*) FROM adventureworks.silver.stg_purchase_order_detail), 'Join lost or multiplied purchase lines');

SELECT assert_true((SELECT COUNT(*) FROM fact_purchases f LEFT ANTI JOIN adventureworks.silver.dim_product d ON f.ProductID = d.ProductID) = 0, 'Product missing from dimension');

SELECT assert_true((SELECT COUNT(*) FROM fact_purchases f LEFT ANTI JOIN adventureworks.silver.dim_vendor d ON f.VendorID = d.BusinessEntityID) = 0, 'Vendor missing from dimension');

CREATE TABLE IF NOT EXISTS adventureworks.gold.fact_purchases USING DELTA AS
SELECT * FROM fact_purchases;

SELECT COUNT(*) AS SavedRows FROM adventureworks.gold.fact_purchases;
DESCRIBE TABLE adventureworks.gold.fact_purchases;

-- COMMAND ----------

-- Sales fact, one row per sales-order line

CREATE OR REPLACE TEMP VIEW sales_lines AS
SELECT
    cast(SalesOrderID as int) as SalesOrderID,
    cast(SalesOrderDetailID as int) as SalesOrderDetailID,
    cast(ProductID as int) as ProductID,
    cast(OrderQty as smallint) as OrderQty,
    cast(UnitPrice as decimal(19,4)) as UnitPrice,
    cast(UnitPriceDiscount as decimal(19,4)) as UnitPriceDiscount,
    cast(LineTotal as decimal(38,6)) as LineTotal
FROM adventureworks.bronze.salesorderdetail;

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT SalesOrderID FROM adventureworks.silver.stg_sales_order_header)) = (SELECT COUNT(*) FROM adventureworks.silver.stg_sales_order_header), 'Duplicate sales header keys');

SELECT assert_true((SELECT COUNT(*) FROM (SELECT DISTINCT SalesOrderID, SalesOrderDetailID FROM sales_lines)) = (SELECT COUNT(*) FROM sales_lines), 'Duplicate sales lines');

SELECT assert_true((SELECT COUNT(*) FROM sales_lines WHERE SalesOrderID IS NULL OR ProductID IS NULL OR OrderQty IS NULL OR LineTotal IS NULL) = 0, 'Missing sales key or measure');

CREATE OR REPLACE TEMP VIEW fact_sales AS
SELECT s.*, h.OrderDate, h.TerritoryID
FROM sales_lines s
INNER JOIN adventureworks.silver.stg_sales_order_header h
    ON s.SalesOrderID = h.SalesOrderID;

SELECT assert_true((SELECT COUNT(*) FROM fact_sales) = (SELECT COUNT(*) FROM sales_lines), 'Join lost or multiplied sales lines');

SELECT assert_true((SELECT COUNT(*) FROM fact_sales f LEFT ANTI JOIN adventureworks.silver.dim_product d ON f.ProductID = d.ProductID) = 0, 'Product missing from dimension');

SELECT assert_true((SELECT COUNT(*) FROM fact_sales f LEFT ANTI JOIN adventureworks.silver.dim_sales_territory d ON f.TerritoryID = d.TerritoryID) = 0, 'Territory missing from dimension');

CREATE TABLE IF NOT EXISTS adventureworks.gold.fact_sales USING DELTA AS
SELECT * FROM fact_sales;

SELECT COUNT(*) AS SavedRows FROM adventureworks.gold.fact_sales;
DESCRIBE TABLE adventureworks.gold.fact_sales;

-- COMMAND ----------

-- 5. Five products with the lowest margin per unit

-- Quantity-weighted prices. Sales LineTotal already includes discounts.
-- These historical average prices do not match individual purchases to sales.

SELECT assert_true((SELECT COUNT(*) FROM adventureworks.gold.fact_sales WHERE OrderQty IS NULL OR OrderQty <= 0 OR LineTotal IS NULL) = 0, 'Invalid fact_sales quantity or amount');

SELECT assert_true((SELECT COUNT(*) FROM adventureworks.gold.fact_purchases WHERE OrderQty IS NULL OR OrderQty <= 0 OR LineTotal IS NULL) = 0, 'Invalid fact_purchases quantity or amount');

CREATE OR REPLACE TEMP VIEW margins AS
WITH sales_prices AS (
    SELECT ProductID, SUM(LineTotal) / SUM(OrderQty) AS UnitNetSalesPrice
    FROM adventureworks.gold.fact_sales
    GROUP BY ProductID
), purchase_prices AS (
    SELECT ProductID, SUM(LineTotal) / SUM(OrderQty) AS UnitPurchasePrice
    FROM adventureworks.gold.fact_purchases
    GROUP BY ProductID
)
SELECT s.ProductID, s.UnitNetSalesPrice, p.UnitPurchasePrice,
       s.UnitNetSalesPrice - p.UnitPurchasePrice AS MarginPerUnit
FROM sales_prices s
INNER JOIN purchase_prices p ON s.ProductID = p.ProductID;

SELECT COUNT(*) AS ProductsInBothFacts FROM margins;
SELECT * FROM margins ORDER BY MarginPerUnit, ProductID LIMIT 5;

-- COMMAND ----------

-- 6. Monthly sales quantities greater than purchase-order quantities

-- Purchased means ordered, not received. This does not prove a stock shortage.
CREATE OR REPLACE TEMP VIEW faster AS
WITH sold AS (
    SELECT ProductID, DATE_TRUNC('month', OrderDate) AS Month,
           SUM(CAST(OrderQty AS INT)) AS UnitsSold
    FROM adventureworks.gold.fact_sales
    GROUP BY ProductID, DATE_TRUNC('month', OrderDate)
), bought AS (
    SELECT ProductID, DATE_TRUNC('month', OrderDate) AS Month,
           SUM(CAST(OrderQty AS INT)) AS UnitsPurchased
    FROM adventureworks.gold.fact_purchases
    GROUP BY ProductID, DATE_TRUNC('month', OrderDate)
), monthly AS (
    SELECT COALESCE(s.ProductID, b.ProductID) AS ProductID,
           CAST(COALESCE(s.Month, b.Month) AS DATE) AS Month,
           COALESCE(s.UnitsSold, 0) AS UnitsSold,
           COALESCE(b.UnitsPurchased, 0) AS UnitsPurchased
    FROM sold s
    FULL OUTER JOIN bought b
        ON s.ProductID = b.ProductID AND s.Month = b.Month
)
SELECT * FROM monthly WHERE UnitsSold > UnitsPurchased;

SELECT COUNT(*) AS ProductMonthsSalesOutranPurchases FROM faster;
SELECT * FROM faster ORDER BY Month, ProductID LIMIT 20;
