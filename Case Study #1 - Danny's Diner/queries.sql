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

-- Question 6
-- Which item was purchased first by the customer after they became a member?

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

-- Question 7
-- Which item was purchased just before the customer became a member?

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

-- Question 8
-- What is the total items and amount spent for each member before they became a member?

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

-- Question 9
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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

-- Question 10
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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
