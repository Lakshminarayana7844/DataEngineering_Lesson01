# Neeraj Bhuma: Lesson 1 and purchasing homework

Fresh implementation for the shared course repository. Existing team files are not changed.

## Run order
1. `Lesson01_Neeraj_Bhuma.ipynb`: setup, sales-star load, workspace notes, join checks, SQL queries, revenue chart, profiling and the confirmed Hello World team.
2. `Purchasing_Star_Neeraj_Bhuma.ipynb`: purchasing Bronze, Silver and Gold, followed by both cross-star queries. It includes its own setup cells.

The separate `.py` files have been replaced by `Neeraj_Bhuma_Simple.ipynb`.

## Simple notebook
`Neeraj_Bhuma_Simple.ipynb` is a separate beginner-friendly version of all the Python-file work. It uses explicit column names and casts, short Python cells, and SQL joins and summaries. Run it from top to bottom on Free Edition Serverless. It uses the existing `adventure_works` catalog and the same source data and table names. It does not depend on running the older notebooks first.

The two original notebooks above are unchanged. The runtime results below describe those original runs. The simple version was checked separately on 18 November 2026: all 70 code cells completed successfully on Free Edition Serverless. Query 1 gives the same five products and margins listed below; Query 2 gives the same 3,727 product-months and the same largest gap. Its saved results are in the new DataEngineering_Lesson01 Git folder in Databricks.

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

## Checked in Databricks on 18 November 2026
All eight Lesson 1 code cells and all three purchasing code cells completed successfully on Free Edition Serverless. The requested `adventure_works` catalog was created, so the fallback was not needed.

| Check | Result |
|---|---:|
| Sales fact rows | 121,317 |
| Distinct sales line IDs | 121,317 |
| Products in the dimension | 504 |
| Products sold | 266 |
| Territories | 10 |
| Purchase detail before / after cleaning | 8,845 / 8,845 |
| Purchase headers | 4,012 |
| Vendors | 104 |
| Gold purchase fact rows | 8,845 |
| Product-months where sold exceeds purchased | 3,727 |

### Query 1: five lowest margins per unit
| ProductID | Product | Sales price | Purchase price | Margin |
|---|---|---:|---:|---:|
| 948 | Front Brakes | 63.750711 | 82.834500 | -19.083789 |
| 907 | Rear Brakes | 63.900000 | 82.834500 | -18.934500 |
| 937 | HL Mountain Pedal | 48.430988 | 62.989500 | -14.558512 |
| 932 | ML Road Tire | 24.990000 | 39.458267 | -14.468267 |
| 940 | HL Road Pedal | 48.594000 | 62.989500 | -14.395500 |

Ties use ProductID order. Negative values mean the weighted net selling price is below the weighted purchase price under this definition, not total accounting profit.

### Query 2: largest monthly gap
Product 870, Water Bottle - 30 oz., March 2025: 673 units sold and zero units purchased that month, a gap of 673. There are 3,727 matching product-months in total. The full results are saved in `adventure_works.gold.query2_monthly_quantity_gaps`; Query 1 is saved in `adventure_works.gold.query1_lowest_margins`.

### UI steps
The Git folder was cloned into the workspace. Genie Code read the schema reference from the raw-data volume for Exercise 2 and explained duplicate dimension keys for Exercise 4. A duplicate ProductID matches each sales line more than once, so aggregation repeats its revenue. The notebook checks dimension keys and join row counts rather than trusting a join to warn about this.

The committed notebooks contain the runnable source. Execution results are retained in the Databricks workspace and summarized above. No instructor invitation or submission was made.
