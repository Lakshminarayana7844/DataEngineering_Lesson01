# Exercise 2: apply the source names and types, then save the sales star.
# The CREATE TABLE script is kept alongside the CSVs for checking the mapping.
def raw(name):
    return spark.read.option('sep','\t').option('header',False).csv(raw_dir+'/'+name+'.csv')
def typed(name):
    df = raw(name)
    assert len(df.columns) == len(columns[name]), (name,len(df.columns),columns[name])
    df = df.toDF(*columns[name])
    exprs = []
    for c in df.columns:
        typ = 'string'
        if c.endswith('ID') or c in ['OrderQty','RevisionNumber','Status','CreditRating','SafetyStockLevel','ReorderPoint','DaysToManufacture']:
            typ = 'int'
        elif c.endswith('Date'):
            typ = 'timestamp'
        elif c in ['LineTotal','UnitPrice','UnitPriceDiscount','SubTotal','TaxAmt','Freight','TotalDue','StandardCost','ListPrice','SalesYTD','SalesLastYear','CostYTD','CostLastYear']:
            typ = 'decimal(38,6)' if c == 'LineTotal' and name == 'SalesOrderDetail' else 'decimal(19,4)'
        elif c in ['ReceivedQty','RejectedQty','StockedQty','Weight']:
            typ = 'decimal(18,4)'
        elif c.endswith('Flag') or c == 'PreferredVendorStatus':
            typ = 'boolean'
        exprs.append(F.col(c).cast(typ).alias(c))
    return df.select(*exprs)
products, territories = typed('Product'), typed('SalesTerritory')
sales_detail, sales_header = typed('SalesOrderDetail'), typed('SalesOrderHeader')
assert sales_header.count() == sales_header.select('SalesOrderID').distinct().count()
fact_sales = sales_detail.join(sales_header.select('SalesOrderID','OrderDate','TerritoryID'), 'SalesOrderID')
assert fact_sales.count() == sales_detail.count()
for name, df in [('dim_product',products),('dim_sales_territory',territories),('fact_sales',fact_sales)]:
    df.write.mode('overwrite').option('overwriteSchema',True).saveAsTable(lesson+'.'+name)
    print(name, df.count())
spark.sql(f'USE CATALOG {catalog}')
spark.sql(f'USE SCHEMA {lesson_schema}')
