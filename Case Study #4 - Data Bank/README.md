# Case Study #4: Data Bank
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/7a51101a-29b1-4394-a0bf-8d00a1dd4ef7" />
There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Entity Relationship Diagram
## Questions and Solutions

### A. Customer Nodes Exploration

#### 1. How many unique nodes are there on the Data Bank system?

```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
```

##### Answer
| unique_nodes |
|--------------|
| 5 |

#### 2. What is the number of nodes per region?

```sql
SELECT
r.region_name,
COUNT(DISTINCT cn.node_id) AS node_count
FROM customer_nodes cn
JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```

##### Answer
| region_name | node_count |
|-------------|-----------|
| Africa | 5 |
| America | 5 |
| Asia | 5 |
| Australia | 5 |
| Europe | 5 |

#### 3. How many customers are allocated to each region?

```sql
SELECT
r.region_name,
COUNT(DISTINCT cn.customer_id) AS customers
FROM customer_nodes cn
JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY customers DESC;
```

##### Answer
| region_name | customers |
|-------------|-----------|
| Australia | 110 |
| America | 105 |
| Europe | 88 |
| Asia | 70 |
| Africa | 56 |

#### 4. How many days on average are customers reallocated to a different node?

```sql
SELECT
ROUND(AVG(end_date - start_date), 2) AS avg_reallocation_days
FROM customer_nodes
WHERE end_date != '9999-12-31';
```

##### Answer
| avg_reallocation_days |
|-----------------------|
| 24 |

#### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

```sql
WITH durations AS (
SELECT
r.region_name,
(end_date - start_date) AS days
FROM customer_nodes cn
JOIN regions r
ON cn.region_id = r.region_id
WHERE end_date != '9999-12-31'
)

SELECT
region_name,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days) AS median_days,
PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY days) AS p80_days,
PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days) AS p95_days
FROM durations
GROUP BY region_name
ORDER BY region_name;
```

##### Answer
| region_name | median_days | p80_days | p95_days |
|-------------|-------------|----------|----------|
| Africa | 21 | 28 | 30 |
| America | 21 | 28 | 30 |
| Asia | 21 | 28 | 30 |
| Australia | 21 | 28 | 30 |
| Europe | 21 | 28 | 30 |

### B. Customer Transactions

#### 1. What is the unique count and total amount for each transaction type?

```sql
SELECT
txn_type,
COUNT(*) AS transaction_count,
SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
ORDER BY txn_type;
```

##### Answer
| txn_type | transaction_count | total_amount |
|---------|------------------|-------------|
| deposit | 2671 | 1359168 |
| purchase | 1617 | 806537 |
| withdrawal | 1580 | 793003 |

#### 2. What is the average total historical deposit counts and amounts for all customers?

```sql
WITH deposit_stats AS (
SELECT
customer_id,
COUNT(*) AS deposit_count,
SUM(txn_amount) AS deposit_amount
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)

SELECT
ROUND(AVG(deposit_count),2) AS avg_deposit_count,
ROUND(AVG(deposit_amount),2) AS avg_deposit_amount
FROM deposit_stats;
```

##### Answer
| avg_deposit_count | avg_deposit_amount |
|------------------|--------------------|
| 5.34 | 2718.34 |

#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql
WITH monthly_txns AS (
SELECT
customer_id,
DATE_TRUNC('month', txn_date) AS month,
SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposits,
SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawals
FROM customer_transactions
GROUP BY customer_id, month
)

SELECT
month,
COUNT(customer_id) AS customers
FROM monthly_txns
WHERE deposits > 1
AND (purchases >= 1 OR withdrawals >= 1)
GROUP BY month
ORDER BY month;
```

##### Answer
| month | customers |
|------|----------|
| 2020-01-01 | 168 |
| 2020-02-01 | 181 |
| 2020-03-01 | 192 |
| 2020-04-01 | 70  |

#### 4. What is the closing balance for each customer at the end of the month?

```sql
WITH running_balance AS (
  SELECT
    customer_id,
    txn_date,
    SUM(
      CASE
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type IN ('purchase','withdrawal') THEN -txn_amount
      END
    ) OVER (
      PARTITION BY customer_id
      ORDER BY txn_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS balance
  FROM customer_transactions
),

month_end AS (
  SELECT
    customer_id,
    DATE_TRUNC('month', txn_date) AS month,
    MAX(balance) AS closing_balance
  FROM running_balance
  GROUP BY customer_id, DATE_TRUNC('month', txn_date)
),

months AS (
  SELECT generate_series(
    (SELECT MIN(month) FROM month_end),
    (SELECT MAX(month) FROM month_end),
    INTERVAL '1 month'
  ) AS month
),

customers AS (
  SELECT DISTINCT customer_id
  FROM customer_transactions
),

customer_months AS (
  SELECT
    c.customer_id,
    m.month
  FROM customers c
  CROSS JOIN months m
),

base AS (
  SELECT
    cm.customer_id,
    cm.month,
    me.closing_balance
  FROM customer_months cm
  LEFT JOIN month_end me
    ON cm.customer_id = me.customer_id
    AND cm.month = me.month
),

filled AS (
  SELECT
    customer_id,
    month,
    closing_balance,
    -- create groups that reset whenever we see a non-null balance
    COUNT(closing_balance) OVER (
      PARTITION BY customer_id
      ORDER BY month
    ) AS grp
  FROM base
)

SELECT
  customer_id,
  month,
  MAX(closing_balance) OVER (
    PARTITION BY customer_id, grp
  ) AS closing_balance
FROM filled
ORDER BY customer_id, month;
```

##### Answer
| customer_id |    month   | closing_balance|
|-------------|------------|----------------|
|           1 | 2020-01-01 |             312|
|           1 | 2020-02-01 |             312|
|           1 | 2020-03-01 |              24|
|           1 | 2020-04-01 |              24|
|           2 | 2020-01-01 |             549|
|...|...|...|

I observe multiple instances where the closing balance remains unchanged across consecutive months. This is primarily due to periods of customer inactivity, where no transactions are recorded. I retain these inactive months with unchanged balances to preserve temporal consistency and ensure the dataset remains suitable for time-based analysis and month-level referencing.

However, unchanged balances should not be interpreted as definitive evidence of inactivity. There may be cases where transactions occur but net to zero, resulting in no change in the closing balance.

#### 5. What is the percentage of customers who increase their closing balance by more than 5%?

```sql
WITH monthly_net AS (
  SELECT
    customer_id,
    DATE_TRUNC('month', txn_date) AS month,
    SUM(
      CASE
        WHEN txn_type = 'deposit' THEN txn_amount
        ELSE -txn_amount
      END
    ) AS net_txn
  FROM customer_transactions
  GROUP BY customer_id, DATE_TRUNC('month', txn_date)
),

monthly_balance AS (
  SELECT
    customer_id,
    month,
    SUM(net_txn) OVER (
      PARTITION BY customer_id
      ORDER BY month
    ) AS balance
  FROM monthly_net
),

growth AS (
  SELECT
    customer_id
  FROM (
    SELECT
      customer_id,
      month,
      balance,
      LAG(balance) OVER (
        PARTITION BY customer_id ORDER BY month
      ) AS prev_balance
    FROM monthly_balance
  ) t
  WHERE prev_balance IS NOT NULL
    AND balance > prev_balance * 1.05
)

SELECT
ROUND(
  100.0 * COUNT(DISTINCT customer_id) /
  (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions),
2
) AS pct_customers_growth
FROM growth;
```

##### Answer
| pct_customers_growth |
|----------------------|
| 71.0 |

### C. Data Allocation Challenge

#### 1. Create a running customer balance column that includes the impact of each transaction

```sql
SELECT
customer_id,
txn_date,
txn_type,
txn_amount,
SUM(
CASE
WHEN txn_type = 'deposit' THEN txn_amount
WHEN txn_type IN ('purchase','withdrawal') THEN -txn_amount
END
) OVER (
PARTITION BY customer_id
ORDER BY txn_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS running_balance
FROM customer_transactions
ORDER BY customer_id, txn_date;
```
| customer_id |  txn_date  |  txn_type  | txn_amount | running_balance|
|-------------|------------|------------|------------|----------------|
|           1 | 2020-01-02 | deposit    |        312 |             312|
|           1 | 2020-03-05 | purchase   |        612 |            -300|
|           1 | 2020-03-17 | deposit    |        324 |              24|
|          ...|...|...|...|           

#### 2. Customer balance at the end of each month

```sql
WITH running_balance AS (
SELECT
customer_id,
txn_date,
SUM(
CASE
WHEN txn_type = 'deposit' THEN txn_amount
WHEN txn_type IN ('purchase','withdrawal') THEN -txn_amount
END
) OVER (
PARTITION BY customer_id
ORDER BY txn_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS balance
FROM customer_transactions
)

SELECT
customer_id,
DATE_TRUNC('month', txn_date) AS month,
MAX(balance) AS closing_balance
FROM running_balance
GROUP BY customer_id, month
ORDER BY customer_id, month;
```

#### 3. Minimum, average and maximum values of the running balance for each customer

```sql
WITH running_balance AS (
SELECT
customer_id,
txn_date,
SUM(
CASE
WHEN txn_type = 'deposit' THEN txn_amount
WHEN txn_type IN ('purchase','withdrawal') THEN -txn_amount
END
) OVER (
PARTITION BY customer_id
ORDER BY txn_date
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS running_balance
FROM customer_transactions
)

SELECT
customer_id,
MIN(running_balance) AS min_balance,
ROUND(AVG(running_balance),2) AS avg_balance,
MAX(running_balance) AS max_balance
FROM running_balance
GROUP BY customer_id
ORDER BY customer_id;
```
| customer_id | min_balance | avg_balance | max_balance|
|-------------|-------------|-------------|------------|
|           1 |        -640 |     -151.00 |         312|
|           2 |         549 |      579.50 |         610|
|           3 |       -1222 |     -732.40 |         144|
|...|...|...|...|

#### 4. Using all available data - how much data would be required for each option on a monthly basis?

For Option 1 (transaction-level storage), every single transaction is stored as its own row. This means the monthly data volume depends directly on how active customers are. If a customer performs multiple transactions per month, each one contributes to storage. In practice, this quickly scales up, since total records ≈ number of customers × average transactions per customer per month. This makes it the most data-intensive option, but also the most flexible, since no information is lost.

For Option 2 (daily balance storage), I aggregate all transactions into a single closing balance per customer per day. Here, the number of records is driven by time rather than activity: each customer contributes up to ~30 records per month (one per day). So total records ≈ number of customers × number of active days. This reduces data volume compared to raw transactions - especially for highly active users - while still preserving short-term trends and behavioral patterns.

For Option 3 (monthly balance storage), the aggregation is pushed even further. Each customer contributes exactly one record per month, regardless of how many transactions occurred. So total records ≈ number of customers × number of months. This is the most storage-efficient approach, but it abstracts away all intra-month variation, meaning I can no longer analyze volatility, transaction timing, or short-term behavioral changes.


### D. Extra Challenge

I approach this by first converting the annual interest rate into a daily rate, assuming 365 days in a year. Since the requirement specifies non-compounding interest, I calculate daily interest based solely on the daily closing balance without reinvesting the earned interest.

To support this, I construct a daily balance table by generating a continuous date series and forward-filling each customer’s balance for days without transactions. This ensures that interest is calculated consistently for every day, including inactive periods.

I then compute daily interest as a function of the daily balance and aggregate the results at the monthly level to estimate the total data growth required under this model.

#### 1. Daily balance

```sql
WITH running_balance AS (
  SELECT
    customer_id,
    txn_date,
    SUM(
      CASE
        WHEN txn_type = 'deposit' THEN txn_amount
        ELSE -txn_amount
      END
    ) OVER (
      PARTITION BY customer_id
      ORDER BY txn_date
    ) AS balance
  FROM customer_transactions
),

dates AS (
  SELECT generate_series(
    (SELECT MIN(txn_date) FROM customer_transactions),
    (SELECT MAX(txn_date) FROM customer_transactions),
    INTERVAL '1 day'
  ) AS date
),

customers AS (
  SELECT DISTINCT customer_id FROM customer_transactions
),

customer_days AS (
  SELECT c.customer_id, d.date
  FROM customers c
  CROSS JOIN dates d
),

daily_balance AS (
  SELECT
    cd.customer_id,
    cd.date,
    rb.balance
  FROM customer_days cd
  LEFT JOIN running_balance rb
    ON cd.customer_id = rb.customer_id
    AND cd.date = rb.txn_date
),

filled AS (
  SELECT
    customer_id,
    date,
    balance,
    COUNT(balance) OVER (
      PARTITION BY customer_id ORDER BY date
    ) AS grp
  FROM daily_balance
),

final_balance AS (
  SELECT
    customer_id,
    date,
    MAX(balance) OVER (
      PARTITION BY customer_id, grp
    ) AS balance
  FROM filled
)
```

#### 2. Calculate Daily Interest
```sql
, interest_calc AS (
  SELECT
    customer_id,
    date,
    balance,
    balance * (0.06 / 365) AS daily_interest
  FROM final_balance
)
```
#### 3. Aggregate monthly
```sql
SELECT
  DATE_TRUNC('month', date) AS month,
  ROUND(SUM(daily_interest), 2) AS total_interest
FROM interest_calc
GROUP BY month
ORDER BY month;
```
---
### Extension Request

#### Investor & Customer Security Insights (Customer Node Analysis)

**Key headline insights**

• Data Bank operates **5 distributed nodes across every region**, creating redundancy and geographic resilience.  
• Customers are **dynamically reallocated between nodes**, reducing risk of localized infrastructure failures.  
• The **average node allocation period (~24 days)** indicates active load balancing and security rotation.  
• Regional infrastructure parity suggests **globally consistent architecture**, preventing weak regional entry points.

These points frame Data Bank as a **distributed and resilient banking infrastructure**, similar to how large cloud providers distribute workloads.


#### Data Provisioning Options (Management Slide Content)

**Objective:** Estimate infrastructure capacity needed for storing customer data balances.

| Option | Allocation Logic | Risk | Infrastructure Cost |
|------|------------------|------|--------------------|
| Option 1 | End-of-month balance | Low volatility | Low |
| Option 2 | Average balance (30 days) | Smooth demand | Medium |
| Option 3 | Real-time balance | Handles peak demand | High |
| Option 4 | Interest-based balance | Simulates savings growth | Medium–High |

**Recommendation**

Option 2 provides the most balanced provisioning strategy because it smooths short-term fluctuations while remaining realistic to customer behavior.

Option 3 is safest technically but requires significant over-provisioning because the system must handle the highest instantaneous balance.

Option 4 introduces financial-style incentives but increases forecasting complexity due to interest growth dynamics.
