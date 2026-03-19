# Case Study #5: Data Mart
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/3653d03e-9d8c-4f68-b894-693fc8efa378" />

'Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

What was the quantifiable impact of the changes introduced in June 2020?
Which platform, region, segment and customer types were the most impacted by this change?
What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?'


## Entity Relationship Diagram


### 1. Data Cleansing Steps

> In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

> - Convert the week_date to a DATE format

> - Add a `week_number` as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

> - Add a `month_number` with the calendar month for each week_date value as the 3rd column

> - Add a `calendar_year` column as the 4th column containing either 2018, 2019 or 2020 values

> - Add a new column called `age_band` after the original segment column using the following mapping on the number inside the segment value

| segment |	 age_band  |
|---------|------------|
|1        |Young Adults|
|2        |Middle Aged |
|3 or 4   |Retirees    |

> - Add a new demographic column using the following mapping for the first letter in the segment values

|segment|	demographic|
|-------|------------|
|C	    |Couples     |
|F	    |Families    |

> - Ensure all `null` string values with an `unknown` string value in the original `segment` column as well as the new `age_band` and `demographic` columns

> - Generate a new `avg_transaction` column as the `sales` value divided by `transactions` rounded to 2 decimal places for each record


```sql
CREATE TABLE data_mart.clean_weekly_sales AS
SELECT
TO_DATE(week_date, 'DD/MM/YY') AS week_date,
EXTRACT(WEEK FROM TO_DATE(week_date,'DD/MM/YY')) AS week_number,
EXTRACT(MONTH FROM TO_DATE(week_date,'DD/MM/YY')) AS month_number,
EXTRACT(YEAR FROM TO_DATE(week_date,'DD/MM/YY')) AS calendar_year,
region,
platform,
segment,

CASE
WHEN segment LIKE '%1' THEN 'Young Adults'
WHEN segment LIKE '%2' THEN 'Middle Aged'
WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
ELSE 'unknown'
END AS age_band,

CASE
WHEN segment LIKE 'C%' THEN 'Couples'
WHEN segment LIKE 'F%' THEN 'Families'
ELSE 'unknown'
END AS demographic,

customer_type,
transactions,
sales,
ROUND(sales::numeric / transactions, 2) AS avg_transaction

FROM data_mart.weekly_sales;
```

---

### 2. Data Exploration

#### 1. What day of the week is used for each week_date value?

```sql
SELECT DISTINCT
TO_CHAR(week_date,'Day') AS day_of_week
FROM data_mart.clean_weekly_sales;
```

##### Answer
All records use **Monday** as the week_date reference.

| day_of_week|
|-------------|
| Monday|

#### 2. What range of week numbers are missing from the dataset?

```sql
SELECT generate_series(1,52) AS week_number
EXCEPT
SELECT DISTINCT week_number
FROM data_mart.clean_weekly_sales
ORDER BY week_number;
```

##### Answer
| week_number|
|------------|
|           1|
|           2|
|           3|
|           4|
|           5|
|           6|
|           7|
|           8|
|           9|
|          10|
|          11|
|          12|
|          37|
|          38|
|          39|
|          40|
|          41|
|          42|
|          43|
|          44|
|          45|
|          46|
|          47|
|          48|
|          49|
|          50|
|          51|
|          52|

The weeks missing from the dataset range from week 13 to week 36.

#### 3. How many total transactions were there for each year?

```sql
SELECT
calendar_year,
SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```


#### 4. Total sales for each region for each month

```sql
SELECT
region,
month_number,
SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```

---

#### 5. Total count of transactions for each platform

```sql
SELECT
platform,
SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform;
```

---

#### 6. Percentage of sales for Retail vs Shopify for each month

```sql
SELECT
month_number,
platform,
ROUND(
100 * SUM(sales) /
SUM(SUM(sales)) OVER (PARTITION BY month_number),
2
) AS pct_sales
FROM data_mart.clean_weekly_sales
GROUP BY month_number, platform
ORDER BY month_number;
```

---

#### 7. Percentage of sales by demographic for each year

```sql
SELECT
calendar_year,
demographic,
ROUND(
100 * SUM(sales) /
SUM(SUM(sales)) OVER (PARTITION BY calendar_year),
2
) AS pct_sales
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, demographic
ORDER BY calendar_year;
```

---

#### 8. Which age_band and demographic contribute the most to Retail sales?

```sql
SELECT
age_band,
demographic,
SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales DESC;
```

---

#### 9. Can avg_transaction be used to calculate average transaction size?

No.

Because **avg_transaction is calculated per row**, averaging those values would produce a biased result.

Correct calculation:

```sql
SELECT
calendar_year,
platform,
ROUND(SUM(sales)/SUM(transactions),2) AS avg_transaction_size
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
```

---

### 3. Before & After Analysis

Baseline date: **2020-06-15**

#### 1. Sales 4 weeks before and after

```sql
WITH baseline AS (
SELECT *
FROM data_mart.clean_weekly_sales
WHERE calendar_year = 2020
),

periods AS (
SELECT
CASE
WHEN week_date BETWEEN DATE '2020-05-18' AND DATE '2020-06-14' THEN 'Before'
WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-07-12' THEN 'After'
END AS period,
sales
FROM baseline
)

SELECT
period,
SUM(sales) AS total_sales
FROM periods
GROUP BY period;
```

Growth rate:

```
growth = (after - before) / before * 100
```

---

#### 2. Sales 12 weeks before and after

```sql
WITH periods AS (
SELECT
CASE
WHEN week_date BETWEEN DATE '2020-03-23' AND DATE '2020-06-14' THEN 'Before'
WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-09-06' THEN 'After'
END AS period,
sales
FROM data_mart.clean_weekly_sales
WHERE calendar_year = 2020
)

SELECT
period,
SUM(sales) AS total_sales
FROM periods
GROUP BY period;
```

---

#### 3. Comparison with 2018 and 2019

```sql
SELECT
calendar_year,
CASE
WHEN week_date BETWEEN DATE '2020-03-23' AND DATE '2020-06-14' THEN 'Before'
WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-09-06' THEN 'After'
END AS period,
SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
WHERE calendar_year IN (2018,2019,2020)
GROUP BY calendar_year, period
ORDER BY calendar_year;
```

---

### 4. Bonus Question

#### Which areas saw the biggest negative impact?

```sql
SELECT
region,
platform,
age_band,
demographic,
customer_type,
SUM(CASE
WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-09-06'
THEN sales END) -
SUM(CASE
WHEN week_date BETWEEN DATE '2020-03-23' AND DATE '2020-06-14'
THEN sales END) AS sales_change
FROM data_mart.clean_weekly_sales
GROUP BY
region, platform, age_band, demographic, customer_type
ORDER BY sales_change;
```

---

### Recommendations

Key strategic observations:

• **Retail sales dominate older demographics**, particularly retirees and families.  
• **Shopify growth indicates strong digital channel potential** and should receive further investment.  
• Packaging changes should be evaluated alongside **regional sales sensitivity**, since some markets may respond differently to sustainability initiatives.  
• Monitoring **average transaction size trends** is critical because small shifts there scale massively across millions of transactions.
