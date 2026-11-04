-- Databricks notebook source
-- Homework: Build a Purchasing Star and Link It to Sales (SQL version)
-- Author: Lakshmi Narayana Reddy Mandi
-- Adapted from the Python notebook by my teammate Bala Sai Kiran Reddy Telluri.
-- Run top to bottom in Databricks (Runtime 13.3 LTS+, Unity Catalog).
-- Uses the existing sales star: gold.fact_sales, silver.dim_product and
-- silver.dim_sales_territory.
-- The first Bronze CREATE fails if the table already exists, same as the
-- Python notebook. The rest use IF NOT EXISTS, so nothing is overwritten.

-- COMMAND ----------

-- 1. Bronze: load the 3 raw CSVs as staging tables.
-- Columns stay as _c0, _c1, ... and are fixed in Silver.

CREATE OR REPLACE TEMP VIEW raw_purchase_order_detail AS
SELECT * FROM read_files(
    '/Volumes/adventureworks/default/raw_data/PurchaseOrderDetail.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING, _c8 STRING, _c9 STRING, _c10 STRING'
);

CREATE TABLE adventureworks.bronze.stg_purchase_order_detail AS
SELECT * FROM raw_purchase_order_detail;

CREATE OR REPLACE TEMP VIEW raw_purchase_order_header AS
SELECT * FROM read_files(
    '/Volumes/adventureworks/default/raw_data/PurchaseOrderHeader.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING, _c8 STRING, _c9 STRING, _c10 STRING, _c11 STRING, _c12 STRING'
);

CREATE TABLE IF NOT EXISTS adventureworks.bronze.stg_purchase_order_header AS
SELECT * FROM raw_purchase_order_header;

CREATE OR REPLACE TEMP VIEW raw_vendor AS
SELECT * FROM read_files(
    '/Volumes/adventureworks/default/raw_data/Vendor.csv',
    format => 'csv', header => false, sep => '\t',
    schema => '_c0 STRING, _c1 STRING, _c2 STRING, _c3 STRING, _c4 STRING, _c5 STRING, _c6 STRING, _c7 STRING'
);

CREATE TABLE IF NOT EXISTS adventureworks.bronze.dim_vendor AS
SELECT * FROM raw_vendor;

-- COMMAND ----------

-- 2. Silver: apply the real column names and types from instawdb.sql.
-- On the detail table also drop rows with NULL ProductID or negative LineTotal.

CREATE SCHEMA IF NOT EXISTS adventureworks.silver;

CREATE TABLE IF NOT EXISTS adventureworks.silver.stg_purchase_order_detail AS
WITH typed AS (
    SELECT
        CAST(_c0 AS INT) AS PurchaseOrderID,
        CAST(_c1 AS INT) AS PurchaseOrderDetailID,
        CAST(_c2 AS TIMESTAMP) AS DueDate,
        CAST(_c3 AS SMALLINT) AS OrderQty,
        CAST(_c4 AS INT) AS ProductID,
        CAST(_c5 AS DECIMAL(19,4)) AS UnitPrice,
        CAST(_c6 AS DECIMAL(19,4)) AS LineTotal,
        CAST(_c7 AS DECIMAL(8,2)) AS ReceivedQty,
        CAST(_c8 AS DECIMAL(8,2)) AS RejectedQty,
        CAST(_c9 AS DECIMAL(8,2)) AS StockedQty,
        CAST(_c10 AS TIMESTAMP) AS ModifiedDate
    FROM adventureworks.bronze.stg_purchase_order_detail
)
SELECT * FROM typed
WHERE ProductID IS NOT NULL
  AND (LineTotal IS NULL OR LineTotal >= 0);

CREATE TABLE IF NOT EXISTS adventureworks.silver.stg_purchase_order_header AS
SELECT
    CAST(_c0 AS INT) AS PurchaseOrderID,
    CAST(_c1 AS TINYINT) AS RevisionNumber,
    CAST(_c2 AS TINYINT) AS Status,
    CAST(_c3 AS INT) AS EmployeeID,
    CAST(_c4 AS INT) AS VendorID,
    CAST(_c5 AS INT) AS ShipMethodID,
    CAST(_c6 AS TIMESTAMP) AS OrderDate,
    CAST(_c7 AS TIMESTAMP) AS ShipDate,
    CAST(_c8 AS DECIMAL(19,4)) AS SubTotal,
    CAST(_c9 AS DECIMAL(19,4)) AS TaxAmt,
    CAST(_c10 AS DECIMAL(19,4)) AS Freight,
    CAST(_c11 AS DECIMAL(19,4)) AS TotalDue,
    CAST(_c12 AS TIMESTAMP) AS ModifiedDate
FROM adventureworks.bronze.stg_purchase_order_header;

CREATE TABLE IF NOT EXISTS adventureworks.silver.dim_vendor AS
SELECT
    CAST(_c0 AS INT) AS BusinessEntityID,
    _c1 AS AccountNumber,
    _c2 AS Name,
    CAST(_c3 AS TINYINT) AS CreditRating,
    CAST(_c4 AS BOOLEAN) AS PreferredVendorStatus,
    CAST(_c5 AS BOOLEAN) AS ActiveFlag,
    _c6 AS PurchasingWebServiceURL,
    CAST(_c7 AS TIMESTAMP) AS ModifiedDate
FROM adventureworks.bronze.dim_vendor;

-- COMMAND ----------

-- 3. Gold: join detail to header on PurchaseOrderID to add VendorID and
-- OrderDate. One row per purchase-order line, saved as fact_purchases.

CREATE SCHEMA IF NOT EXISTS adventureworks.gold;

CREATE TABLE IF NOT EXISTS adventureworks.gold.fact_purchases AS
SELECT d.*, h.VendorID, h.OrderDate
FROM adventureworks.silver.stg_purchase_order_detail d
JOIN adventureworks.silver.stg_purchase_order_header h
    ON d.PurchaseOrderID = h.PurchaseOrderID;

-- COMMAND ----------

-- 4. Query 1: join fact_sales and fact_purchases on ProductID.
-- The 5 products with the thinnest margin between sales and purchase price.
-- Prices are quantity-weighted averages: SUM(LineTotal) / SUM(OrderQty).

WITH sales_price AS (
    SELECT ProductID, SUM(LineTotal) / SUM(OrderQty) AS SalesUnitPrice
    FROM adventureworks.gold.fact_sales
    GROUP BY ProductID
),
purchase_price AS (
    SELECT ProductID, SUM(LineTotal) / SUM(OrderQty) AS PurchaseUnitPrice
    FROM adventureworks.gold.fact_purchases
    GROUP BY ProductID
)
SELECT s.ProductID,
       s.SalesUnitPrice,
       p.PurchaseUnitPrice,
       s.SalesUnitPrice - p.PurchaseUnitPrice AS MarginPerUnit
FROM sales_price s
JOIN purchase_price p ON s.ProductID = p.ProductID
ORDER BY MarginPerUnit
LIMIT 5;

-- COMMAND ----------

-- 5. Query 2: units sold vs units purchased per product, by month.
-- Products that sell faster than we restock them.

WITH sold AS (
    SELECT ProductID, DATE_TRUNC('month', OrderDate) AS Month,
           SUM(OrderQty) AS UnitsSold
    FROM adventureworks.gold.fact_sales
    GROUP BY ProductID, DATE_TRUNC('month', OrderDate)
),
bought AS (
    SELECT ProductID, DATE_TRUNC('month', OrderDate) AS Month,
           SUM(OrderQty) AS UnitsPurchased
    FROM adventureworks.gold.fact_purchases
    GROUP BY ProductID, DATE_TRUNC('month', OrderDate)
)
SELECT COALESCE(s.ProductID, b.ProductID) AS ProductID,
       COALESCE(s.Month, b.Month) AS Month,
       COALESCE(s.UnitsSold, 0) AS UnitsSold,
       COALESCE(b.UnitsPurchased, 0) AS UnitsPurchased
FROM sold s
FULL JOIN bought b
    ON s.ProductID = b.ProductID AND s.Month = b.Month
WHERE COALESCE(s.UnitsSold, 0) > COALESCE(b.UnitsPurchased, 0)
ORDER BY Month, ProductID;
