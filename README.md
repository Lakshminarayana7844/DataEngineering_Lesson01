# DataEngineering_Lesson01

Homework: Build a Purchasing Star and Link It to Sales
(Data Pipelines with Databricks and Fabric, Hochschule Albstadt-Sigmaringen)

The lakehouse holds two star schemas that share silver.dim_product:

- Sales star: gold.fact_sales with silver.dim_product and silver.dim_sales_territory
- Purchasing star: gold.fact_purchases with silver.dim_vendor and the shared silver.dim_product

Files:

- Purchasing_Star_Homework.ipynb - Python version by Bala Sai Kiran Reddy Telluri
- Purchasing_Star_Homework.sql - SQL version by Lakshmi Narayana Reddy Mandi

Both load the raw AdventureWorks CSVs into Bronze, apply the instawdb.sql
column names and types in Silver, build fact_purchases in Gold and answer the
two homework queries (thinnest-margin products; products that sell faster
than they are restocked).
