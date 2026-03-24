# Case Study #6: Clique Bait 
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/c2d5a86d-a12a-4a4c-907f-ef9f5156e133" />

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

## Entity Relational Diagram
<img width="831" height="462" alt="6" src="https://github.com/user-attachments/assets/b5e2568a-57b3-4e31-b7fb-475693a7782e" />

## Questions and Answers

> Using the available datasets - answer the following questions using a single query for each one:

#### 1. How many users are there?

```sql
SELECT COUNT(DISTINCT user_id) AS total_users
FROM clique_bait.users;
```

**Answer**

| total_users |
|-------------|
| 500 |

#### 2. How many cookies does each user have on average?

```sql
SELECT ROUND(AVG(cookie_count),2) AS avg_cookies_per_user
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM clique_bait.users
    GROUP BY user_id
) t;
```

**Answer**

| avg_cookies_per_user |
|----------------------|
| 3.56 |

#### 3. What is the unique number of visits by all users per month?

```sql
SELECT ROUND(AVG(cookie_count),2) AS avg_cookies_per_user
FROM (
    SELECT user_id, COUNT(cookie_id) AS cookie_count
    FROM clique_bait.users
    GROUP BY user_id
) t;
```

**Answer**

| avg_cookies_per_user |
|----------------------|
| 3.56 |

#### 4. What is the number of events for each event type?

```sql
SELECT
e.event_name,
COUNT(*) AS event_count
FROM clique_bait.events ev
JOIN clique_bait.event_identifier e
ON ev.event_type = e.event_type
GROUP BY e.event_name
ORDER BY event_count DESC;
```

**Answer**

| event_name | event_count |
|------------|-------------|
| Page View | 20928 |
| Add to Cart | 8451 |
| Purchase | 1777 |
| Ad Impression | 876|
| Ad Click | 702 |

#### 5. What is the percentage of visits which have a purchase event?

```sql
SELECT
ROUND(
  100.0 * COUNT(DISTINCT CASE WHEN event_type = 3 THEN visit_id END)
  / COUNT(DISTINCT visit_id),
  2
) AS pct_visits_with_purchase
FROM clique_bait.events;
```

**Answer**

| pct_visits_with_purchase|
|-------------------------|
|                    49.86|

#### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

```sql
WITH checkout_visits AS (
SELECT DISTINCT visit_id
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy p
ON e.page_id = p.page_id
WHERE p.page_name = 'Checkout'
),

purchase_visits AS (
SELECT DISTINCT visit_id
FROM clique_bait.events
WHERE event_type = 3
)

SELECT
ROUND(
100.0 * COUNT(*) /
(SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events),2
) AS checkout_no_purchase_percentage
FROM checkout_visits
WHERE visit_id NOT IN (SELECT visit_id FROM purchase_visits);
```

**Answer**

| checkout_no_purchase_percentage |
|--------------------------------|
| 9.15 |

#### 7. What are the top 3 pages by number of views?

```sql
SELECT
p.page_name,
COUNT(*) AS views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = 1
GROUP BY p.page_name
ORDER BY views DESC
LIMIT 3;
```

**Answer**

| page_name | views |
|----------|-------|
| All Products | 3174 |
| Checkout | 2103 |
| Home Page | 1782 |

#### 8. What is the number of views and cart adds for each product category?

```sql
SELECT
p.page_name,
COUNT(*) AS views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = 1
GROUP BY p.page_name
ORDER BY views DESC
LIMIT 3;
```

**Answer**

| product_category | views | cart_adds|
|------------------|-------|----------|
| Fish             |  4633 |      2789|
| Luxury           |  3032 |      1870|
| Shellfish        |  6204 |      3792|

#### 9. What are the top 3 products by purchases?
```sql
WITH purchase_visits AS (
  SELECT DISTINCT visit_id
  FROM clique_bait.events
  WHERE event_type = 3
)

SELECT
  p.page_name AS product_name,
  COUNT(*) AS purchases
FROM clique_bait.events e
JOIN purchase_visits pv
  ON e.visit_id = pv.visit_id
JOIN clique_bait.page_hierarchy p
  ON e.page_id = p.page_id
WHERE e.event_type = 2  -- cart adds
  AND p.product_id IS NOT NULL
GROUP BY p.page_name
ORDER BY purchases DESC
LIMIT 3;
```

**Answer**

| product_name | purchases|
|--------------|----------|
| Lobster      |       754|
| Oyster       |       726|
| Crab         |       719|

---
### Product Funnel Analysis
> Using a single SQL query - create a new output table which has the following details:

> How many times was each product viewed?
> How many times was each product added to cart?
> How many times was each product added to a cart but not purchased (abandoned)?
> How many times was each product purchased?

```sql
WITH purchase_sessions AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
),
product_events AS (
    SELECT
        e.visit_id,
        ph.page_name,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
)
SELECT
    page_name AS product,
    SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
    SUM(
        CASE 
            WHEN event_type = 2 
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
            THEN 1 
            ELSE 0 
        END
    ) AS purchases,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END)
    -
    SUM(
        CASE 
            WHEN event_type = 2 
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
            THEN 1 
            ELSE 0 
        END
    ) AS abandoned
FROM product_events
GROUP BY page_name
ORDER BY views DESC;
```

#### Output Table

|    product     | views | add_to_cart | purchases | abandoned|
|----------------+-------+-------------+-----------+----------|
| Oyster         |  1568 |         943 |       726 |       217|
| Crab           |  1564 |         949 |       719 |       230|
| Russian Caviar |  1563 |         946 |       697 |       249|
| Salmon         |  1559 |         938 |       711 |       227|
| Kingfish       |  1559 |         920 |       707 |       213|
| Lobster        |  1547 |         968 |       754 |       214|
| Abalone        |  1525 |         932 |       699 |       233|
| Tuna           |  1515 |         931 |       697 |       234|
| Black Truffle  |  1469 |         924 |       707 |       217|

> Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
WITH purchase_sessions AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
),
product_events AS (
    SELECT
        e.visit_id,
        ph.product_category,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
)

SELECT
    product_category,
    SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,
    SUM(
        CASE 
            WHEN event_type = 2 
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
            THEN 1 
            ELSE 0 
        END
    ) AS purchases,
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END)
    -
    SUM(
        CASE 
            WHEN event_type = 2 
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
            THEN 1 
            ELSE 0 
        END
    ) AS abandoned
FROM product_events
GROUP BY product_category
ORDER BY views DESC;
```

#### Output Table

| product_category | views | add_to_cart | purchases | abandoned|
|------------------|-------|-------------|-----------|----------|
| Shellfish        |  6204 |        3792 |      2898 |       894|
| Fish             |  4633 |        2789 |      2115 |       674|
| Luxury           |  3032 |        1870 |      1404 |       466|

> Use your 2 new output tables - answer the following questions:

#### 1. Which product had the most views, cart adds and purchases?
- Most Views: Oyster (1,568 views)  
- Most Add to Cart: Lobster (968 adds)  
- Most Purchases: Lobster (754 purchases)
- 
#### 2. Which product was most likely to be abandoned?
```sql
WITH purchase_sessions AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
),
product_events AS (
    SELECT
        e.visit_id,
        ph.page_name,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
)

SELECT
    page_name AS product,
    ROUND(
        100.0 * (
            SUM(CASE 
                WHEN event_type = 2 
                AND visit_id NOT IN (SELECT visit_id FROM purchase_sessions)
                THEN 1 ELSE 0 END
            )::numeric
            /
            NULLIF(SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END), 0)
        ),
        2
    ) AS abandonment_rate
FROM product_events
GROUP BY page_name
ORDER BY abandonment_rate DESC
LIMIT 1;
```
|    product     | abandonment_rate|
|----------------|-----------------|
| Russian Caviar |            26.32|

#### 3. Which product had the highest view to purchase percentage?
```sql
WITH purchase_sessions AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
),
product_events AS (
    SELECT
        e.visit_id,
        ph.page_name,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
)

SELECT
    page_name AS product,
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE 
            WHEN event_type = 1 
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
            THEN visit_id END
        )
        /
        NULLIF(
            COUNT(DISTINCT CASE WHEN event_type = 1 THEN visit_id END),
            0
        ),
        2
    ) AS view_to_purchase_pct
FROM product_events
GROUP BY page_name
ORDER BY view_to_purchase_pct DESC
LIMIT 1;
```
| product | view_to_purchase_pct|
|---------|---------------------|
| Oyster  |                72.45|

#### 4. What is the average conversion rate from view to cart add?

```sql
WITH product_events AS (
    SELECT
        ph.page_name,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
),

product_metrics AS (
    SELECT
        page_name,
        COUNT(*) FILTER (WHERE event_type = 1) AS views,
        COUNT(*) FILTER (WHERE event_type = 2) AS cart_adds
    FROM product_events
    GROUP BY page_name
)

SELECT
    ROUND(
        AVG(
            cart_adds * 1.0 / NULLIF(views, 0)
        ) * 100,
        2
    ) AS avg_view_to_cart_pct
FROM product_metrics;
```

| avg_view_to_cart_pct|
|---------------------|
|                60.95|

#### 5. What is the average conversion rate from cart add to purchase?
```sql
WITH purchase_sessions AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
),
product_events AS (
    SELECT
        e.visit_id,
        ph.page_name,
        e.event_type
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
),

product_metrics AS (
    SELECT
        page_name,
        COUNT(*) FILTER (WHERE event_type = 2) AS cart_adds,
        COUNT(*) FILTER (
            WHERE event_type = 2
            AND visit_id IN (SELECT visit_id FROM purchase_sessions)
        ) AS purchases
    FROM product_events
    GROUP BY page_name
)

SELECT
    ROUND(
        AVG(
            purchases * 1.0 / NULLIF(cart_adds, 0)
        ) * 100,
        2
    ) AS avg_cart_to_purchase_pct
FROM product_metrics;
```
| avg_cart_to_purchase_pct|
|-------------------------|
|                    75.93|

---

### Campaigns Analysis
> Generate a table that has 1 single row for every unique visit_id record and has the following columns:

> `user_id`

> `visit_id`

> `visit_start_time`: the earliest event_time for each visit

> `page_views`: count of page views for each visit

> `cart_adds`: count of product cart add events for each visit

> `purchase`: 1/0 flag if a purchase event exists for each visit

> `campaign_name`: map the visit to a campaign if the visit_start_time falls between the start_date and end_date

> `impression`: count of ad impressions for each visit

> `click`: count of ad clicks for each visit

> (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
WITH visit_base AS (
    SELECT
        u.user_id,
        e.visit_id,
        MIN(e.event_time) AS visit_start_time
    FROM clique_bait.events e
    JOIN clique_bait.users u
        ON e.cookie_id = u.cookie_id
    GROUP BY u.user_id, e.visit_id
),

event_metrics AS (
    SELECT
        visit_id,
        COUNT(*) FILTER (WHERE event_type = 1) AS page_views,
        COUNT(*) FILTER (WHERE event_type = 2) AS cart_adds,
        COUNT(*) FILTER (WHERE event_type = 3) > 0 AS purchase,
        COUNT(*) FILTER (WHERE event_type = 4) AS impression,
        COUNT(*) FILTER (WHERE event_type = 5) AS click
    FROM clique_bait.events
    GROUP BY visit_id
),

cart_products AS (
    SELECT
        e.visit_id,
        STRING_AGG(
            ph.page_name,
            ', ' ORDER BY e.sequence_number
        ) AS cart_products
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE e.event_type = 2
      AND ph.product_id IS NOT NULL
    GROUP BY e.visit_id
)

SELECT
    vb.user_id,
    vb.visit_id,
    vb.visit_start_time,
    em.page_views,
    em.cart_adds,
    em.purchase,
    ci.campaign_name,
    em.impression,
    em.click,
    cp.cart_products
FROM visit_base vb
LEFT JOIN event_metrics em
    ON vb.visit_id = em.visit_id
LEFT JOIN cart_products cp
    ON vb.visit_id = cp.visit_id
LEFT JOIN clique_bait.campaign_identifier ci
    ON vb.visit_start_time BETWEEN ci.start_date AND ci.end_date
ORDER BY vb.visit_id;
```

> Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

> Some ideas you might want to investigate further include:

> 1. Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
> 2. Does clicking on an impression lead to higher purchase rates?
> 3. What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
> 4. What metrics can you use to quantify the success or failure of each campaign compared to eachother?
