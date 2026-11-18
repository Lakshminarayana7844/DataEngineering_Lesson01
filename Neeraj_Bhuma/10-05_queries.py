# Exercise 5: first queries. The preceding SQL cell gives the ten latest sales.
display(spark.sql('SELECT COUNT(*) AS sales_rows, COUNT(DISTINCT ProductID) AS products_sold, (SELECT COUNT(DISTINCT ProductID) FROM dim_product) AS catalog_products FROM fact_sales'))
revenue_sql = '''SELECT f.ProductID, p.Name, SUM(f.LineTotal) AS Revenue
FROM fact_sales f JOIN dim_product p ON f.ProductID=p.ProductID
GROUP BY f.ProductID,p.Name ORDER BY Revenue DESC'''
display(spark.sql(revenue_sql+' LIMIT 10'))
display(spark.sql('SELECT COUNT(*) AS bad_rows FROM fact_sales WHERE LineTotal IS NULL OR LineTotal<0'))
print('If bad amounts appear, quarantine and check the source before calculating revenue. Do not replace missing amounts with zero without a business rule.')
top5 = spark.sql(revenue_sql+' LIMIT 5').toPandas()
import matplotlib.pyplot as plt
fig, ax = plt.subplots(figsize=(10,4))
ax.barh(top5['Name'][::-1], top5['Revenue'].astype(float)[::-1], color='#287b8e')
ax.set_xlabel('Net sales revenue (source monetary units)')
ax.set_title('Top 5 products by revenue')
fig.tight_layout()
display(fig)
