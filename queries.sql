create database clothing_company;
use clothing_company;



CREATE TABLE product_details(
    product_id VARCHAR(20) PRIMARY KEY,
    price int, 
    product_name VARCHAR(255), 
    category_id INTEGER, 
    segment_id INTEGER, 
    style_id INTEGER, 
    category_name VARCHAR(100), 
    segment_name VARCHAR(100), 
    style_name VARCHAR(100) 
);

drop table product_sales;

CREATE TABLE product_sales(
    prod_id VARCHAR(20), -- Assuming prod_id is a string identifier with maximum length 20
    qty INTEGER, -- Assuming qty is an integer
    price INTEGER, -- Assuming price is a decimal number with 10 total digits and 2 decimal places
    discount INTEGER, -- Assuming discount is a decimal number with 10 total digits and 2 decimal places
    member VARCHAR(20), -- Assuming member is a boolean (true/false) value
    txn_id VARCHAR(20), -- Assuming txn_id is a string identifier with maximum length 20
    start_txn_time DATETIME -- Assuming start_txn_time is a timestamp data type
);

select 
*
from product_details;

select*
from product_sales;


# Sales Analysis
# 1. What was the total quantity sold for all products? Result : 45216
select 
sum(qty)
from product_sales;

# 2. What is the total generated revenue for all products before discounts? Result : 1289453
select
sum(qty * price) as product_rev_before_disc
from product_sales;

# 3. What was the total discount amount for all products? Result : 52096.34
select *,
(price * discount) / 100 as discount_amount
from product_sales;

select
sum(price * discount) / 100 as total_discount_amount
from product_sales;

# ========================================================================================
# Transaction Analysis
# ========================================================================================
# 1. How many unique transactions were there? Result : 2500
select
count(distinct txn_id)
from product_sales;

# 2. What is the average unique products purchased in each transaction? result : 6
# berapa rata-rata barang unik yg dibeli setiap transaksi
select
round(avg(unique_products)) as avg_unique_prod
from(
select 
	txn_id,
	count(distinct prod_id) as unique_products
from product_sales
group by txn_id
) as subquery;

# 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
# ada 2500 unique id transaction
select
count(*)
from (
SELECT
  txn_id,
  SUM((qty * price) - ((qty * price * discount) / 100)) AS revenue_per_transaction
FROM 
  product_sales
GROUP BY 
  txn_id
  order by revenue_per_transaction asc
) as subquery;

SELECT
    txn_id,
    SUM((qty * price) - ((qty * price * discount) / 100)) AS revenue_per_transaction,
    NTILE(100) OVER (ORDER BY SUM((qty * price) - ((qty * price * discount) / 100))) AS percentile_group
  FROM 
    product_sales
  GROUP BY 
    txn_id;


SELECT
  MAX(CASE WHEN percentile_group <= 25 THEN revenue_per_transaction END) AS PERCENTILE_25,
  MAX(CASE WHEN percentile_group <= 50 THEN revenue_per_transaction END) AS PERCENTILE_50,
  MAX(CASE WHEN percentile_group <= 75 THEN revenue_per_transaction END) AS PERCENTILE_75
FROM (
  SELECT
    txn_id,
    SUM((qty * price) - ((qty * price * discount) / 100)) AS revenue_per_transaction,
    NTILE(100) OVER (ORDER BY SUM((qty * price) - ((qty * price * discount) / 100))) AS percentile_group # kenapa 100?, karena kita cari percentile
  FROM 
    product_sales
  GROUP BY 
    txn_id
) AS subquery;

# 4. What is the average discount value per transaction? Result : 62.49
select
round(avg(discount_value),2)
from(select
txn_id,
sum((qty * price * discount) / 100) as discount_value
from product_sales
group by txn_id) as subquery;

# 5. What is the percentage split of all transactions for members vs non-members?
select * from product_sales;

select
member,
count(txn_id),
round(count(txn_id) / 2500 * 100,2) as percentage
from(select
distinct txn_id,
member
from product_sales) as subquery
group by member;

# 6. What is the average revenue for member transactions and non-member transactions?
select
member,
sum(revenue),
avg(revenue)as avg_revenue
from (select 
txn_id,
member,
sum((qty * price) - ((qty * price * discount) / 100)) as revenue
from product_sales
group by txn_id, member) as subquery
group by member;

# menghitung berapa member f(995) atau t (1505)
select
count(member)
from (select 
txn_id,
member,
sum((qty * price) - ((qty * price * discount) / 100)) as revenue
from product_sales
group by txn_id, member) as subquery
where member = 'f';


select * from product_sales; # 15095

# ========================================================================================
# Question 3: Product Analysis
# ========================================================================================
# 1. What is the percentage split of total revenue by category?
select * from product_details;

# step 1 kita join table product_details dan product_sales
SELECT ps.prod_id, pd.category_id, ps.qty, ps.price, ps.discount, ps.member, ps.txn_id
FROM product_sales as ps
INNER JOIN product_details as pd ON ps.prod_id = pd.product_id;

# step 2 kita lakukan subquery
select
category_id,
revenue,
revenue / total_revenue as percentage
from (select
category_id,
sum((qty * price) - ((qty * price * discount) / 100)) as revenue
from (SELECT ps.prod_id, pd.category_id, ps.qty, ps.price, ps.discount, ps.member, ps.txn_id
FROM product_sales as ps
INNER JOIN product_details as pd ON ps.prod_id = pd.product_id) as subquery
group by category_id) as subquery
cross join (
select 
sum((qty * price) - ((qty * price * discount) / 100)) as total_revenue
from product_sales
) as total_sales;

# 2. What is the total transaction “penetration” for each product? 
# (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
# Insights:
select
prod_id,
total_transactions_each_product,
total_transactions_each_product / total_transactions as penetration
from (SELECT ps.prod_id, COUNT(DISTINCT ps.txn_id) AS total_transactions_each_product
    FROM product_sales ps
    JOIN product_details pd ON ps.prod_id = pd.product_id
    GROUP BY ps.prod_id) as subquery
cross join (
select
count(distinct txn_id) as total_transactions
from product_sales
)as total_transactions;

SELECT ps.prod_id, COUNT(DISTINCT ps.txn_id) AS total_transactions_each_product
    FROM product_sales ps
    JOIN product_details pd ON ps.prod_id = pd.product_id
    GROUP BY ps.prod_id;

select count(distinct product_id) from product_details;
# cek berapa unique txn_id untuk product 'c4a632' yaitu 1274
select prod_id, count(txn_id) from product_sales where prod_id = 'c4a632' ;
SELECT * from product_sales;


# 3. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
select * from product_details;

# nah disini kita checking apakah bener query kita
select * 
from product_sales as ps
join product_details as pd on ps.prod_id = pd.product_id
where prod_id in ('2a2353','2feb6b','5d267b');

# check apakah di txn_id mengandung 3 products tersebut
select * 
from product_sales as ps
join product_details as pd on ps.prod_id = pd.product_id
where txn_id = '54f307';


# 2a2353,2feb6b,5d267b
WITH TransactionProductCombinations AS (
    SELECT txn_id, 
           GROUP_CONCAT(DISTINCT prod_id ORDER BY prod_id) AS product_ids,
           COUNT(*) AS occurrence
    FROM product_sales
    WHERE qty > 0
    GROUP BY txn_id
),
ProductCombinations AS (
    SELECT SUBSTRING_INDEX(product_ids, ',', 3) AS combination
    FROM TransactionProductCombinations
    WHERE CHAR_LENGTH(product_ids) - CHAR_LENGTH(REPLACE(product_ids, ',', '')) >= 2
),
MostCommonCombinations AS (
    SELECT combination,
           COUNT(*) AS frequency
    FROM ProductCombinations
    GROUP BY combination
    ORDER BY frequency DESC
    LIMIT 1
)
SELECT mc.combination, mc.frequency
FROM MostCommonCombinations mc;






