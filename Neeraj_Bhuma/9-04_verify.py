# Exercise 4: grain, dimensions and joins.
display(spark.sql('SELECT COUNT(*) AS total_rows, COUNT(DISTINCT SalesOrderDetailID) AS distinct_detail_ids FROM fact_sales'))
for dim,key in [('dim_product','ProductID'),('dim_sales_territory','TerritoryID')]:
    display(spark.sql(f'''SELECT '{dim}' AS dimension,
      (SELECT COUNT(*) FROM {dim}) AS dimension_rows,
      (SELECT COUNT(*) FROM fact_sales f LEFT JOIN {dim} d ON f.{key}=d.{key}) AS left_join_rows,
      (SELECT COUNT(*) FROM fact_sales f RIGHT JOIN {dim} d ON f.{key}=d.{key}) AS right_join_rows,
      (SELECT COUNT(*) FROM fact_sales f LEFT JOIN {dim} d ON f.{key}=d.{key} WHERE d.{key} IS NULL) AS orphan_fact_rows'''))
    display(spark.sql(f'SELECT {key}, COUNT(*) AS copies FROM {dim} GROUP BY {key} HAVING COUNT(*)>1'))
print('A LEFT JOIN preserves unmatched facts too. An unchanged count rules out fan-out, but orphan checks are needed to prove matches.')
print('A RIGHT JOIN keeps unused dimension rows. Those rows have NULL fact columns, so its count can be higher.')
print('A duplicate ProductID makes every matching sale appear twice. SUM(LineTotal) then counts the same sale twice without a SQL error.')
