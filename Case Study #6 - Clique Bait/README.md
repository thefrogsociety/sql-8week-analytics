# Case Study #6: Clique Bait 
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/c2d5a86d-a12a-4a4c-907f-ef9f5156e133" />

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

## Entity Relational Diagram

## Questions and Answers

### Digital Analysis
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
| Ad Click | 702 |

#### 5. What is the percentage of visits which have a purchase event?

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
| Ad Click | 702 |

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
| 15.50 |

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

| page_name | views |
|----------|-------|
| All Products | 3174 |
| Checkout | 2103 |
| Home Page | 1782 |

#### 9. What are the top 3 products by purchases?
```sql
SELECT
ph.page_name AS product,
COUNT(*) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
ON e.page_id = ph.page_id
WHERE e.event_type = 3
GROUP BY ph.page_name
ORDER BY purchases DESC
LIMIT 3;
```

**Answer**

| product | purchases |
|--------|-----------|
| Lobster | 189 |
| Oyster | 174 |
| Salmon | 163 |
---
### Product Funnel Analysis
> Using a single SQL query - create a new output table which has the following details:

> How many times was each product viewed?
> How many times was each product added to cart?
> How many times was each product added to a cart but not purchased (abandoned)?
> How many times was each product purchased?
```sql
SELECT
    ph.page_name AS product,

    /* Product views */
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,

    /* Add to cart events */
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,

    /* Purchases */
    SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases,

    /* Cart adds that did not result in purchase */
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END)
      - SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END)
      AS abandoned

FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
    ON e.page_id = ph.page_id

WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY views DESC;
```

#### Output Table

| product | views | add_to_cart | abandoned | purchases |
|--------|------|-------------|-----------|-----------|
| Salmon | ... | ... | ... | ... |
| Lobster | ... | ... | ... | ... |
| Oyster | ... | ... | ... | ... |

> Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql
SELECT
    ph.product_category,

    /* Product views */
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,

    /* Add to cart events */
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart,

    /* Purchases */
    SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases,

    /* Cart adds that did not result in purchase */
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END)
      - SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END)
      AS abandoned

FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
    ON e.page_id = ph.page_id

WHERE ph.product_id IS NOT NULL
GROUP BY ph.product_category
ORDER BY views DESC;
```

#### Output Table

| product_category | views | add_to_cart | abandoned | purchases |
|------------------|------|-------------|-----------|-----------|
| Fish | ... | ... | ... | ... |
| Shellfish | ... | ... | ... | ... |
| Crustaceans | ... | ... | ... | ... |

> Use your 2 new output tables - answer the following questions:

#### 1. Which product had the most views, cart adds and purchases?
```sql
SELECT
  ph.page_name AS product,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
  SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY views DESC;
```
#### 2. Which product was most likely to be abandoned?
```sql
SELECT
  ph.page_name AS product,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
  SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY views DESC;
```
#### 3. Which product had the highest view to purchase percentage?
```sql
WITH product_stats AS (
SELECT
  ph.page_name AS product,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
  SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
)

SELECT
  product,
  cart_adds,
  purchases,
  (cart_adds - purchases) AS abandoned,
  ROUND((cart_adds - purchases) * 100.0 / cart_adds, 2) AS abandonment_rate
FROM product_stats
WHERE cart_adds > 0
ORDER BY abandonment_rate DESC;
```
#### 4. What is the average conversion rate from view to cart add?
```sql
WITH product_stats AS (
SELECT
  ph.page_name AS product,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
  SUM(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
)

SELECT
  product,
  views,
  purchases,
  ROUND(purchases * 100.0 / views, 2) AS view_to_purchase_rate
FROM product_stats
WHERE views > 0
ORDER BY view_to_purchase_rate DESC;
```

#### 5. What is the average conversion rate from cart add to purchase?
```sql
WITH product_stats AS (
SELECT
  ph.page_name AS product,
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
  ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.page_name
)

SELECT
  ROUND(AVG(cart_adds * 1.0 / views), 4) AS avg_view_to_cart_conversion
FROM product_stats
WHERE views > 0;
```

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

> Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

> Some ideas you might want to investigate further include:

#### 1. Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
#### 2. Does clicking on an impression lead to higher purchase rates?
#### 3. What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
#### 4. What metrics can you use to quantify the success or failure of each campaign compared to eachother?
