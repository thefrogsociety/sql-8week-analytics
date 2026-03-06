-- Question 1
-- What is the total amount each customer spent at the restaurant?
SELECT 
  sales.customer_id
  SUM(menu.price) AS total_spent
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id

-- Question 2
-- How many days has each customer visited the restaurant?

-- Question 3
-- What was the first item from the menu purchased by each customer?

