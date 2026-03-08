# Case Study #1: Danny's Diner
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/6ac3d0e3-e644-4c25-82fe-a1481d474c7d" />
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## Entity Relationship Diagram
<img width="604" height="360" alt="sushi" src="https://github.com/user-attachments/assets/bc02bc5d-7bfe-4d52-98e7-fa2d524b69c9" />

## Questions and Solutions

### 1. What is the total amount each customer spent at the restaurant?
```sql 
SELECT 
  sales.customer_id,
  SUM(menu.price) AS total_spent
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
```
#### Steps
1. Identify what one row represents  
   In the `sales` table, each row represents **one purchased item**.
2. Determine the data needed  
   - `sales` → tells us **who bought what**  
   - `menu` → contains the **price of each item**
3. Join tables  
   Join `sales` with `menu` using `product_id` so we can attach the **price** to each purchase.
4. Calculate spending  
   Use `SUM(menu.price)` to add the price of all items purchased.
5. Aggregate by customer  
   Use `GROUP BY sales.customer_id` so each customer gets **one row showing their total spending**.
#### Answer
| customer_id | total_spent |
|--------------|-------------|
| A | 76 |
| B | 74 |
| C | 36 |
### 2. How many days has each customer visited the restaurant?
```sql
SELECT 
  customer_id,
  COUNT(order_date) AS days_spent
FROM sales
GROUP BY customer_id;
```
#### Steps
1. Count purchase records per customer using `COUNT(order_date)`.
2. Use `GROUP BY customer_id` to calculate the count for each customer separately.

#### Answer

| customer_id | days_spent |
|-------------|------------|
| A | 6 |
| B | 6 |
| C | 3 |
### 3. What was the first item from the menu purchased by each customer?
```sql
SELECT
  sales.customer_id,
  sales.order_date AS first_day,
  menu.product_name
FROM sales 
JOIN menu 
  ON sales.product_id = menu.product_id
WHERE sales.order_date = (
  SELECT MIN(order_date)
  FROM sales
  WHERE customer_id = sales.customer_id
);
```
#### Steps

1. Use a correlated subquery to find the **earliest `order_date` for each customer**.
2. Filter the `sales` table so only rows matching that earliest date remain.
3. Join `menu` to retrieve the **product name** of the item purchased.

#### Answer

| customer_id | first_day  | product_name |
|--------------|------------|--------------|
| A | 2021-01-01 | sushi |
| A | 2021-01-01 | curry |
| B | 2021-01-01 | curry |
| C | 2021-01-01 | ramen |

I chose to keep both rows for customer A because the dataset only records the date of the purchase, not the exact time. On the earliest recorded date, customer A purchased two items, sushi and curry. Since both purchases happened on the same day, the data does not provide enough information to determine which one occurred first.

Because of this limitation, I kept both results rather than forcing the query to return a single item. Doing so avoids introducing an arbitrary choice that the dataset itself cannot justify.
Alternatively, if it absolutely requires to be only one item, here is the edited query:
```sql
SELECT customer_id, order_date AS first_day, product_name
FROM (
  SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    ROW_NUMBER() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date
    ) AS purchase_rank
  FROM sales
  JOIN menu
    ON sales.product_id = menu.product_id
) t
WHERE purchase_rank = 1;
```
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT
  menu.product_name AS most_purchased_product,
  COUNT(sales.product_id) AS times_purchased
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY menu.product_name
LIMIT 1;
```
#### Steps

1. Count how many times each product appears in `sales`.
2. Group results by `menu.product_name` to calculate totals per item.

#### Answer

| most_purchased_product | times_purchased |
|------------------------|-----------------|
| ramen | 8 |
### 5. Which item was the most popular for each customer?
```sql
SELECT customer_id, product_name, times_purchased
FROM (
  SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(*) AS times_purchased,
    ROW_NUMBER() OVER (
      PARTITION BY sales.customer_id
      ORDER BY COUNT(*) DESC
    ) AS time_rank
  FROM sales 
  JOIN menu 
    ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
) t
WHERE time_rank = 1;
```
#### Steps

1. Count how many times each customer purchased each product.
2. Use `ROW_NUMBER()` with `PARTITION BY customer_id` to rank products by purchase frequency for each customer.
3. Keep only the product with the highest rank (`time_rank = 1`) for each customer.

#### Answer

| customer_id | product_name | times_purchased |
|-------------|--------------|-----------------|
| A | ramen | 3 |
| B | sushi | 2 |
| C | ramen | 3 |
### 6. Which item was purchased first by the customer after they became a member?
```sql
SELECT
  customer_id, product_name AS first_after_mem
FROM (
  SELECT
    sales.customer_id,
    menu.product_name,
    ROW_NUMBER() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date
  ) AS purchase_rank
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
JOIN members
  ON sales.customer_id = members.customer_id
WHERE sales.order_date >= members.join_date
) t
WHERE rank = 1;
```
#### Steps

1. Filter orders to include only purchases **on or after the membership join date**.
2. Use `ROW_NUMBER()` with `PARTITION BY customer_id` and `ORDER BY order_date` to rank purchases chronologically for each customer.
3. Select the row where `rank = 1` to get the **first item purchased after becoming a member**.

#### Answer

| customer_id | first_after_mem |
|-------------|-----------------|
| A | ramen |
| B | sushi |
### 7. Which item was purchased just before the customer became a member?
```sql
SELECT 
  customer_id, product_name AS last_before_mem
FROM (
  SELECT
    sales.customer_id,
    menu.product_name,
    ROW_NUMBER() OVER (
      PARTITION BY sales.customer_id
      ORDER BY sales.order_date DESC
  ) AS purchase_rank
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
JOIN members
  ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
) t
WHERE purchase_rank = 1;
```
#### Steps

1. Filter purchases to include only orders **before the customer became a member**.
2. Use `ROW_NUMBER()` with `PARTITION BY customer_id` and `ORDER BY order_date DESC` to rank purchases from **most recent to oldest** for each customer.
3. Select the row where `purchase_rank = 1` to get the **last item purchased before membership**.

#### Answer

| customer_id | last_before_mem |
|-------------|-----------------|
| A | sushi |
| B | sushi |
### 8. What is the total items and amount spent for each member before they became a member?
```sql
SELECT
  sales.customer_id,
  COUNT(*) AS total_items,
  SUM(menu.price) AS amount_spent
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
JOIN members
ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;
```
#### Steps

1. Filter purchases to include only orders **before the membership join date**.
2. Count the number of items purchased using `COUNT(*)`.
3. Sum the total amount spent using `SUM(menu.price)`.
4. Group results by `customer_id` to calculate totals per customer.

#### Answer

| customer_id | total_items | amount_spent |
|-------------|-------------|--------------|
| A | 2 | 25 |
| B | 3 | 40 |
### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
SELECT
  sales.customer_id,
  SUM(
    CASE
      WHEN menu.product_name = 'sushi' THEN menu.price * 20
      ELSE menu.price * 10
    END
  ) AS total_points
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
```
#### Steps

1. Convert spending into points using `price * 10`.
2. Apply a 2× multiplier for sushi using a `CASE` expression.
3. Sum the calculated points for each customer.

#### Answer

| customer_id | total_points |
|-------------|--------------|
| A | 860 |
| B | 940 |
| C | 360 |
### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
SELECT
  sales.customer_id,
  SUM(
    CASE
      WHEN sales.order_date BETWEEN members.join_date 
           AND members.join_date + INTERVAL '6 days'
        THEN menu.price * 20
      WHEN menu.product_name = 'sushi'
        THEN menu.price * 20
      ELSE menu.price * 10
    END
  ) AS points
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
JOIN members
  ON sales.customer_id = members.customer_id
WHERE sales.order_date <= '2021-01-31'
GROUP BY sales.customer_id
HAVING sales.customer_id IN ('A','B');
```
#### Steps

1. Identify purchases made **within the first 7 days of membership** and apply a **2× multiplier on all items**.
2. Otherwise apply the **sushi 2× multiplier**, or the normal **10 points per $1** rule.
3. Sum the calculated points for each customer.
4. Filter results to **customers A and B** and purchases **before the end of January**.

#### Answer

| customer_id | points |
|-------------|--------|
| A | 1370 |
| B | 820 |

## Bonus Questions
### Join all the things
The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. Recreate the table with customer_id, order_date, product_name, price, member (Y/N):
```sql
SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  CASE
    WHEN members.join_date IS NOT NULL
         AND sales.order_date >= members.join_date
      THEN 'Y'
    ELSE 'N'
  END AS member
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
LEFT JOIN members
  ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date;
```
#### Answer
| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A | 2021-01-01 | curry | 15 | N |
| A | 2021-01-01 | sushi | 10 | N |
| A | 2021-01-07 | curry | 15 | Y |
| A | 2021-01-10 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| B | 2021-01-01 | curry | 15 | N |
| B | 2021-01-02 | curry | 15 | N |
| B | 2021-01-04 | sushi | 10 | N |
| B | 2021-01-11 | sushi | 10 | Y |
| B | 2021-01-16 | ramen | 12 | Y |
| B | 2021-02-01 | ramen | 12 | Y |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-07 | ramen | 12 | N |
### Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
```sql
SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  CASE
    WHEN members.join_date IS NOT NULL 
         AND sales.order_date >= members.join_date
      THEN 'Y'
    ELSE 'N'
  END AS member,
  CASE
    WHEN sales.order_date >= members.join_date
      THEN RANK() OVER (
        PARTITION BY sales.customer_id
        ORDER BY sales.order_date
      )
  END AS ranking
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
LEFT JOIN members
  ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date;
```
#### Answer
| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|--------|
| A | 2021-01-01 | curry | 15 | N | NULL |
| A | 2021-01-01 | sushi | 10 | N | NULL |
| A | 2021-01-07 | curry | 15 | Y | 1 |
| A | 2021-01-10 | ramen | 12 | Y | 2 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| A | 2021-01-11 | ramen | 12 | Y | 3 |
| B | 2021-01-01 | curry | 15 | N | NULL |
| B | 2021-01-02 | curry | 15 | N | NULL |
| B | 2021-01-04 | sushi | 10 | N | NULL |
| B | 2021-01-11 | sushi | 10 | Y | 1 |
| B | 2021-01-16 | ramen | 12 | Y | 2 |
| B | 2021-02-01 | ramen | 12 | Y | 3 |
| C | 2021-01-01 | ramen | 12 | N | NULL |
| C | 2021-01-01 | ramen | 12 | N | NULL |
| C | 2021-01-07 | ramen | 12 | N | NULL |
