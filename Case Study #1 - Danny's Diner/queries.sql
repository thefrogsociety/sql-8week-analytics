-- Question 1
-- What is the total amount each customer spent at the restaurant?
SELECT 
  sales.customer_id,
  SUM(menu.price) AS total_spent
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- Question 2
-- How many days has each customer visited the restaurant?

SELECT 
  customer_id,
  COUNT(order_date) AS days_spent
FROM sales
GROUP BY customer_id;

-- Question 3
-- What was the first item from the menu purchased by each customer?

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

-- Question 4
-- What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  menu.product_name AS most_purchased_product,
  COUNT(sales.product_id) AS times_purchased
FROM sales
JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY menu.product_name
LIMIT 1;

-- Question 5
-- Which item was the most popular for each customer?

SELECT
  s.customer_id,
  m.product_name,
  COUNT(*) AS purchases,
  ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY COUNT(*) DESC
  ) AS rank
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name;

