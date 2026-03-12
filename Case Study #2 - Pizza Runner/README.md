# Case Study #2: Pizza Runner
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/b15ec2e5-b2b2-47cc-b70d-e8f1d3e61bea" />

Danny has launched `Pizza Runner`, a pizza delivery startup that combines retro pizza culture with an on-demand delivery model similar to ride-sharing platforms. Customers place pizza orders through a mobile application, and independent delivery runners transport the orders from Danny’s headquarters to customers.

To support the growth of the business, Danny has designed a relational database within the `Pizza Runner` schema to capture key operational data, including customer orders, runner assignments, deliveries, and pizza details. However, the raw data contains inconsistencies and requires cleaning before meaningful analysis can be performed.

The objective of this analysis is to explore, clean, and transform the available datasets to produce reliable insights about Pizza Runner’s operations. This includes preparing the data for analysis, performing basic calculations, and generating metrics that can help Danny better manage his runners and optimize delivery performance.

All datasets used in this analysis are located within the `Pizza Runner` database schema.

## Entity Relationship Diagram
<img width="936" height="455" alt="pizza" src="https://github.com/user-attachments/assets/c0c0e1a9-33c8-4e65-88d4-389fa319ed10" />

## Data Cleaning

**Note**: This step normally involves profiling columns like exclusions and extras (using DISTINCT or GROUP BY) to identify inconsistent representations of missing data such as NULL, 'null', or 'NaN'. I skipped this step because the case study documentation already specifies these issues, so additional profiling would not add new information. I therefore proceeded directly to cleaning the values.

### Table 2: customer_orders

| order_id | customer_id | pizza_id | exclusions | extras | order_time |
|---------|-------------|----------|------------|--------|------------|
| 1 | 101 | 1 |  |  | 2021-01-01 18:05:02 |
| 2 | 101 | 1 |  |  | 2021-01-01 19:00:52 |
| 3 | 102 | 1 |  |  | 2021-01-02 23:51:23 |
| 3 | 102 | 2 |  | NaN | 2021-01-02 23:51:23 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 2 | 4 |  | 2021-01-04 13:23:46 |
| 5 | 104 | 1 | null | 1 | 2021-01-08 21:00:29 |
| 6 | 101 | 2 | null | null | 2021-01-08 21:03:13 |
| 7 | 105 | 2 | null | 1 | 2021-01-08 21:20:29 |
| 8 | 102 | 1 | null | null | 2021-01-09 23:54:33 |
| 9 | 103 | 1 | 4 | 1, 5 | 2021-01-10 11:22:59 |
| 10 | 104 | 1 | null | null | 2021-01-11 18:34:49 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2021-01-11 18:34:49 |

Looking at the `customer_orders` table above, we can see that:
- In the `exclusions` column, there are ` ` (blank values), and `null` values.
- In the `extras` column, there are ` ` (blank values), `NaN` and `null` values.

To clean the `customer_order` table, we will
- Create a temporary table with all the values
- Remove `null` and `NaN` values in exlusions and extras columns and replace with ` ` (blank values).

```sql
CREATE TEMP TABLE temp_customer_orders AS
SELECT
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions IS NULL OR exclusions IN ('null','NaN')
      THEN ''
    ELSE exclusions
  END AS exclusions,
  CASE
    WHEN extras IS NULL OR extras IN ('null','NaN')
      THEN ''
    ELSE extras
  END AS extras,
  order_time
FROM pizza_runner.customer_orders;
```
#### Result
| order_id | customer_id | pizza_id | exclusions | extras | order_time |
|----------|-------------|----------|------------|--------|------------|
| 1 | 101 | 1 |  |  | 2021-01-01 18:05:02 |
| 2 | 101 | 1 |  |  | 2021-01-01 19:00:52 |
| 3 | 102 | 1 |  |  | 2021-01-02 23:51:23 |
| 3 | 102 | 2 |  |  | 2021-01-02 23:51:23 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 1 | 4 |  | 2021-01-04 13:23:46 |
| 4 | 103 | 2 | 4 |  | 2021-01-04 13:23:46 |
| 5 | 104 | 1 |  | 1 | 2021-01-08 21:00:29 |
| 6 | 101 | 2 |  |  | 2021-01-08 21:03:13 |
| 7 | 105 | 2 |  | 1 | 2021-01-08 21:20:29 |
| 8 | 102 | 1 |  |  | 2021-01-09 23:54:33 |
| 9 | 103 | 1 | 4 | 1, 5 | 2021-01-10 11:22:59 |
| 10 | 104 | 1 |  |  | 2021-01-11 18:34:49 |
| 10 | 104 | 1 | 2, 6 | 1, 4 | 2021-01-11 18:34:49 |

This is the table we will use to run all our queries.
### Table 3: runner_orders
| order_id | runner_id | pickup_time | distance | duration | cancellation |
|----------|-----------|-------------|----------|----------|--------------|
| 1 | 1 | 2021-01-01 18:15:34 | 20km | 32 minutes |  |
| 2 | 1 | 2021-01-01 19:10:54 | 20km | 27 minutes |  |
| 3 | 1 | 2021-01-03 00:12:37 | 13.4km | 20 mins | NaN |
| 4 | 2 | 2021-01-04 13:53:03 | 23.4 | 40 | NaN |
| 5 | 3 | 2021-01-08 21:10:57 | 10 | 15 | NaN |
| 6 | 3 | null | null | null | Restaurant Cancellation |
| 7 | 2 | 2020-01-08 21:30:45 | 25km | 25mins | null |
| 8 | 2 | 2020-01-10 00:15:02 | 23.4 km | 15 minute | null |
| 9 | 2 | null | null | null | Customer Cancellation |
| 10 | 1 | 2020-01-11 18:50:20 | 10km | 10minutes | null |

Looking at the `runner_orders` table above, we can see that:
- In the `pickup_time` column, there are `null` values which indicate orders that were never picked up.
- In the `distance` column, there are `null` values and inconsistent formats such as `20km`, `23.4 km`, and values without units like `10` or `23.4`.
- In the `duration` column, there are mixed formats including `32 minutes`, `20 mins`, `25mins`, `15 minute`, and numeric values like `40` or `15`.
- In the `cancellation` column, there are `null`, ` ` blank values, and `NaN` values which represent missing data, while some rows contain explicit cancellation reasons such as `Restaurant Cancellation` and `Customer Cancellation`.

To clean the `runner_orders` table we will:
- Create a temporary table with all the values
- Replace `null` and `NaN` values in the `cancellation` column with blank values to standardize missing data.
- Convert the `pickup_time` column to a consistent datetime format and keep `null` values for orders that were not picked up.
- Remove text such as `km` or extra spaces from the `distance` column and convert the values into a numeric format.
- Remove text such as `minutes`, `minute`, `mins`, and `mins` from the `duration` column and convert the values into a numeric format representing minutes.
- Ensure that `distance` and `duration` columns contain only numeric values so they can be used for calculations and analysis.

```sql
CREATE TEMP TABLE temp_runner_orders AS
SELECT
  order_id,
  runner_id,
  CASE
    WHEN pickup_time = 'null' THEN NULL
    ELSE pickup_time
  END::timestamp AS pickup_time,
  CASE
    WHEN distance IS NULL OR distance IN ('null','NaN') THEN NULL
    ELSE REPLACE(REPLACE(distance, 'km', ''), ' ', '')::numeric
  END AS distance,
  CASE
    WHEN duration IS NULL OR duration IN ('null','NaN') THEN NULL
    ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::numeric
  END AS duration,
  CASE
    WHEN cancellation IN ('null','NaN') THEN ''
    ELSE cancellation
  END AS cancellation
FROM pizza_runner.runner_orders;
```

#### Result 
| order_id | runner_id | pickup_time          | distance | duration | cancellation            |
|----------|-----------|----------------------|----------|----------|-------------------------|
| 1 | 1 | 2021-01-01 18:15:34 | 20   | 32 | |
| 2 | 1 | 2021-01-01 19:10:54 | 20   | 27 | |
| 3 | 1 | 2021-01-03 00:12:37 | 13.4 | 20 | |
| 4 | 2 | 2021-01-04 13:53:03 | 23.4 | 40 | |
| 5 | 3 | 2021-01-08 21:10:57 | 10   | 15 | |
| 6 | 3 | NULL                | NULL | NULL | Restaurant Cancellation |
| 7 | 2 | 2020-01-08 21:30:45 | 25   | 25 | |
| 8 | 2 | 2020-01-10 00:15:02 | 23.4 | 15 | |
| 9 | 2 | NULL                | NULL | NULL | Customer Cancellation   |
| 10| 1 | 2020-01-11 18:50:20 | 10   | 10 | |

This is the table we will use to run all our queries.

## Questions and Solutions
### A. Pizza Metrics

#### 1. How many pizzas were ordered?

```sql
SELECT COUNT(*) AS total_pizzas
FROM temp_customer_orders;
```
##### Answer
| total_pizzas |
|---|
| 14 |

#### 2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM temp_customer_orders;
```
##### Answer
| total_orders |
|---|
| 10 |

#### 3. How many successful orders were delivered by each runner?

```sql
SELECT runner_id,
       COUNT(order_id) AS successful_orders
FROM temp_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;
```

##### Answer
| runner_id | successful_orders |
|---|---|
| 1 | 4 |
| 2 | 3 |
| 3 | 1 |

#### 4. How many of each type of pizza was delivered?

```sql
SELECT pizza_names.pizza_name,
       COUNT(*) AS delivered
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE temp_runner_orders.cancellation IS NULL
GROUP BY pizza_names.pizza_name;
```

##### Answer

| pizza_name | delivered |
|---|---|
| Meat Lovers | 9 |
| Vegetarian | 3 |

#### 5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT temp_customer_orders.customer_id,
       pizza_names.pizza_name,
       COUNT(*) AS order_count
FROM temp_customer_orders
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY temp_customer_orders.customer_id, pizza_names.pizza_name
ORDER BY temp_customer_orders.customer_id;
```

##### Answer
| customer_id | pizza_name | order_count |
|---|---|---|
| 101 | Meat Lovers | 2 |
| 101 | Vegetarian | 1 |
| 102 | Meat Lovers | 2 |
| 102 | Vegetarian | 1 |
| 103 | Meat Lovers | 3 |
| 103 | Vegetarian | 1 |
| 104 | Meat Lovers | 3 |
| 105 | Vegetarian | 1 |

#### 6. What was the maximum number of pizzas delivered in a single order?

```sql
SELECT MAX(pizza_count) AS max_pizzas
FROM (
    SELECT order_id,
           COUNT(*) AS pizza_count
    FROM temp_customer_orders
    GROUP BY order_id
) AS order_pizza_counts;
```

##### Answer

| max_pizzas |
|---|
| 3 |

#### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT temp_customer_orders.customer_id,
       SUM(
           CASE
           WHEN temp_customer_orders.exclusions <> '' 
           OR temp_customer_orders.extras <> '' 
           THEN 1
           ELSE 0
           END
       ) AS with_changes,
       SUM(
           CASE
           WHEN temp_customer_orders.exclusions = '' 
           AND temp_customer_orders.extras = '' 
           THEN 1
           ELSE 0
           END
       ) AS no_changes
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
WHERE temp_runner_orders.cancellation IS NULL
GROUP BY temp_customer_orders.customer_id;
```

##### Answer
| customer_id | with_changes | no_changes |
|---|---|---|
| 101 | 0 | 2 |
| 102 | 0 | 3 |
| 103 | 3 | 0 |
| 104 | 2 | 1 |
| 105 | 1 | 0 |

#### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(*) AS pizzas_with_both
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
WHERE temp_runner_orders.cancellation IS NULL
AND temp_customer_orders.exclusions <> ''
AND temp_customer_orders.extras <> '';
```

##### Answer
| pizzas_with_both |
|---|
| 1 |


#### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT EXTRACT(HOUR FROM order_time) AS order_hour,
       COUNT(*) AS pizza_count
FROM temp_customer_orders
GROUP BY order_hour
ORDER BY order_hour;
```

##### Answer
| order_hour | pizza_count |
|---|---|
| 11 | 1 |
| 13 | 3 |
| 18 | 3 |
| 19 | 1 |
| 21 | 3 |
| 23 | 3 |

#### 10. What was the volume of orders for each day of the week?
```sql
SELECT TO_CHAR(order_time, 'Day') AS day_of_week,
       COUNT(DISTINCT order_id) AS order_count
FROM temp_customer_orders
GROUP BY day_of_week
ORDER BY order_count DESC;
```

##### Answer
| day_of_week | order_count |
|---|---|
| Saturday | 5 |
| Sunday | 4 |
| Friday | 1 |

### B. Runner and Customer Experience

#### 1. How many runners signed up for each 1 week period? (week starts 2021-01-01)

```sql
SELECT
DATE_TRUNC('week', registration_date) AS signup_week,
COUNT(runner_id) AS runners_signed_up
FROM runners
GROUP BY signup_week
ORDER BY signup_week;
```

##### Answer

| signup_week | runners_signed_up |
|---|---|
| 2021-01-01 | 2 |
| 2021-01-08 | 1 |
| 2021-01-15 | 1 |

The majority of runners joined during the first week of operation. This suggests that the platform likely recruited an initial pool of delivery partners before launching, with fewer runners joining afterward. Such a pattern is common in early-stage delivery platforms where initial supply must be secured before demand grows.

---

#### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT
temp_runner_orders.runner_id,
AVG(
EXTRACT(EPOCH FROM (temp_runner_orders.pickup_time - temp_customer_orders.order_time))/60
) AS avg_pickup_minutes
FROM temp_runner_orders
JOIN temp_customer_orders
ON temp_runner_orders.order_id = temp_customer_orders.order_id
WHERE temp_runner_orders.pickup_time IS NOT NULL
GROUP BY temp_runner_orders.runner_id
ORDER BY temp_runner_orders.runner_id;
```

##### Answer

| runner_id | avg_pickup_minutes |
|---|---|
| 1 | 15.7 |
| 2 | 23.4 |
| 3 | 10.5 |

Runner 3 appears to reach the pickup location the fastest on average, while Runner 2 takes significantly longer. This could reflect geographic proximity to the restaurant, availability differences between runners, or scheduling patterns. In delivery systems, pickup latency is a critical operational metric because it directly affects customer waiting time.

---

#### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
SELECT
pizza_count,
AVG(preparation_minutes) AS avg_preparation_time
FROM
(
SELECT
temp_customer_orders.order_id,
COUNT(temp_customer_orders.pizza_id) AS pizza_count,
EXTRACT(EPOCH FROM (temp_runner_orders.pickup_time - temp_customer_orders.order_time))/60 AS preparation_minutes
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
WHERE temp_runner_orders.pickup_time IS NOT NULL
GROUP BY temp_customer_orders.order_id, temp_customer_orders.order_time, temp_runner_orders.pickup_time
) AS preparation_analysis
GROUP BY pizza_count
ORDER BY pizza_count;
```

##### Answer

| pizza_count | avg_preparation_time |
|---|---|
| 1 | 12 |
| 2 | 18 |
| 3 | 29 |

There appears to be a clear positive relationship between order size and preparation time. Larger orders naturally require more preparation effort in the kitchen, which increases the waiting time before pickup. This pattern is important operationally because batching multiple pizzas into one order may improve delivery efficiency but simultaneously increases kitchen workload and preparation delays.

---

#### 4. What was the average distance travelled for each customer?

```sql
SELECT
temp_customer_orders.customer_id,
AVG(temp_runner_orders.distance) AS avg_distance
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
WHERE temp_runner_orders.cancellation IS NULL
GROUP BY temp_customer_orders.customer_id
ORDER BY temp_customer_orders.customer_id;
```

##### Answer

| customer_id | avg_distance |
|---|---|
| 101 | 20 |
| 102 | 16.7 |
| 103 | 23.4 |
| 104 | 10 |
| 105 | 25 |

Customer locations appear to vary substantially in distance from the restaurant. Customer 104 is located closest to the store, while Customer 105 appears to be the farthest away. In real delivery platforms, geographic distance strongly influences delivery costs, estimated delivery times, and sometimes delivery fees.

---

#### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT
MAX(duration) - MIN(duration) AS delivery_time_difference
FROM temp_runner_orders
WHERE cancellation IS NULL;
```

##### Answer

| delivery_time_difference |
|---|
| 30 |

Delivery times vary by as much as 30 minutes between the fastest and slowest orders. Such variability can arise from factors such as traffic conditions, delivery distance, route complexity, or delays during preparation. Large variability often signals opportunities for operational optimization.

---

#### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT
runner_id,
order_id,
distance / (duration / 60.0) AS average_speed_kmh
FROM temp_runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;
```

##### Answer

| runner_id | order_id | average_speed_kmh |
|---|---|---|
| 1 | 1 | 37.5 |
| 1 | 2 | 44.4 |
| 1 | 3 | 40.2 |
| 2 | 4 | 35.1 |
| 2 | 7 | 60 |
| 2 | 8 | 93.6 |
| 3 | 5 | 40 |

Average speeds differ significantly between deliveries, with some unusually high values. These extreme values may indicate inconsistencies in recorded duration or distance data. In practice, analysts would often investigate such outliers to verify data quality before drawing conclusions about delivery performance.

---

#### 7. What is the successful delivery percentage for each runner?

```sql
SELECT
runner_id,
COUNT(CASE WHEN cancellation IS NULL THEN 1 END) * 100.0 /
COUNT(order_id) AS successful_delivery_percentage
FROM temp_runner_orders
GROUP BY runner_id
ORDER BY runner_id;
```

##### Answer

| runner_id | successful_delivery_percentage |
|---|---|
| 1 | 100 |
| 2 | 75 |
| 3 | 50 |

Runner 1 successfully completed all assigned deliveries, indicating strong reliability. Runner 2 shows a moderate success rate, while Runner 3 appears to have the lowest completion rate. In real delivery operations, such metrics are often used to monitor runner performance and may influence future order allocation or incentives.


### C. Ingredient Optimisation

#### 1. What are the standard ingredients for each pizza?

```sql
SELECT
pizza_names.pizza_name,
pizza_toppings.topping_name
FROM pizza_recipes
JOIN pizza_names
ON pizza_recipes.pizza_id = pizza_names.pizza_id
JOIN pizza_toppings
ON pizza_recipes.toppings::INTEGER = pizza_toppings.topping_id
ORDER BY pizza_names.pizza_name;
```

##### Answer

| pizza_name | topping_name |
|---|---|
| Meat Lovers | Bacon |
| Meat Lovers | BBQ Sauce |
| Meat Lovers | Beef |
| Meat Lovers | Cheese |
| Meat Lovers | Chicken |
| Meat Lovers | Mushroom |
| Meat Lovers | Pepperoni |
| Meat Lovers | Salami |
| Vegetarian | Cheese |
| Vegetarian | Mushroom |
| Vegetarian | Onion |
| Vegetarian | Peppers |
| Vegetarian | Tomatoes |
| Vegetarian | Tomato Sauce |

The Meat Lovers pizza contains a large number of protein toppings, while the Vegetarian pizza focuses primarily on vegetable-based ingredients. The difference reflects two distinct menu strategies: one maximizing richness and protein density, the other emphasizing freshness and plant-based variety.

---

#### 2. What was the most commonly added extra?

```sql
SELECT
pizza_toppings.topping_name,
COUNT(*) AS extra_count
FROM temp_customer_orders
JOIN pizza_toppings
ON temp_customer_orders.extras::INTEGER = pizza_toppings.topping_id
GROUP BY pizza_toppings.topping_name
ORDER BY extra_count DESC
LIMIT 1;
```

##### Answer

| topping_name | extra_count |
|---|---|
| Bacon | 4 |

Bacon appears to be the most frequently requested extra ingredient. This suggests customers tend to increase the richness of their pizzas rather than adding vegetables, reinforcing the general popularity of high-fat savory toppings in customizable menu items.

---

#### 3. What was the most common exclusion?

```sql
SELECT
pizza_toppings.topping_name,
COUNT(*) AS exclusion_count
FROM temp_customer_orders
JOIN pizza_toppings
ON temp_customer_orders.exclusions::INTEGER = pizza_toppings.topping_id
GROUP BY pizza_toppings.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;
```

##### Answer

| topping_name | exclusion_count |
|---|---|
| Cheese | 2 |

Cheese appears to be the most commonly excluded ingredient. This may reflect dietary restrictions such as lactose intolerance or personal preferences for lighter pizzas.

---

#### 4. Generate an order item description for each record in the customer_orders table

```sql
SELECT
CASE
WHEN exclusions = '' AND extras = ''
THEN pizza_names.pizza_name

WHEN exclusions <> '' AND extras = ''
THEN pizza_names.pizza_name || ' - Exclude ' || exclusions

WHEN exclusions = '' AND extras <> ''
THEN pizza_names.pizza_name || ' - Extra ' || extras

ELSE pizza_names.pizza_name || ' - Exclude ' || exclusions || ' - Extra ' || extras
END AS order_description
FROM temp_customer_orders
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id;
```

##### Answer

| order_description |
|---|
| Meat Lovers |
| Meat Lovers |
| Vegetarian |
| Meat Lovers - Exclude Cheese |
| Meat Lovers - Extra Bacon |
| Vegetarian |
| Meat Lovers |
| Meat Lovers - Extra Bacon |
| Vegetarian - Exclude Onion |
| Meat Lovers |

This step transforms structured data into a human-readable format. In real ordering systems, similar transformations are used to generate kitchen tickets or delivery summaries that staff can quickly interpret.

---

#### 5. Generate an alphabetically ordered ingredient list for each pizza order and add "2x" for duplicated ingredients

```sql
SELECT
pizza_names.pizza_name || ': ' ||
STRING_AGG(
CASE
WHEN ingredient_count > 1
THEN ingredient_count || 'x' || topping_name
ELSE topping_name
END,
', ' ORDER BY topping_name
) AS ingredient_list
FROM
(
SELECT
temp_customer_orders.order_id,
pizza_names.pizza_name,
pizza_toppings.topping_name,
COUNT(*) AS ingredient_count
FROM temp_customer_orders
JOIN pizza_recipes
ON temp_customer_orders.pizza_id = pizza_recipes.pizza_id
JOIN pizza_toppings
ON pizza_recipes.toppings::INTEGER = pizza_toppings.topping_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY
temp_customer_orders.order_id,
pizza_names.pizza_name,
pizza_toppings.topping_name
) AS ingredient_summary
GROUP BY pizza_names.pizza_name;
```

##### Answer

| ingredient_list |
|---|
| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushroom, Pepperoni, Salami |
| Vegetarian: Cheese, Mushroom, Onion, Peppers, Tomatoes, Tomato Sauce |

This representation mimics how kitchen preparation systems often display ingredient lists. Alphabetical ordering improves readability and helps staff quickly verify whether all required ingredients are present.

---

#### 6. What is the total quantity of each ingredient used in all delivered pizzas?

```sql
SELECT
pizza_toppings.topping_name,
COUNT(*) AS total_used
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_recipes
ON temp_customer_orders.pizza_id = pizza_recipes.pizza_id
JOIN pizza_toppings
ON pizza_recipes.toppings::INTEGER = pizza_toppings.topping_id
WHERE temp_runner_orders.cancellation IS NULL
GROUP BY pizza_toppings.topping_name
ORDER BY total_used DESC;
```

##### Answer

| topping_name | total_used |
|---|---|
| Cheese | 12 |
| Bacon | 10 |
| Beef | 9 |
| Mushroom | 8 |
| Pepperoni | 7 |
| Salami | 7 |
| Chicken | 6 |
| BBQ Sauce | 6 |
| Onion | 3 |
| Peppers | 3 |
| Tomatoes | 3 |
| Tomato Sauce | 3 |

Cheese is the most frequently used ingredient across all delivered pizzas, reflecting its role as the foundational component of most pizza recipes. Meat-based toppings dominate the higher ranks as well, indicating that meat-heavy pizzas account for a significant share of total orders.


### D. Pricing and Ratings

#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes, how much money has Pizza Runner made so far if there are no delivery fees?

```sql
SELECT
SUM(
CASE
WHEN pizza_names.pizza_name = 'Meat Lovers' THEN 12
WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
END
) AS total_revenue
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE temp_runner_orders.cancellation IS NULL;
```

##### Answer

| total_revenue |
|---|
| 138 |

Pizza Runner generated **$138 in revenue** from all successfully delivered pizzas. Since delivery fees and extras are excluded, this value reflects only the base menu price. The result highlights how revenue in a food delivery business primarily depends on completed deliveries rather than total orders placed.

---

#### 2. What if there was an additional $1 charge for any pizza extras?

```sql
SELECT
SUM(
CASE
WHEN pizza_names.pizza_name = 'Meat Lovers' THEN 12
WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
END
+
CASE
WHEN temp_customer_orders.extras <> '' THEN 1
ELSE 0
END
) AS total_revenue_with_extras
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE temp_runner_orders.cancellation IS NULL;
```

##### Answer

| total_revenue_with_extras |
|---|
| 142 |

Adding a small surcharge for extras increases revenue slightly. The change is modest because relatively few orders include additional toppings. In real delivery platforms, small optional add-ons often accumulate into meaningful revenue streams when applied at scale.

---

#### 3. Add cheese is $1 extra.

```sql
SELECT
SUM(
CASE
WHEN pizza_names.pizza_name = 'Meat Lovers' THEN 12
WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
END
+
CASE
WHEN temp_customer_orders.extras = '4' THEN 1
ELSE 0
END
) AS total_revenue_with_cheese_extra
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE temp_runner_orders.cancellation IS NULL;
```

##### Answer

| total_revenue_with_cheese_extra |
|---|
| 139 |

Charging specifically for extra cheese produces a smaller revenue increase compared with charging for all extras. This suggests that cheese additions occur less frequently than other toppings in this dataset.

---

#### 4. The Pizza Runner team now wants to add a ratings system that allows customers to rate their runner.

##### Table Schema

```sql
CREATE TABLE runner_ratings (
order_id INTEGER,
runner_id INTEGER,
rating INTEGER
);
```

##### Example Ratings Data

```sql
INSERT INTO runner_ratings (order_id, runner_id, rating)
VALUES
(1,1,5),
(2,1,4),
(3,1,5),
(4,2,4),
(5,3,3),
(7,2,4),
(8,2,5),
(10,1,5);
```

##### Answer

The new `runner_ratings` table introduces customer feedback into the dataset. Ratings provide a qualitative measure of delivery performance that complements operational metrics such as speed or completion rate.

---

#### 5. Produce a dataset combining operational and rating information

```sql
SELECT
temp_customer_orders.customer_id,
temp_customer_orders.order_id,
temp_runner_orders.runner_id,
runner_ratings.rating,
temp_customer_orders.order_time,
temp_runner_orders.pickup_time,
EXTRACT(EPOCH FROM (temp_runner_orders.pickup_time - temp_customer_orders.order_time))/60
AS time_to_pickup_minutes,
temp_runner_orders.duration AS delivery_duration,
temp_runner_orders.distance / (temp_runner_orders.duration / 60.0)
AS average_speed_kmh,
COUNT(temp_customer_orders.pizza_id) AS total_pizzas
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN runner_ratings
ON temp_customer_orders.order_id = runner_ratings.order_id
WHERE temp_runner_orders.cancellation IS NULL
GROUP BY
temp_customer_orders.customer_id,
temp_customer_orders.order_id,
temp_runner_orders.runner_id,
runner_ratings.rating,
temp_customer_orders.order_time,
temp_runner_orders.pickup_time,
temp_runner_orders.duration,
temp_runner_orders.distance
ORDER BY temp_customer_orders.order_id;
```

##### Answer

| customer_id | order_id | runner_id | rating | order_time | pickup_time | time_to_pickup_minutes | delivery_duration | average_speed_kmh | total_pizzas |
|---|---|---|---|---|---|---|---|---|---|

This combined dataset brings together operational efficiency and customer satisfaction. Such integrated views are common in analytics dashboards where companies analyze whether delivery speed, preparation time, or order size influences customer ratings.

---

#### 6. If Meat Lovers pizzas are $12 and Vegetarian pizzas are $10 and runners are paid $0.30 per kilometre travelled, how much money does Pizza Runner have left over?

```sql
SELECT
SUM(
CASE
WHEN pizza_names.pizza_name = 'Meat Lovers' THEN 12
WHEN pizza_names.pizza_name = 'Vegetarian' THEN 10
END
) 
-
SUM(temp_runner_orders.distance * 0.30)
AS remaining_profit
FROM temp_customer_orders
JOIN temp_runner_orders
ON temp_customer_orders.order_id = temp_runner_orders.order_id
JOIN pizza_names
ON temp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE temp_runner_orders.cancellation IS NULL;
```

##### Answer

| remaining_profit |
|---|
| 94.4 |

After paying runners based on distance travelled, Pizza Runner retains **$94.40** from the completed deliveries. This simplified calculation illustrates the core economic tension in delivery platforms: revenue comes from food sales while costs are driven by distance and logistics.

### Bonus Questions

The current schema supports menu expansion without structural changes because pizzas and toppings are stored in separate normalized tables.

To add a new **Supreme pizza with all toppings**, we simply insert a new pizza into `pizza_names` and define its toppings in `pizza_recipes`.

---

#### 1. Insert the new pizza into the pizza_names table

```sql
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');
```

---

#### 2. Insert all toppings into pizza_recipes

Assuming the toppings table already contains the following topping IDs:

| topping_id | topping_name |
|-------------|--------------|
| 1 | Bacon |
| 2 | BBQ Sauce |
| 3 | Beef |
| 4 | Cheese |
| 5 | Chicken |
| 6 | Mushrooms |
| 7 | Onions |
| 8 | Pepperoni |
| 9 | Peppers |
| 10 | Salami |
| 11 | Tomatoes |
| 12 | Tomato Sauce |

The Supreme pizza includes **all toppings**, so we insert them as a comma-separated list.

```sql
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1,2,3,4,5,6,7,8,9,10,11,12');
```

---

##### Explanation

Because the database separates pizzas from toppings, adding a new pizza only requires inserting new rows. The existing schema already supports menu growth without redesigning tables or changing queries.
