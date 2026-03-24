<img width="344" height="376" alt="5" src="https://github.com/user-attachments/assets/eac6f854-d94f-4601-bf8b-dc00b559f933" /># Case Study #5: Data Mart
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
<img width="344" height="376" alt="5" src="https://github.com/user-attachments/assets/cad51c02-9623-4961-9b69-1a9df88d03e7" />

## Questions and Answers
### Data Cleansing Steps

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

### Data Exploration

#### 1. What day of the week is used for each `week_date` value?

```sql
SELECT DISTINCT
TO_CHAR(week_date,'Day') AS day_of_week
FROM data_mart.clean_weekly_sales;
```

##### Answer

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

#### 3. How many total `transactions` were there for each year?

```sql
SELECT
calendar_year,
SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
| calendar_year | total_transactions|
|---------------|-------------------|
|          2018 |          346406460|
|          2019 |          365639285|
|          2020 |          375813651|

#### 4. Total `sales` for each `region` for each month

```sql
SELECT
region,
month_number,
SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```

|    region     | month_number | total_sales|
|---------------|--------------|------------|
| AFRICA        |            3 |   567767480|
| AFRICA        |            4 |  1911783504|
| AFRICA        |            5 |  1647244738|
| AFRICA        |            6 |  1767559760|
| AFRICA        |            7 |  1960219710|
| AFRICA        |            8 |  1809596890|
| AFRICA        |            9 |   276320987|
| ASIA          |            3 |   529770793|
|...|...|...|

#### 5. Total count of `transactions` for each `platform`

```sql
SELECT
platform,
SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform;
```
| month_number | platform | pct_sales|
|--------------|----------|----------|
|            3 | Retail   |     97.54|
|            3 | Shopify  |      2.46|
|            4 | Retail   |     97.59|
|            4 | Shopify  |      2.41|
|            5 | Retail   |     97.30|
|            5 | Shopify  |      2.70|
|            6 | Shopify  |      2.73|
|            6 | Retail   |     97.27|
|            7 | Shopify  |      2.71|
|            7 | Retail   |     97.29|
|            8 | Retail   |     97.08|
|            8 | Shopify  |      2.92|
|            9 | Retail   |     97.38|
|            9 | Shopify  |      2.62|


#### 6. Percentage of `sales` for Retail vs Shopify for each month

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

| month_number | platform | pct_sales|
|--------------|----------|----------|
|            3 | Retail   |     97.54|
|            3 | Shopify  |      2.46|
|            4 | Retail   |     97.59|
|            4 | Shopify  |      2.41|
|            5 | Retail   |     97.30|
|            5 | Shopify  |      2.70|
|            6 | Shopify  |      2.73|
|            6 | Retail   |     97.27|
|            7 | Shopify  |      2.71|
|            7 | Retail   |     97.29|
|            8 | Retail   |     97.08|
|            8 | Shopify  |      2.92|
|            9 | Retail   |     97.38|
|            9 | Shopify  |      2.62|
            

#### 7. Percentage of `sales` by `demographic` for each year

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

| calendar_year | demographic | pct_sales|
|---------------|-------------|----------|
|          2018 | Couples     |     26.38|
|          2018 | Families    |     31.99|
|          2018 | unknown     |     41.63|
|          2019 | Couples     |     27.28|
|          2019 | unknown     |     40.25|
|          2019 | Families    |     32.47|
|          2020 | Couples     |     28.72|
|          2020 | Families    |     32.73|
|          2020 | unknown     |     38.55|


#### 8. Which `age_band` and `demographic` contribute the most to Retail sales?

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

|   age_band   | demographic | total_sales|
|--------------|-------------|------------|
| unknown      | unknown     | 16067285533|
| Retirees     | Families    |  6634686916|
| Retirees     | Couples     |  6370580014|
| Middle Aged  | Families    |  4354091554|
| Young Adults | Couples     |  2602922797|
| Middle Aged  | Couples     |  1854160330|
| Young Adults | Families    |  1770889293|

Apart from the unknown age band from the unknown demographic, which might consist many different groups within the category and thus is not useful for interpretation and analysis, the `age_band` and `demographic` that contribute the most to Retail sales are `Retirees` and `Families`

#### 9. Can `avg_transaction` be used to calculate average `transaction` size?

No, because **avg_transaction is calculated per row**, averaging those values would produce a biased result.

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

| calendar_year | platform | avg_transaction_size|
|---------------|----------|---------------------|
|          2018 | Retail   |                36.00|
|          2018 | Shopify  |               192.00|
|          2019 | Retail   |                36.00|
|          2019 | Shopify  |               183.00|
|          2020 | Retail   |                36.00|
|          2020 | Shopify  |               179.00|

---

### Before & After Analysis

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
),

aggregated AS (
    SELECT
        period,
        SUM(sales) AS total_sales
    FROM periods
    GROUP BY period
),

pivoted AS (
    SELECT
        MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN period = 'After' THEN total_sales END) AS after_sales
    FROM aggregated
)

SELECT
    before_sales,
    after_sales,
    (after_sales - before_sales) AS absolute_change,
    ROUND(
        (after_sales - before_sales) * 100.0 / before_sales,
        2
    ) AS percentage_change
FROM pivoted;
```

| before_sales | after_sales | absolute_change | percentage_change|
|--------------|-------------|-----------------|------------------|
|   2345878357 |  2318994169 |       -26884188 |             -1.15|


#### 2. Sales 12 weeks before and after

```sql
WITH baseline AS (
    SELECT *
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
),

periods AS (
    SELECT
        CASE
            WHEN week_date BETWEEN DATE '2020-03-23' AND DATE '2020-06-14' THEN 'Before'
            WHEN week_date BETWEEN DATE '2020-06-15' AND DATE '2020-09-06' THEN 'After'
        END AS period,
        sales
    FROM baseline
),

aggregated AS (
    SELECT
        period,
        SUM(sales) AS total_sales
    FROM periods
    GROUP BY period
),

pivoted AS (
    SELECT
        MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN period = 'After' THEN total_sales END) AS after_sales
    FROM aggregated
)

SELECT
    before_sales,
    after_sales,
    (after_sales - before_sales) AS absolute_change,
    ROUND(
        (after_sales - before_sales) * 100.0 / before_sales,
        2
    ) AS percentage_change
FROM pivoted;
```
 before_sales | after_sales | absolute_change | percentage_change|
--------------+-------------+-----------------+------------------|
   7126273147 |  6973947753 |      -152325394 |             -2.14|


#### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
```sql
WITH baseline AS (
    SELECT *
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year IN (2018, 2019, 2020)
),

periods AS (
    SELECT
        calendar_year,
        CASE
            WHEN week_number BETWEEN 13 AND 24 THEN 'Before'
            WHEN week_number BETWEEN 25 AND 36 THEN 'After'
        END AS period,
        sales
    FROM baseline
),

aggregated AS (
    SELECT
        calendar_year,
        period,
        SUM(sales) AS total_sales
    FROM periods
    WHERE period IS NOT NULL
    GROUP BY calendar_year, period
),

pivoted AS (
    SELECT
        calendar_year,
        MAX(CASE WHEN period = 'Before' THEN total_sales END) AS before_sales,
        MAX(CASE WHEN period = 'After' THEN total_sales END) AS after_sales
    FROM aggregated
    GROUP BY calendar_year
)

SELECT
    calendar_year,
    before_sales,
    after_sales,
    (after_sales - before_sales) AS absolute_change,
    ROUND(
        (after_sales - before_sales) * 100.0 / before_sales,
        2
    ) AS percentage_change
FROM pivoted
ORDER BY calendar_year;
```

| calendar_year | before_sales | after_sales | absolute_change | percentage_change|
|---------------| -------------|-------------|-----------------|------------------|
|          2018 |   6396562317 |  6500818510 |       104256193 |              1.63|
|          2019 |   6883386397 |  6862646103 |       -20740294 |             -0.30|
|          2020 |   7126273147 |  6973947753 |      -152325394 |             -2.14|

Looking at 2018 and 2019, I see a fairly stable pattern between the two periods. Sales either grow slightly (+1.63% in 2018) or stay almost flat (−0.30% in 2019), which suggests that this time window doesn’t naturally produce a decline.

In 2020, that pattern clearly breaks. Sales drop by −2.14%, which is both the largest change and a reversal in direction compared to 2018. Even relative to 2019, the decline is noticeably stronger.

Because I’m comparing the same weeks across years, I can rule out seasonality as the main driver. This makes it more likely that the 2020 drop reflects an external shock rather than normal variation. I also notice a progression from growth (2018) to stagnation (2019) to contraction (2020), which suggests the shock in 2020 amplified an already weakening trend.

---

### Bonus Question

#### Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

```sql
WITH sales_change AS (
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
  WHERE region != 'unknown'
    AND platform != 'unknown'
    AND age_band != 'unknown'
    AND demographic != 'unknown'
    AND customer_type != 'unknown'
  GROUP BY
    region, platform, age_band, demographic, customer_type
)

SELECT *
FROM sales_change
WHERE sales_change < 0
ORDER BY sales_change ASC
LIMIT 1;
```

| region  | platform | age_band | demographic | customer_type | sales_change|
|---------|----------|----------|-------------|---------------|-------------|
| OCEANIA | Retail   | Retirees | Couples     | Existing      |    -1187100|

#### Recommendations

The largest decline is concentrated in the **OCEANIA – Retail – Retirees – Couples – Existing customers** segment, indicating that the impact is highly localized rather than systemic across the business.

I would recommend focusing on **targeted recovery efforts** for this segment. Since the decline is driven by existing customers, the priority should be retention—specifically re-engagement campaigns, personalized offers, and identifying potential friction points in their experience.

From a channel perspective, the underperformance of the Retail platform suggests possible operational or experience-related issues. Investigating factors such as pricing, product availability, or in-store experience could help explain the drop and guide improvements.

The fact that retirees and couples are most affected also points to a demographic-specific shift in behavior. This segment may be more sensitive to changes, so tailored messaging or incentives may be required to win them back.

Overall, the key insight is that the decline is driven by a very specific customer segment. Addressing this group directly is likely to be more effective than applying broad, undifferentiated strategies across the entire customer base.
