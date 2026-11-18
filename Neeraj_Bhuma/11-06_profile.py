# Exercise 6: profile the sales star.
for name,key in [('fact_sales','SalesOrderDetailID'),('dim_product','ProductID'),('dim_sales_territory','TerritoryID')]:
    display(spark.sql(f'DESCRIBE {name}'))
    display(spark.sql(f"SELECT '{name}' AS table_name, COUNT(*) AS rows, COUNT(DISTINCT {key}) AS distinct_keys FROM {name}"))
display(spark.sql('SELECT COUNT(*) AS orphaned_sales FROM fact_sales f LEFT JOIN dim_product p ON f.ProductID=p.ProductID WHERE p.ProductID IS NULL'))
display(spark.sql('SELECT COUNT(*) AS unsold_products FROM dim_product p LEFT JOIN fact_sales f ON p.ProductID=f.ProductID WHERE f.ProductID IS NULL'))
print('An orphan is a sale whose product is missing. An unsold product exists in the catalog but has no sales lines; that is not an orphan sale.')
display(spark.sql('''SELECT f.ProductID,p.Name,COUNT(*) AS order_line_count,COUNT(DISTINCT f.SalesOrderID) AS distinct_orders,SUM(f.OrderQty) AS units FROM fact_sales f JOIN dim_product p ON f.ProductID=p.ProductID GROUP BY f.ProductID,p.Name ORDER BY order_line_count DESC LIMIT 10'''))
display(spark.sql('''SELECT COALESCE(p.ProductLine,'Unspecified') AS ProductLine,SUM(f.LineTotal) AS revenue FROM fact_sales f JOIN dim_product p ON f.ProductID=p.ProductID GROUP BY p.ProductLine ORDER BY revenue DESC'''))
