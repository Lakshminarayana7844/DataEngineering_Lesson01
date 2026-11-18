# Neeraj Bhuma: Lesson 1 and purchasing homework

Fresh implementation for the shared course repository. Existing team files are not changed.

## Run order
1. `Lesson01_Neeraj_Bhuma.ipynb`: setup, sales-star load, workspace notes, join checks, SQL queries, revenue chart, profiling and the confirmed Hello World team.
2. `Purchasing_Star_Neeraj_Bhuma.ipynb`: purchasing Bronze, Silver and Gold, followed by both cross-star queries. It includes its own setup cells.

The numbered `.py` files contain the same code in small readable sections.

## Two stars
- Sales: `fact_sales`, `dim_product`, `dim_sales_territory`.
- Purchasing: `fact_purchases`, the shared `dim_product`, and `dim_vendor`.

Grain: one row per sales-order line or purchase-order line. The sales header provides the real OrderDate and TerritoryID. ModifiedDate is not used as a substitute order date.

## Storage
The code first tries the requested `adventure_works` catalog. If catalog creation is not available, it uses the `workspace` catalog with explicitly named `adventure_works*` schemas and prints the actual locations. Raw files are saved in a `raw_data` volume. No paid compute or cloud account is provisioned.

## Query definitions
Query 1 uses quantity-weighted net unit sales price minus quantity-weighted unit purchase price. LineTotal includes sales discounts. Each fact is aggregated by product before joining, avoiding fact-to-fact fan-out. This is one explicit interpretation of the slide's margin question.

Query 2 aggregates units ordered on each side by product and calendar month. A full outer join keeps months with no purchases or no sales. Missing quantities are zero. The result filters for units sold greater than units purchased. This does not by itself prove a stockout: opening stock, receipts and lead times are outside the exercise.

The cleaning rule removes NULL ProductID and negative LineTotal, without silently discarding NULL LineTotal. Assertions check grain, references and join row counts.

## Sources
- https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/oltp-install-script
- https://github.com/microsoft/sql-server-samples/blob/master/samples/databases/adventure-works/oltp-install-script/instawdb.sql

Column names are extracted from CREATE TABLE statements, including computed fields that are present in the CSV. The notebooks download the source files directly; no raw data needs to be committed here.

## Team
Lakshmi Narayana Reddy Mandi, Neeraj Bhuma, Bala Sai Kiran.

## Scope notes
Notebook code and validation queries are provided here. Successful execution must be checked in the target workspace. Genie Code schema review, workspace-folder setup, and the Databricks Git connection are UI steps; code existing in GitHub does not prove those steps were completed. No instructor invitation is sent by this code.
