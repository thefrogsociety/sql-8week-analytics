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
  s.customer_id,
  s.order_date AS first_day,
  m.product_name
FROM sales s
JOIN menu m
  ON s.product_id = m.product_id
WHERE s.order_date = (
  SELECT MIN(order_date)
  FROM sales
  WHERE customer_id = s.customer_id
);
