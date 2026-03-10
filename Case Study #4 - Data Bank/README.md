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
| 2020-04-01 | 175 |

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
GROUP BY customer_id, month
)

SELECT *
FROM month_end
ORDER BY customer_id, month;
```

##### Answer
| customer_id | month | closing_balance |
|------------|------|----------------|
| 1 | 2020-01-01 | 312 |
| 1 | 2020-02-01 | 428 |
| 1 | 2020-03-01 | 590 |
| 2 | 2020-01-01 | 549 |
| 2 | 2020-02-01 | 732 |
| ... | ... | ... |

#### 5. What is the percentage of customers who increase their closing balance by more than 5%?

```sql
WITH monthly_balance AS (
SELECT
customer_id,
DATE_TRUNC('month', txn_date) AS month,
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

balance_change AS (
SELECT
customer_id,
month,
balance,
LAG(balance) OVER (PARTITION BY customer_id ORDER BY month) AS prev_balance
FROM monthly_balance
),

growth_customers AS (
SELECT DISTINCT customer_id
FROM balance_change
WHERE prev_balance IS NOT NULL
AND balance > prev_balance * 1.05
)

SELECT
ROUND(
100.0 * COUNT(DISTINCT customer_id) /
(SELECT COUNT(DISTINCT customer_id) FROM customer_transactions),
2
) AS pct_customers_growth
FROM growth_customers;
```

##### Answer
| pct_customers_growth |
|----------------------|
| 41.2 |

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

##### Answer
A running balance is calculated by adding deposits and subtracting purchases and withdrawals cumulatively for each customer ordered by transaction date.

---

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

##### Answer
The closing balance is the maximum running balance recorded for each customer within each month.

---

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

##### Answer
This query returns the minimum, average and maximum running balance observed for each customer across all transactions.

---

#### 4. Using all available data - how much data would be required for each option on a monthly basis?

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

month_end_balance AS (
SELECT
customer_id,
DATE_TRUNC('month', txn_date) AS month,
MAX(balance) AS closing_balance
FROM running_balance
GROUP BY customer_id, month
),

avg_30_balance AS (
SELECT
customer_id,
DATE_TRUNC('month', txn_date) AS month,
ROUND(AVG(balance),2) AS avg_balance
FROM running_balance
GROUP BY customer_id, month
),

max_balance AS (
SELECT
DATE_TRUNC('month', txn_date) AS month,
MAX(balance) AS max_balance
FROM running_balance
GROUP BY month
)

SELECT
m.month,
SUM(m.closing_balance) AS option1_end_month,
SUM(a.avg_balance) AS option2_avg_30_days,
SUM(mx.max_balance) AS option3_realtime
FROM month_end_balance m
JOIN avg_30_balance a
ON m.customer_id = a.customer_id
AND m.month = a.month
JOIN max_balance mx
ON m.month = mx.month
GROUP BY m.month
ORDER BY m.month;
```

##### Answer

| month | option1_end_month | option2_avg_30_days | option3_realtime |
|------|------------------|--------------------|------------------|
| 2020-01-01 | … | … | … |
| 2020-02-01 | … | … | … |
| 2020-03-01 | … | … | … |
| 2020-04-01 | … | … | … |

Option 1 provisions data based on the total of customer closing balances at the end of each month.  
Option 2 provisions data based on the average customer balance within the month.  
Option 3 requires provisioning based on the maximum real-time balance observed in the system during the month.

### D. Extra Challenge

#### 1. Monthly data requirement with daily interest (6% annual, no compounding)

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

daily_interest AS (
SELECT
customer_id,
txn_date,
balance,
balance * (0.06/365) AS daily_interest
FROM running_balance
)

SELECT
DATE_TRUNC('month', txn_date) AS month,
ROUND(SUM(balance + daily_interest),2) AS required_data
FROM daily_interest
GROUP BY month
ORDER BY month;
```

##### Answer
| month | required_data |
|------|--------------|
| 2020-01-01 | … |
| 2020-02-01 | … |
| 2020-03-01 | … |
| 2020-04-01 | … |

---

#### 2. Monthly data requirement with daily compounding interest

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

compound_interest AS (
SELECT
customer_id,
txn_date,
balance * POWER(1 + 0.06/365,1) AS compounded_balance
FROM running_balance
)

SELECT
DATE_TRUNC('month', txn_date) AS month,
ROUND(SUM(compounded_balance),2) AS required_data
FROM compound_interest
GROUP BY month
ORDER BY month;
```

##### Answer
| month | required_data |
|------|--------------|
| 2020-01-01 | … |
| 2020-02-01 | … |
| 2020-03-01 | … |
| 2020-04-01 | … |

---

### Extension Request

#### Investor & Customer Security Insights (Customer Node Analysis)

**Key headline insights**

• Data Bank operates **5 distributed nodes across every region**, creating redundancy and geographic resilience.  
• Customers are **dynamically reallocated between nodes**, reducing risk of localized infrastructure failures.  
• The **average node allocation period (~24 days)** indicates active load balancing and security rotation.  
• Regional infrastructure parity suggests **globally consistent architecture**, preventing weak regional entry points.

These points frame Data Bank as a **distributed and resilient banking infrastructure**, similar to how large cloud providers distribute workloads.

---

### Data Provisioning Options (Management Slide Content)

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
