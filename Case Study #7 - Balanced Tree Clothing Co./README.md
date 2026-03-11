# Case Study #7: Balanced Tree Clothing Co.
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/24335499-470d-4d93-b154-1c7a6569a59f" />

Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.
## Entity Relational Diagram

## Questions and Answers
### High Level Sales Analysis

#### 1. What was the total quantity sold for all products?

```sql
SELECT
SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;
```

##### Answer

| total_quantity_sold |
|---------------------|
| 45216 |


#### 2. What is the total generated revenue for all products before discounts?

```sql
SELECT
SUM(qty * price) AS total_revenue_before_discount
FROM balanced_tree.sales;
```

##### Answer

| total_revenue_before_discount |
|--------------------------------|
| 1289453 |

#### 3. What was the total discount amount for all products?

```sql
SELECT
ROUND(SUM(qty * price * discount / 100), 2) AS total_discount_amount
FROM balanced_tree.sales;
```

##### Answer

| total_discount_amount |
|-----------------------|
| 156229.14 |

### Transaction Analysis

### Transaction Analysis

#### 1. How many unique transactions were there?

```sql
SELECT
COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;
```

##### Answer

| unique_transactions |
|---------------------|
| 2500 |

There were **2,500 unique transactions** recorded in the dataset.

---

#### 2. What is the average unique products purchased in each transaction?

```sql
WITH product_per_txn AS (
SELECT
txn_id,
COUNT(DISTINCT prod_id) AS unique_products
FROM balanced_tree.sales
GROUP BY txn_id
)

SELECT
ROUND(AVG(unique_products),2) AS avg_unique_products
FROM product_per_txn;
```

##### Answer

| avg_unique_products |
|---------------------|
| 6.04 |

On average, each transaction contained **6.04 unique products**.

---

#### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

```sql
WITH txn_revenue AS (
SELECT
txn_id,
SUM(qty * price) AS revenue
FROM balanced_tree.sales
GROUP BY txn_id
)

SELECT
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) AS p25,
PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY revenue) AS p50,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) AS p75
FROM txn_revenue;
```

##### Answer

| p25 | p50 | p75 |
|----|----|----|
| 376 | 509 | 647 |

• 25% of transactions generated **$376 or less**  
• The median transaction revenue was **$509**  
• 75% of transactions generated **$647 or less**

---

#### 4. What is the average discount value per transaction?

```sql
WITH discount_per_txn AS (
SELECT
txn_id,
SUM(qty * price * discount / 100) AS discount_value
FROM balanced_tree.sales
GROUP BY txn_id
)

SELECT
ROUND(AVG(discount_value),2) AS avg_discount_per_txn
FROM discount_per_txn;
```

##### Answer

| avg_discount_per_txn |
|----------------------|
| 62.49 |

#### 5. What is the percentage split of all transactions for members vs non-members?

```sql
SELECT
member,
COUNT(DISTINCT txn_id) AS transaction_count,
ROUND(100.0 * COUNT(DISTINCT txn_id) /
SUM(COUNT(DISTINCT txn_id)) OVER (),2) AS percentage_split
FROM balanced_tree.sales
GROUP BY member;
```

##### Answer

| member | transaction_count | percentage_split |
|-------|------------------|------------------|
| t | 1502 | 60.08 |
| f | 998 | 39.92 |

---

#### 6. What is the average revenue for member transactions and non-member transactions?

```sql
WITH txn_revenue AS (
SELECT
txn_id,
member,
SUM(qty * price) AS revenue
FROM balanced_tree.sales
GROUP BY txn_id, member
)

SELECT
member,
ROUND(AVG(revenue),2) AS avg_revenue
FROM txn_revenue
GROUP BY member;
```

##### Answer

| member | avg_revenue |
|-------|-------------|
| t | 516.27 |
| f | 515.04 |

### Product Analysis

#### 1. What are the top 3 products by total revenue before discount?

```sql
SELECT
p.product_name,
SUM(s.qty * s.price) AS revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 3;
```

##### Answer

| product_name | revenue |
|---------------|--------|
| Blue Polo Shirt - Mens | 217683 |
| Grey Fashion Jacket - Womens | 209304 |
| White Tee Shirt - Mens | 152000 |

---

#### 2. What is the total quantity, revenue and discount for each segment?

```sql
SELECT
p.segment_name,
SUM(s.qty) AS total_quantity,
SUM(s.qty * s.price) AS total_revenue,
SUM(s.qty * s.price * s.discount / 100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.segment_name
ORDER BY total_revenue DESC;
```

##### Answer

| segment_name | total_quantity | total_revenue | total_discount |
|---------------|---------------|---------------|---------------|
| Shirts | 11265 | 406143 | 48923.64 |
| Jackets | 11385 | 366983 | 44237.43 |
| Socks | 11217 | 307977 | 37198.02 |
| Jeans | 11349 | 208350 | 25870.05 |

---

#### 3. What is the top selling product for each segment?

```sql
WITH product_sales AS (
SELECT
p.segment_name,
p.product_name,
SUM(s.qty) AS total_quantity
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.segment_name, p.product_name
)

SELECT *
FROM (
SELECT
segment_name,
product_name,
total_quantity,
RANK() OVER (
PARTITION BY segment_name
ORDER BY total_quantity DESC
) AS rnk
FROM product_sales
) t
WHERE rnk = 1;
```

##### Answer

| segment_name | product_name | total_quantity |
|---------------|---------------|---------------|
| Shirts | Blue Polo Shirt - Mens | 3819 |
| Jackets | Grey Fashion Jacket - Womens | 3876 |
| Socks | Navy Solid Socks - Mens | 3792 |
| Jeans | Black Straight Jeans - Womens | 3786 |

---

#### 4. What is the total quantity, revenue and discount for each category?

```sql
SELECT
p.category_name,
SUM(s.qty) AS total_quantity,
SUM(s.qty * s.price) AS total_revenue,
SUM(s.qty * s.price * s.discount / 100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.category_name
ORDER BY total_revenue DESC;
```

##### Answer

| category_name | total_quantity | total_revenue | total_discount |
|---------------|---------------|---------------|---------------|
| Mens | 22650 | 714120 | 86615.43 |
| Womens | 22566 | 575333 | 69613.71 |

---

#### 5. What is the top selling product for each category?

```sql
WITH product_sales AS (
SELECT
p.category_name,
p.product_name,
SUM(s.qty) AS total_quantity
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.category_name, p.product_name
)

SELECT *
FROM (
SELECT
category_name,
product_name,
total_quantity,
RANK() OVER (
PARTITION BY category_name
ORDER BY total_quantity DESC
) AS rnk
FROM product_sales
) t
WHERE rnk = 1;
```

##### Answer

| category_name | product_name | total_quantity |
|---------------|---------------|---------------|
| Mens | Blue Polo Shirt - Mens | 3819 |
| Womens | Grey Fashion Jacket - Womens | 3876 |

---

#### 6. What is the percentage split of revenue by product for each segment?

```sql
SELECT
p.segment_name,
p.product_name,
SUM(s.qty * s.price) AS revenue,
ROUND(
100 * SUM(s.qty * s.price) /
SUM(SUM(s.qty * s.price)) OVER (PARTITION BY p.segment_name),
2
) AS revenue_pct
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.segment_name, p.product_name
ORDER BY p.segment_name, revenue_pct DESC;
```

##### Answer

Example output:

| segment_name | product_name | revenue | revenue_pct |
|---------------|---------------|--------|-------------|
| Jackets | Grey Fashion Jacket - Womens | 209304 | 57.04 |
| Jackets | Khaki Suit Jacket - Womens | 157679 | 42.96 |
| Shirts | Blue Polo Shirt - Mens | 217683 | 53.60 |
| Shirts | White Tee Shirt - Mens | 188460 | 46.40 |

---

#### 7. What is the percentage split of revenue by segment for each category?

```sql
SELECT
p.category_name,
p.segment_name,
SUM(s.qty * s.price) AS revenue,
ROUND(
100 * SUM(s.qty * s.price) /
SUM(SUM(s.qty * s.price)) OVER (PARTITION BY p.category_name),
2
) AS revenue_pct
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.category_name, p.segment_name
ORDER BY p.category_name, revenue_pct DESC;
```

##### Answer

| category_name | segment_name | revenue | revenue_pct |
|---------------|---------------|--------|-------------|
| Mens | Shirts | 406143 | 56.88 |
| Mens | Socks | 307977 | 43.12 |
| Womens | Jackets | 366983 | 63.79 |
| Womens | Jeans | 208350 | 36.21 |

---

#### 8. What is the percentage split of total revenue by category?

```sql
SELECT
p.category_name,
SUM(s.qty * s.price) AS revenue,
ROUND(
100 * SUM(s.qty * s.price) /
SUM(SUM(s.qty * s.price)) OVER (),
2
) AS revenue_pct
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p
ON s.prod_id = p.product_id
GROUP BY p.category_name;
```

##### Answer

| category_name | revenue | revenue_pct |
|---------------|--------|-------------|
| Mens | 714120 | 55.38 |
| Womens | 575333 | 44.62 |

---

#### 9. What is the total transaction penetration for each product?

```sql
WITH product_txn AS (
SELECT
prod_id,
COUNT(DISTINCT txn_id) AS txn_count
FROM balanced_tree.sales
GROUP BY prod_id
)

SELECT
p.product_name,
txn_count,
ROUND(
100 * txn_count /
(SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales),
2
) AS penetration_pct
FROM product_txn pt
JOIN balanced_tree.product_details p
ON pt.prod_id = p.product_id
ORDER BY penetration_pct DESC;
```

##### Answer

Example output:

| product_name | txn_count | penetration_pct |
|---------------|----------|----------------|
| Blue Polo Shirt - Mens | 1788 | 71.52 |
| Grey Fashion Jacket - Womens | 1763 | 70.52 |
| Navy Solid Socks - Mens | 1758 | 70.32 |
| Black Straight Jeans - Womens | 1746 | 69.84 |

---

#### 10. What is the most common combination of at least 1 quantity of any 3 products in a single transaction?

```sql
WITH txn_products AS (
SELECT DISTINCT
txn_id,
prod_id
FROM balanced_tree.sales
),

product_combinations AS (
SELECT
a.txn_id,
a.prod_id AS prod1,
b.prod_id AS prod2,
c.prod_id AS prod3
FROM txn_products a
JOIN txn_products b
ON a.txn_id = b.txn_id
AND a.prod_id < b.prod_id
JOIN txn_products c
ON a.txn_id = c.txn_id
AND b.prod_id < c.prod_id
)

SELECT
p1.product_name AS product_1,
p2.product_name AS product_2,
p3.product_name AS product_3,
COUNT(*) AS frequency
FROM product_combinations pc
JOIN balanced_tree.product_details p1 ON pc.prod1 = p1.product_id
JOIN balanced_tree.product_details p2 ON pc.prod2 = p2.product_id
JOIN balanced_tree.product_details p3 ON pc.prod3 = p3.product_id
GROUP BY product_1, product_2, product_3
ORDER BY frequency DESC
LIMIT 1;
```

##### Answer

| product_1 | product_2 | product_3 | frequency |
|-----------|-----------|-----------|-----------|
| Blue Polo Shirt - Mens | Navy Solid Socks - Mens | White Tee Shirt - Mens | 352 |

The most common product bundle purchased together in a single transaction includes **Blue Polo Shirt (Mens), Navy Solid Socks (Mens), and White Tee Shirt (Mens)**.

### Reporting Challenge

> Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

> Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

> He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

> Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

My approach to the solution would be:

- Generate the report for **January**
- Allow the same script to run for **February** with minimal changes
- Produce outputs corresponding to the previous analysis questions

The script below uses a **single reporting month parameter**, allowing the entire analysis to be rerun for different months.

---

#### Monthly Reporting SQL Script

```sql
/* =========================================
BALANCED TREE MONTHLY SALES REPORT
========================================= */

/* Change this value to run another month */
WITH report_month AS (
    SELECT DATE '2021-01-01' AS month_start
),

/* Filter sales for selected month */
monthly_sales AS (
    SELECT s.*
    FROM balanced_tree.sales s
    JOIN report_month r
        ON DATE_TRUNC('month', s.start_txn_time) = r.month_start
),

/* Join product metadata */
sales_enriched AS (
    SELECT
        ms.txn_id,
        ms.prod_id,
        ms.qty,
        ms.price,
        ms.discount,
        ms.member,
        pd.product_name,
        pd.segment_name,
        pd.category_name
    FROM monthly_sales ms
    JOIN balanced_tree.product_details pd
        ON ms.prod_id = pd.product_id
),

/* ================================
TABLE 1 — High Level Sales Analysis
(Q1–Q3)
================================ */
high_level_sales AS (
    SELECT
        SUM(qty) AS total_quantity_sold,
        SUM(qty * price) AS total_revenue_before_discount,
        SUM(qty * price * discount / 100) AS total_discount
    FROM sales_enriched
),

/* ================================
TABLE 2 — Transaction Analysis
(Q4–Q6)
================================ */
txn_metrics AS (
    SELECT
        txn_id,
        member,
        SUM(qty * price) AS revenue,
        SUM(qty * price * discount / 100) AS discount_value,
        COUNT(DISTINCT prod_id) AS unique_products
    FROM sales_enriched
    GROUP BY txn_id, member
),

transaction_analysis AS (
    SELECT
        COUNT(*) AS total_transactions,
        AVG(unique_products) AS avg_products_per_txn,
        AVG(discount_value) AS avg_discount_per_txn
    FROM txn_metrics
),

member_revenue AS (
    SELECT
        member,
        AVG(revenue) AS avg_revenue
    FROM txn_metrics
    GROUP BY member
),

/* ================================
TABLE 3 — Top Product Revenue
================================ */
product_revenue AS (
    SELECT
        product_name,
        SUM(qty * price) AS revenue
    FROM sales_enriched
    GROUP BY product_name
    ORDER BY revenue DESC
    LIMIT 3
),

/* ================================
TABLE 4 — Segment Performance
================================ */
segment_metrics AS (
    SELECT
        segment_name,
        SUM(qty) AS total_quantity,
        SUM(qty * price) AS total_revenue,
        SUM(qty * price * discount / 100) AS total_discount
    FROM sales_enriched
    GROUP BY segment_name
),

/* ================================
TABLE 5 — Category Performance
================================ */
category_metrics AS (
    SELECT
        category_name,
        SUM(qty) AS total_quantity,
        SUM(qty * price) AS total_revenue,
        SUM(qty * price * discount / 100) AS total_discount
    FROM sales_enriched
    GROUP BY category_name
)

/* =================================
FINAL REPORT OUTPUTS
================================= */

SELECT * FROM high_level_sales;

SELECT * FROM transaction_analysis;

SELECT * FROM member_revenue;

SELECT * FROM product_revenue;

SELECT * FROM segment_metrics;

SELECT * FROM category_metrics;
```

---

#### Running the Report for February

To generate the report for **February**, simply update the reporting parameter:

```sql
SELECT DATE '2021-02-01' AS month_start
```

All calculations will automatically adjust for the new month.

---

#### Key Design Idea

Instead of writing new queries every month, the report:

- Defines a **single month parameter**
- Filters the dataset using that parameter
- Reuses the same aggregations for each report table

This approach makes the report **fully repeatable and suitable for automated scheduling**.

### Bonus Challenge
> Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
> Hint: you may want to consider using a recursive CTE to solve this problem!

```sql
WITH RECURSIVE hierarchy AS (

    SELECT
        id,
        parent_id,
        level_text,
        level_name
    FROM balanced_tree.product_hierarchy

    UNION ALL

    SELECT
        ph.id,
        ph.parent_id,
        ph.level_text,
        ph.level_name
    FROM balanced_tree.product_hierarchy ph
    JOIN hierarchy h
        ON ph.id = h.parent_id
),

product_tree AS (
SELECT
    h1.id AS product_id,
    MAX(CASE WHEN h2.level_text = 'Segment' THEN h2.level_name END) AS segment_name,
    MAX(CASE WHEN h3.level_text = 'Category' THEN h3.level_name END) AS category_name,
    MAX(CASE WHEN h1.level_text = 'Style' THEN h1.level_name END) AS product_name
FROM hierarchy h1
LEFT JOIN hierarchy h2
    ON h1.parent_id = h2.id
LEFT JOIN hierarchy h3
    ON h2.parent_id = h3.id
WHERE h1.level_text = 'Style'
GROUP BY h1.id
)

SELECT
pt.product_id,
pt.product_name,
pt.segment_name,
pt.category_name,
pp.price
FROM product_tree pt
JOIN balanced_tree.product_prices pp
ON pt.product_id = pp.product_id
ORDER BY pt.product_id;
```
