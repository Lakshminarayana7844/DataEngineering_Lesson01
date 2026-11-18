# Homework: keep Bronze unchanged, clean in Silver, join at line grain in Gold.
for name,target in [('PurchaseOrderDetail','stg_purchase_order_detail'),('PurchaseOrderHeader','stg_purchase_order_header'),('Vendor','dim_vendor')]:
    df = raw(name)
    df.write.mode('overwrite').option('overwriteSchema',True).saveAsTable(bronze+'.'+target)
    print('Bronze',target,df.count(),df.columns)
detail = typed('PurchaseOrderDetail')
before = detail.count()
# Only the two exclusions required by the slide. A NULL amount is retained.
detail = detail.where('ProductID IS NOT NULL AND (LineTotal IS NULL OR LineTotal >= 0)')
print('Purchase detail before:',before,'after:',detail.count(),'dropped:',before-detail.count())
header, vendors = typed('PurchaseOrderHeader'), typed('Vendor')
for name,df in [('stg_purchase_order_detail',detail),('stg_purchase_order_header',header),('dim_vendor',vendors),('dim_product',products),('dim_sales_territory',territories)]:
    df.write.mode('overwrite').option('overwriteSchema',True).saveAsTable(silver+'.'+name)
assert header.count() == header.select('PurchaseOrderID').distinct().count()
fact_purchases = detail.join(header.select('PurchaseOrderID','VendorID','OrderDate'),'PurchaseOrderID')
assert fact_purchases.count() == detail.count()
assert fact_purchases.select('PurchaseOrderID','PurchaseOrderDetailID').distinct().count() == fact_purchases.count()
assert fact_purchases.join(products,'ProductID','left_anti').count() == 0
assert fact_purchases.join(vendors,fact_purchases.VendorID==vendors.BusinessEntityID,'left_anti').count() == 0
fact_purchases.write.mode('overwrite').option('overwriteSchema',True).saveAsTable(gold+'.fact_purchases')
fact_sales.write.mode('overwrite').option('overwriteSchema',True).saveAsTable(gold+'.fact_sales')
print('Gold sales:',fact_sales.count(),'Gold purchases:',fact_purchases.count())
# Query 1: quantity-weighted unit prices. Sales LineTotal includes line discounts.
# Aggregate each fact before joining: a raw fact-to-fact join would multiply lines.
q1 = spark.sql(f'''WITH s AS (
SELECT ProductID,SUM(LineTotal)/SUM(OrderQty) AS sales_price FROM {gold}.fact_sales GROUP BY ProductID),
p AS (SELECT ProductID,SUM(LineTotal)/SUM(OrderQty) AS purchase_price FROM {gold}.fact_purchases GROUP BY ProductID)
SELECT s.ProductID,d.Name,s.sales_price,p.purchase_price,s.sales_price-p.purchase_price AS margin_per_unit
FROM s JOIN p ON s.ProductID=p.ProductID JOIN {silver}.dim_product d ON s.ProductID=d.ProductID
ORDER BY margin_per_unit,s.ProductID LIMIT 5''')
display(q1)
# Query 2: include months where only one side exists, treating missing quantities as zero.
q2 = spark.sql(f'''WITH s AS (
SELECT ProductID,date_trunc('month',OrderDate) AS month,SUM(OrderQty) AS sold FROM {gold}.fact_sales GROUP BY ProductID,date_trunc('month',OrderDate)),
p AS (SELECT ProductID,date_trunc('month',OrderDate) AS month,SUM(OrderQty) AS purchased FROM {gold}.fact_purchases GROUP BY ProductID,date_trunc('month',OrderDate)),
m AS (SELECT COALESCE(s.ProductID,p.ProductID) AS ProductID,COALESCE(s.month,p.month) AS month,COALESCE(s.sold,0) AS sold,COALESCE(p.purchased,0) AS purchased FROM s FULL OUTER JOIN p ON s.ProductID=p.ProductID AND s.month=p.month)
SELECT m.*,d.Name,sold-purchased AS quantity_gap FROM m JOIN {silver}.dim_product d ON m.ProductID=d.ProductID WHERE sold>purchased ORDER BY quantity_gap DESC,m.ProductID,m.month''')
print('Product-months with sold > purchased:',q2.count())
display(q2)
print('Purchase quantity means units ordered, not receipts. A monthly gap alone does not prove a stockout; opening stock and lead times are not modeled.')
q1.write.mode('overwrite').saveAsTable(gold+'.query1_lowest_margins')
q2.write.mode('overwrite').saveAsTable(gold+'.query2_monthly_quantity_gaps')
