# Case Study #2: Pizza Runner
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/b15ec2e5-b2b2-47cc-b70d-e8f1d3e61bea" />

Danny has launched `Pizza Runner`, a pizza delivery startup that combines retro pizza culture with an on-demand delivery model similar to ride-sharing platforms. Customers place pizza orders through a mobile application, and independent delivery runners transport the orders from Danny’s headquarters to customers.

To support the growth of the business, Danny has designed a relational database within the `Pizza Runner` schema to capture key operational data, including customer orders, runner assignments, deliveries, and pizza details. However, the raw data contains inconsistencies and requires cleaning before meaningful analysis can be performed.

The objective of this analysis is to explore, clean, and transform the available datasets to produce reliable insights about Pizza Runner’s operations. This includes preparing the data for analysis, performing basic calculations, and generating metrics that can help Danny better manage his runners and optimize delivery performance.

All datasets used in this analysis are located within the `Pizza Runner` database schema.
## Entity Relationship Diagram
## Data Cleaning
### Table 2: customer_orders
| order_id | customer_id | pizza_id | exclusions | extras | order_time |
|---------|-------------|----------|------------|--------|------------|
| 1 | 101 | 1 |  |  | 2021-01-01 18:05:02 |
| 2 | 101 | 1 |  |  | 2021-01-01 19:00:52 |
| 3 | 102 | 1 |  |  | 2021-01-02 23:51:23 |
| 3 | 102 | 2 |  | NaN | 2021-01-02 23:51:23 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 2 | 4 |  | 2021-01-04 13:23:46 |
| 5 | 104 | 1 | null | 1 | 2021-01-08 21:00:29 |
| 6 | 101 | 2 | null | null | 2021-01-08 21:03:13 |
| 7 | 105 | 2 | null | 1 | 2021-01-08 21:20:29 |
| 8 | 102 | 1 | null | null | 2021-01-09 23:54:33 |
| 9 | 103 | 1 | 4 | 1, 5 | 2021-01-10 11:22:59 |
| 10 | 104 | 1 | null | null | 2021-01-11 18:34:49 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2021-01-11 18:34:49 |

Looking at the `customer_orders` table above, we can see that:
- In the `exclusions` column, there are ` ` (blank values), and `null` values.
- In the `extras` column, there are ` ` (blank values), `NaN` and `null` values.

To clean the `customer_order` table, we will
- Create a temporary table with all the values
- Remove `null` and `NaN` values in exlusions and extras columns and replace with ` ` (blank values).

```sql
SELECT
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions IS NULL OR exclusions IN ('null','NaN')
      THEN ''
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras IS NULL OR extras IN ('null','NaN')
      THEN ''
    ELSE extras
  END AS extras,
  order_time
FROM pizza_runner.customer_orders;
```
#### Result
| order_id | customer_id | pizza_id | exclusions | extras | order_time |
|----------|-------------|----------|------------|--------|------------|
| 1 | 101 | 1 |  |  | 2021-01-01 18:05:02 |
| 2 | 101 | 1 |  |  | 2021-01-01 19:00:52 |
| 3 | 102 | 1 |  |  | 2021-01-02 23:51:23 |
| 3 | 102 | 2 |  |  | 2021-01-02 23:51:23 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 2 | 4 |  | 2021-01-04 13:23:46 |
| 5 | 104 | 1 |  | 1 | 2021-01-08 21:00:29 |
| 6 | 101 | 2 |  |  | 2021-01-08 21:03:13 |
| 7 | 105 | 2 |  | 1 | 2021-01-08 21:20:29 |
| 8 | 102 | 1 |  |  | 2021-01-09 23:54:33 |
| 9 | 103 | 1 | 4 | 1, 5 | 2021-01-10 11:22:59 |
| 10 | 104 | 1 |  |  | 2021-01-11 18:34:49 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2021-01-11 18:34:49 |

This is the table we will use to run all our queries.
### Table 3: runner_orders
| order_id | runner_id | pickup_time | distance | duration | cancellation |
|----------|-----------|-------------|----------|----------|--------------|
| 1 | 1 | 2021-01-01 18:15:34 | 20km | 32 minutes |  |
| 2 | 1 | 2021-01-01 19:10:54 | 20km | 27 minutes |  |
| 3 | 1 | 2021-01-03 00:12:37 | 13.4km | 20 mins | NaN |
| 4 | 2 | 2021-01-04 13:53:03 | 23.4 | 40 | NaN |
| 5 | 3 | 2021-01-08 21:10:57 | 10 | 15 | NaN |
| 6 | 3 | null | null | null | Restaurant Cancellation |
| 7 | 2 | 2020-01-08 21:30:45 | 25km | 25mins | null |
| 8 | 2 | 2020-01-10 00:15:02 | 23.4 km | 15 minute | null |
| 9 | 2 | null | null | null | Customer Cancellation |
| 10 | 1 | 2020-01-11 18:50:20 | 10km | 10minutes | null |

Looking at the `runner_orders` table above, we can see that:
- In the `pickup_time` column, there are `null` values which indicate orders that were never picked up.
- In the `distance` column, there are `null` values and inconsistent formats such as `20km`, `23.4 km`, and values without units like `10` or `23.4`.
- In the `duration` column, there are mixed formats including `32 minutes`, `20 mins`, `25mins`, `15 minute`, and numeric values like `40` or `15`.
- In the `cancellation` column, there are `null`, ` ` blank values, and `NaN` values which represent missing data, while some rows contain explicit cancellation reasons such as `Restaurant Cancellation` and `Customer Cancellation`.

To clean the `runner_orders` table we will:
- Create a temporary table with all the values
- Replace `null` and `NaN` values in the `cancellation` column with blank values to standardize missing data.
- Convert the `pickup_time` column to a consistent datetime format and keep `null` values for orders that were not picked up.
- Remove text such as `km` or extra spaces from the `distance` column and convert the values into a numeric format.
- Remove text such as `minutes`, `minute`, `mins`, and `mins` from the `duration` column and convert the values into a numeric format representing minutes.
- Ensure that `distance` and `duration` columns contain only numeric values so they can be used for calculations and analysis.

```sql
CREATE TEMP TABLE temp_runner_orders AS
SELECT
  order_id,
  runner_id,
  CASE
    WHEN pickup_time = 'null' THEN NULL
    ELSE pickup_time
  END::timestamp AS pickup_time,
  CASE
    WHEN distance IS NULL OR distance IN ('null','NaN') THEN NULL
    ELSE REPLACE(REPLACE(distance, 'km', ''), ' ', '')::numeric
  END AS distance,
  CASE
    WHEN duration IS NULL OR duration IN ('null','NaN') THEN NULL
    ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric
  END AS duration,
  CASE
    WHEN cancellation IN ('null','NaN') THEN ''
    ELSE cancellation
  END AS cancellation
FROM pizza_runner.runner_orders;
```

#### Result 
| order_id | runner_id | pickup_time          | distance | duration | cancellation            |
|----------|-----------|----------------------|----------|----------|-------------------------|
| 1 | 1 | 2021-01-01 18:15:34 | 20   | 32 | |
| 2 | 1 | 2021-01-01 19:10:54 | 20   | 27 | |
| 3 | 1 | 2021-01-03 00:12:37 | 13.4 | 20 | |
| 4 | 2 | 2021-01-04 13:53:03 | 23.4 | 40 | |
| 5 | 3 | 2021-01-08 21:10:57 | 10   | 15 | |
| 6 | 3 | NULL                | NULL | NULL | Restaurant Cancellation |
| 7 | 2 | 2020-01-08 21:30:45 | 25   | 25 | |
| 8 | 2 | 2020-01-10 00:15:02 | 23.4 | 15 | |
| 9 | 2 | NULL                | NULL | NULL | Customer Cancellation   |
| 10| 1 | 2020-01-11 18:50:20 | 10   | 10 | |

This is the table we will use to run all our queries.

## Questions and Solutions
### A. 
