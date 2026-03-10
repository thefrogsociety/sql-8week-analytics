# Case Study #3: Foodie-Fi 
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/ffad90cc-2f7b-4d97-9daa-52d758d499d0" />

## Entity Relationship Diagram
## Questions and Solutions
### A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
```sql
SELECT
subscriptions.customer_id,
plans.plan_name,
subscriptions.start_date
FROM subscriptions
JOIN plans
ON subscriptions.plan_id = plans.plan_id
WHERE subscriptions.customer_id <= 8
ORDER BY subscriptions.customer_id, subscriptions.start_date;
```
#### Result

| customer_id | plan_name      | start_date |
|-------------|---------------|------------|
| 1 | trial | 2020-08-01 |
| 1 | basic monthly | 2020-08-08 |
| 2 | trial | 2020-09-20 |
| 2 | pro annual | 2020-09-27 |
| 3 | trial | 2020-01-13 |
| 3 | basic monthly | 2020-01-20 |
| 4 | trial | 2020-01-17 |
| 4 | basic monthly | 2020-01-24 |
| 4 | churn | 2020-04-21 |
| 5 | trial | 2020-08-03 |
| 5 | basic monthly | 2020-08-10 |
| 6 | trial | 2020-12-23 |
| 6 | basic monthly | 2020-12-30 |
| 6 | churn | 2021-02-26 |
| 7 | trial | 2020-02-05 |
| 7 | basic monthly | 2020-02-12 |
| 7 | pro monthly | 2020-05-22 |
| 8 | trial | 2020-06-11 |
| 8 | basic monthly | 2020-06-18 |
| 8 | pro monthly | 2020-08-03 |

---

#### Customer onboarding journeys

##### Customer 1  
Trial on 2020-08-01 → upgraded to basic monthly on 2020-08-08.

##### Customer 2  
Trial on 2020-09-20 → upgraded directly to pro annual on 2020-09-27.

##### Customer 3  
Trial on 2020-01-13 → upgraded to basic monthly on 2020-01-20.

##### Customer 4  
Trial on 2020-01-17 → basic monthly on 2020-01-24 → churned on 2020-04-21.

##### Customer 5  
Trial on 2020-08-03 → upgraded to basic monthly on 2020-08-10.

##### Customer 6  
Trial on 2020-12-23 → basic monthly on 2020-12-30 → churned on 2021-02-26.

##### Customer 7  
Trial on 2020-02-05 → basic monthly on 2020-02-12 → upgraded to pro monthly on 2020-05-22.

##### Customer 8  
Trial on 2020-06-11 → basic monthly on 2020-06-18 → upgraded to pro monthly on 2020-08-03.

---

#### Personal Observation

Looking at the first 8 customers, I notice every customer begins with the **trial plan**, and most of them transition exactly **7 days later** to a paid plan. This suggests that the trial period is designed to last one week before customers must decide whether to subscribe.

**Basic monthly plan is the most common first paid option**, as most customers upgrade to it immediately after the trial. However, a few customers behave differently: one customer upgrades directly to **pro annual**, and others eventually upgrade further to **pro monthly** after starting with the basic plan.

**Some customers churn after trying the paid plan**, while others continue upgrading their subscriptions over time. This shows that users respond to the trial in different ways—some commit quickly, some explore gradually, and some decide the service is not worth continuing.

### B. Data Analysis Questions
#### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;
```
##### Answer
| total_customers |
|---|
| 1000 |

#### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

```sql
SELECT
DATE_TRUNC('month', start_date) AS month,
COUNT(*) AS trials
FROM subscriptions
WHERE plan_id = 0
GROUP BY month
ORDER BY month;
```

##### Answer

| month | trials |
|---|---|
| 2020-01-01 | 88 |
| 2020-02-01 | 68 |
| 2020-03-01 | 94 |
| 2020-04-01 | 81 |
| 2020-05-01 | 88 |
| 2020-06-01 | 79 |
| 2020-07-01 | 89 |
| 2020-08-01 | 88 |
| 2020-09-01 | 87 |
| 2020-10-01 | 79 |
| 2020-11-01 | 75 |
| 2020-12-01 | 84 |

#### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

```sql
SELECT
plans.plan_name,
COUNT(*) AS event_count
FROM subscriptions
JOIN plans
ON subscriptions.plan_id = plans.plan_id
WHERE start_date >= '2021-01-01'
GROUP BY plans.plan_name
ORDER BY event_count DESC;
```

##### Answer

| plan_name | event_count |
|---|---|
| churn | 71 |
| pro annual | 63 |
| pro monthly | 60 |
| basic monthly | 8 |

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
SELECT
COUNT(DISTINCT customer_id) AS churned_customers,
ROUND(
100.0 * COUNT(DISTINCT customer_id) /
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1
) AS churn_percentage
FROM subscriptions
WHERE plan_id = 4;
```

##### Answer

| churned_customers | churn_percentage |
|---|---|
| 307 | 30.7 |

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
WITH next_plan AS (
SELECT
customer_id,
plan_id,
LEAD(plan_id) OVER (
PARTITION BY customer_id
ORDER BY start_date
) AS next_plan
FROM subscriptions
)

SELECT
COUNT(*) AS customers,
ROUND(
100.0 * COUNT(*) /
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)
) AS percentage
FROM next_plan
WHERE plan_id = 0
AND next_plan = 4;
```

##### Answer

| customers | percentage |
|---|---|
| 92 | 9 |

#### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
WITH next_plan AS (
SELECT
customer_id,
plan_id,
LEAD(plan_id) OVER (
PARTITION BY customer_id
ORDER BY start_date
) AS next_plan
FROM subscriptions
)

SELECT
plans.plan_name,
COUNT(*) AS customers,
ROUND(
100.0 * COUNT(*) /
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1
) AS percentage
FROM next_plan
JOIN plans
ON next_plan.next_plan = plans.plan_id
WHERE next_plan.plan_id = 0
GROUP BY plans.plan_name
ORDER BY customers DESC;
```

##### Answer

| plan_name | customers | percentage |
|---|---|---|
| basic monthly | 546 | 54.6 |
| pro monthly | 325 | 32.5 |
| churn | 92 | 9.2 |
| pro annual | 37 | 3.7 |

---

#### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

```sql
WITH latest_plan AS (
SELECT
customer_id,
plan_id,
start_date,
ROW_NUMBER() OVER (
PARTITION BY customer_id
ORDER BY start_date DESC
) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)

SELECT
plans.plan_name,
COUNT(*) AS customers,
ROUND(
100.0 * COUNT(*) /
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1
) AS percentage
FROM latest_plan
JOIN plans
ON latest_plan.plan_id = plans.plan_id
WHERE rn = 1
GROUP BY plans.plan_name
ORDER BY customers DESC;
```

##### Answer

| plan_name | customers | percentage |
|---|---|---|
| pro monthly | 326 | 32.6 |
| churn | 236 | 23.6 |
| basic monthly | 224 | 22.4 |
| pro annual | 195 | 19.5 |
| trial | 19 | 1.9 |

---

#### 8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT COUNT(DISTINCT customer_id) AS customers
FROM subscriptions
WHERE plan_id = 3
AND start_date BETWEEN '2020-01-01' AND '2020-12-31';
```

##### Answer

| customers |
|---|
| 195 |

---

#### 9. How many days on average does it take for a customer to upgrade to an annual plan?

```sql
WITH join_dates AS (
SELECT customer_id, MIN(start_date) AS join_date
FROM subscriptions
GROUP BY customer_id
),
annual_dates AS (
SELECT customer_id, start_date AS annual_date
FROM subscriptions
WHERE plan_id = 3
)

SELECT
AVG(annual_date - join_date) AS avg_days
FROM join_dates
JOIN annual_dates
ON join_dates.customer_id = annual_dates.customer_id;
```

##### Answer

| avg_days |
|---|
| 104 |

---

#### 10. Breakdown of upgrade time into 30 day periods

```sql
WITH days_to_upgrade AS (
SELECT
annual_dates.customer_id,
annual_dates.annual_date - join_dates.join_date AS days
FROM
(SELECT customer_id, MIN(start_date) AS join_date
FROM subscriptions
GROUP BY customer_id) join_dates
JOIN
(SELECT customer_id, start_date AS annual_date
FROM subscriptions
WHERE plan_id = 3) annual_dates
ON join_dates.customer_id = annual_dates.customer_id
)

SELECT
CASE
WHEN days <= 30 THEN '0-30 days'
WHEN days <= 60 THEN '31-60 days'
WHEN days <= 90 THEN '61-90 days'
WHEN days <= 120 THEN '91-120 days'
WHEN days <= 180 THEN '121-180 days'
ELSE '180+ days'
END AS period,
COUNT(*) AS customers
FROM days_to_upgrade
GROUP BY period
ORDER BY period;
```

##### Answer

| period | customers |
|---|---|
| 0-30 days | 49 |
| 31-60 days | 24 |
| 61-90 days | 35 |
| 91-120 days | 35 |
| 121-180 days | 42 |
| 180+ days | 10 |

---

#### 11. How many customers downgraded from pro monthly to basic monthly in 2020?

```sql
WITH plan_changes AS (
SELECT
customer_id,
plan_id,
start_date,
LAG(plan_id) OVER (
PARTITION BY customer_id
ORDER BY start_date
) AS previous_plan
FROM subscriptions
)

SELECT COUNT(DISTINCT customer_id) AS downgrade_count
FROM plan_changes
WHERE previous_plan = 2
AND plan_id = 1
AND start_date BETWEEN '2020-01-01' AND '2020-12-31';
```

##### Answer

| downgrade_count |
|---|
| 0 |

### C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments


### C. Challenge Payment Question

```sql
WITH plan_events AS (
SELECT
s.customer_id,
s.plan_id,
p.plan_name,
p.price,
s.start_date,
LEAD(s.start_date) OVER (
PARTITION BY s.customer_id
ORDER BY s.start_date
) AS next_plan_date
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id
),

monthly_payments AS (
SELECT
customer_id,
plan_id,
plan_name,
price,
generate_series(
start_date,
COALESCE(next_plan_date - INTERVAL '1 day', '2020-12-31'),
INTERVAL '1 month'
) AS payment_date
FROM plan_events
WHERE plan_name IN ('basic monthly','pro monthly')
),

annual_payments AS (
SELECT
customer_id,
plan_id,
plan_name,
price,
start_date AS payment_date
FROM plan_events
WHERE plan_name = 'pro annual'
),

payments AS (
SELECT * FROM monthly_payments
UNION ALL
SELECT * FROM annual_payments
)

SELECT
customer_id,
plan_id,
plan_name,
payment_date::date,
price AS amount,
ROW_NUMBER() OVER (
PARTITION BY customer_id
ORDER BY payment_date
) AS payment_order
FROM payments
WHERE payment_date BETWEEN '2020-01-01' AND '2020-12-31'
ORDER BY customer_id, payment_date;
```

##### Answer

| customer_id | plan_id | plan_name | payment_date | amount | payment_order |
|---|---|---|---|---|---|
| 1 | 1 | basic monthly | 2020-08-08 | 9.90 | 1 |
| 1 | 1 | basic monthly | 2020-09-08 | 9.90 | 2 |
| 1 | 1 | basic monthly | 2020-10-08 | 9.90 | 3 |
| 1 | 1 | basic monthly | 2020-11-08 | 9.90 | 4 |
| 1 | 1 | basic monthly | 2020-12-08 | 9.90 | 5 |
| 2 | 3 | pro annual | 2020-09-27 | 199.00 | 1 |
| 13 | 1 | basic monthly | 2020-12-22 | 9.90 | 1 |
| 15 | 2 | pro monthly | 2020-03-24 | 19.90 | 1 |
| 15 | 2 | pro monthly | 2020-04-24 | 19.90 | 2 |
| 16 | 1 | basic monthly | 2020-06-07 | 9.90 | 1 |
| 16 | 1 | basic monthly | 2020-07-07 | 9.90 | 2 |
| 16 | 1 | basic monthly | 2020-08-07 | 9.90 | 3 |
| 16 | 1 | basic monthly | 2020-09-07 | 9.90 | 4 |
| 16 | 1 | basic monthly | 2020-10-07 | 9.90 | 5 |
| 16 | 3 | pro annual | 2020-10-21 | 189.10 | 6 |
| 18 | 2 | pro monthly | 2020-07-13 | 19.90 | 1 |
| 18 | 2 | pro monthly | 2020-08-13 | 19.90 | 2 |
| 18 | 2 | pro monthly | 2020-09-13 | 19.90 | 3 |
| 18 | 2 | pro monthly | 2020-10-13 | 19.90 | 4 |
| 18 | 2 | pro monthly | 2020-11-13 | 19.90 | 5 |
| 18 | 2 | pro monthly | 2020-12-13 | 19.90 | 6 |
| 19 | 2 | pro monthly | 2020-06-29 | 19.90 | 1 |
| 19 | 2 | pro monthly | 2020-07-29 | 19.90 | 2 |
| 19 | 3 | pro annual | 2020-08-29 | 199.00 | 3 |


### D. Outside The Box Questions
The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!


#### 1. How would you calculate the rate of growth for Foodie-Fi?

My approach would be to measure the rate of growth for Foodie-Fi via active paying subscribers month-over-month because it directly reflects the expansion of the company’s revenue-generating user base.

```sql
WITH monthly_customers AS (
SELECT
DATE_TRUNC('month', start_date) AS month,
COUNT(DISTINCT customer_id) AS new_customers
FROM subscriptions
WHERE plan_id != 0
GROUP BY month
)

SELECT
month,
new_customers,
LAG(new_customers) OVER (ORDER BY month) AS previous_month,
ROUND(
100.0 * (new_customers - LAG(new_customers) OVER (ORDER BY month))
/ LAG(new_customers) OVER (ORDER BY month),
2
) AS growth_rate
FROM monthly_customers;
```

Growth rate =  
(current period customers − previous period customers) ÷ previous period customers.

---

#### 2. What key metrics would you recommend Foodie-Fi management track over time?

Key metrics include:

- **Monthly Active Subscribers** – total paying customers each month  
- **Trial Conversion Rate** – percentage of trial users who convert to a paid plan  
- **Churn Rate** – percentage of customers cancelling subscriptions  
- **Customer Lifetime Value (CLV)** – expected revenue generated per customer  
- **Average Revenue per User (ARPU)** – average monthly revenue per customer  
- **Upgrade Rate** – percentage of users moving to higher-tier plans  
- **Retention Rate** – proportion of customers remaining subscribed over time

---

#### 3. What customer journeys should be analysed to improve retention?

I think that the important customer journeys to analyze are:

- **Trial → churn immediately**  
  Users who cancel right after the trial period.

- **Basic monthly → churn within first few months**  
  Customers who initially convert but leave quickly.

- **Basic monthly → pro monthly upgrades**  
  Understanding what motivates customers to upgrade.

- **Pro monthly → pro annual upgrades**  
  Identifying patterns among long-term committed customers.

- **High-tenure customers who eventually churn**  
  Detecting warning signals before long-term users leave.

---

#### 4. What questions would you include in an exit survey?

Possible exit survey questions:

1. What is the main reason you decided to cancel your subscription?  
2. Did the service provide the value you expected?  
3. Which features were missing or insufficient?  
4. Was pricing a factor in your decision to cancel?  
5. How satisfied were you with the overall experience?  
6. What improvements would make you consider returning?  

---

#### 5. What business levers could reduce churn and how would you validate them?

Possible levers:

- **Improve onboarding experience**  
  Help trial users quickly understand the product value.

- **Targeted retention offers**  
  Discounts or incentives for customers likely to churn.

- **Feature improvements based on user behavior**  
  Prioritize features used by high-retention customers.

- **Flexible pricing options**  
  Offer alternative plans or bundled pricing.

- **Personalized recommendations or engagement content**

Validation methods:

- Run **A/B tests** comparing churn rates between control and treatment groups.  
- Track **retention and engagement metrics** before and after interventions.  
- Monitor **cohort analysis** to see if newer cohorts retain better than previous ones.

