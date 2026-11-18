# Exercise 1: set up raw data. No paid resources are created.
import urllib.request, re, json
from pyspark.sql import functions as F
try:
    spark.sql('CREATE CATALOG IF NOT EXISTS adventure_works')
    catalog, lesson_schema = 'adventure_works', 'default'
except Exception as exc:
    print('Catalog creation is unavailable in this workspace:', str(exc)[:400])
    catalog, lesson_schema = 'workspace', 'adventure_works'
lesson = f'{catalog}.{lesson_schema}'
bronze = f'{catalog}.bronze' if catalog == 'adventure_works' else 'workspace.adventure_works_bronze'
silver = f'{catalog}.silver' if catalog == 'adventure_works' else 'workspace.adventure_works_silver'
gold = f'{catalog}.gold' if catalog == 'adventure_works' else 'workspace.adventure_works_gold'
for schema in [lesson, bronze, silver, gold]:
    spark.sql(f'CREATE SCHEMA IF NOT EXISTS {schema}')
spark.sql(f'CREATE VOLUME IF NOT EXISTS {lesson}.raw_data')
raw_dir = f'/Volumes/{catalog}/{lesson_schema}/raw_data'
base = 'https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/databases/adventure-works/oltp-install-script'
sources = {'SalesOrderDetail':'Sales', 'Product':'Production', 'SalesTerritory':'Sales', 'SalesOrderHeader':'Sales', 'PurchaseOrderDetail':'Purchasing', 'PurchaseOrderHeader':'Purchasing', 'Vendor':'Purchasing'}
for name in list(sources) + ['instawdb']:
    suffix = '.sql' if name == 'instawdb' else '.csv'
    urllib.request.urlretrieve(base+'/'+name+suffix, raw_dir+'/'+name+suffix)
script = open(raw_dir+'/instawdb.sql').read()
# Read column names from CREATE TABLE, including computed columns in the CSV.
columns = {}
for name, schema in sources.items():
    start = script.index(f'CREATE TABLE [{schema}].[{name}]')
    block = script[start:script.index(') ON [PRIMARY]', start)]
    columns[name] = re.findall(r'^\s*\[([^\]]+)\]', block, re.M)
print('Lesson tables:', lesson, 'Bronze:', bronze, 'Silver:', silver, 'Gold:', gold)
display(dbutils.fs.ls(raw_dir))
