# Exercise 3: workspace notes and table inspection.
print('Workspace: stores folders, notebooks and Git folders.')
print('Catalog: lists schemas, tables, volumes and permissions.')
print('Compute: runs code; this notebook uses the Free Edition serverless option.')
print('Jobs & Pipelines: schedules notebooks and coordinates dependent tasks.')
print('Data Ingestion: brings source data into the lakehouse.')
display(spark.sql(f'SHOW TABLES IN {lesson}'))
for name in ['fact_sales','dim_product','dim_sales_territory']:
    display(spark.sql(f'DESCRIBE {lesson}.{name}'))
    display(spark.sql(f'SELECT COUNT(*) AS row_count FROM {lesson}.{name}'))
