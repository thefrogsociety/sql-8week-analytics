# Case Study #8: Fresh Segments
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/5adaa64b-3e07-4dfe-88fa-0e71f168dbec" />

Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

## Entity Relational Diagram
<img width="584" height="408" alt="8" src="https://github.com/user-attachments/assets/38cb6073-c652-4965-955e-9308a25995c3" />

## Data Exploration and Cleansing

### 1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month
```sql
UPDATE fresh_segments.interest_metrics
SET month_year = TO_DATE(_month || '-' || _year, 'MM-YYYY');
```

### 2. What is count of records in the `fresh_segments.interest_metrics` for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT
month_year,
COUNT(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year NULLS FIRST;
```

##### Answer

| month_year | record_count|
|------------|-------------|
|            |         1194|
| 2018-07-01 |          729|
| 2018-08-01 |          767|
| 2018-09-01 |          780|
| 2018-10-01 |          857|
| 2018-11-01 |          928|
| 2018-12-01 |          995|
| 2019-01-01 |          973|
| 2019-02-01 |         1121|
| 2019-03-01 |         1136|
| 2019-04-01 |         1099|
| 2019-05-01 |          857|
| 2019-06-01 |          824|
| 2019-07-01 |          864|
| 2019-08-01 |         1149|

### 3. What do you think we should do with these null values in the `fresh_segments.interest_metrics`?

I treat null values as indicators of where metrics could not be computed rather than simply missing data. I keep them when examining data coverage, cold-start behavior, or quality issues, but exclude them when calculating averages, ranking interests, or analyzing trends to ensure results reflect only valid, computed values.

### 4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?

```sql
SELECT
COUNT(DISTINCT mp.id) AS map_not_in_metrics
FROM fresh_segments.interest_map mp
LEFT JOIN fresh_segments.interest_metrics im
  ON mp.id::TEXT = im.interest_id
WHERE im.interest_id IS NULL;
```
##### Answer

| metrics_not_in_map|
|-------------------|
|                  0|

```sql
SELECT
COUNT(DISTINCT mp.id) AS map_not_in_metrics
FROM fresh_segments.interest_map mp
LEFT JOIN fresh_segments.interest_metrics im
  ON mp.id::TEXT = im.interest_id
WHERE im.interest_id IS NULL;
```

##### Answer

| map_not_in_metrics|
|-------------------|
|                  7|

### 5. Summarise the id values in the `fresh_segments.interest_map` by its total record count in this table

```sql
SELECT
    id,
    COUNT(*) AS record_count
FROM fresh_segments.interest_map
GROUP BY id
ORDER BY record_count DESC;
```

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id` = 21246 in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the id column.

A `LEFT JOIN` from `interest_metrics` to `interest_map` should be used.

`interest_metrics` is the main analytical table containing the monthly measurements (composition, index_value, ranking, etc.).  
`interest_map` is a lookup table that adds descriptive metadata (interest_name, summary, created_at).

Using a `LEFT JOIN` ensures that **all metric records remain in the dataset even if some interest_id values do not exist in the mapping table**. This prevents accidental data loss during analysis.

```sql
SELECT
    im.*,
    mp.interest_name,
    mp.interest_summary,
    mp.created_at,
    mp.last_modified
FROM fresh_segments.interest_metrics im
LEFT JOIN fresh_segments.interest_map mp
    ON im.interest_id = mp.id::TEXT
WHERE im.interest_id = '21246';
```


### 7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `fresh_segments.interest_map` table? Do you think these values are valid and why?

```sql
SELECT
    im.interest_id,
    im.month_year,
    mp.created_at
FROM fresh_segments.interest_metrics im
LEFT JOIN fresh_segments.interest_map mp
    ON im.interest_id = mp.id::TEXT
WHERE im.month_year < mp.created_at;
```

##### Answer

| interest_id | month_year |     created_at     | 
|-------------|------------|--------------------|
| 35903       | 2018-09-01 | 2018-09-05 18:10:03|
| 41547       | 2018-12-01 | 2018-12-03 11:10:04|
| 32701       | 2018-07-01 | 2018-07-06 14:35:03|
| ... | ... | ... |

Yes, there are records where `month_year` is earlier than `created_at`.
These are likely not valid under normal assumptions, because metrics should not exist before the interest itself is created.
However, if `created_at` reflects when the interest was added to the system (rather than when it first existed in reality), then these records could be explained by historical backfilling or delayed data entry.

## Questions and Answers

### Interest Analysis

#### 1. Which interests have been present in all month_year dates in our dataset?

```sql
WITH interest_month_counts AS (
SELECT
interest_id,
COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id
)

SELECT interest_id
FROM interest_month_counts
WHERE total_months = (
SELECT COUNT(DISTINCT month_year)
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL
);
```

##### Answer

| interest_id|
|-------------|
| 100|
| 10008|
| 10009|
| 10010|
| 101|
| 102|
| 10249|

#### 2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?

```sql
WITH interest_month_counts AS (
SELECT
interest_id,
COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id
),

month_distribution AS (
SELECT
total_months,
COUNT(*) AS interest_count
FROM interest_month_counts
GROUP BY total_months
),

running_totals AS (
SELECT
total_months,
interest_count,
SUM(interest_count) OVER (ORDER BY total_months DESC) AS cumulative_interests,
SUM(interest_count) OVER () AS total_interests
FROM month_distribution
)

SELECT
total_months,
interest_count,
ROUND(100 * cumulative_interests / total_interests,2) AS cumulative_percentage
FROM running_totals
ORDER BY total_months DESC;
```

##### Answer

| total_months | interest_count | cumulative_percentage|
|--------------|----------------|----------------------|
|           14 |            480 |                 39.90|
|           13 |             82 |                 46.72|
|           12 |             65 |                 52.12|
|           11 |             94 |                 59.93|
|           10 |             86 |                 67.08|
|            9 |             95 |                 74.98|
|            8 |             67 |                 80.55|
|            7 |             90 |                 88.03|
|            6 |             33 |                 90.77|
|            5 |             38 |                 93.93|
|            4 |             32 |                 96.59|
|            3 |             15 |                 97.84|
|            2 |             12 |                 98.84|
|            1 |             13 |                 99.92|

**Value passing 90%:** `total_months = 6`

#### 3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?

```sql
WITH interest_month_counts AS (
SELECT
interest_id,
COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id
)

SELECT COUNT(*) AS removed_rows
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
SELECT interest_id
FROM interest_month_counts
WHERE total_months < 8
);
```

##### Answer

| removed_rows |
|--------------|
| 1228 |

#### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

In my opinion this decision makes perfect sense. Interests that appear for only a few months (such as 2–3) may reflect temporary trends, experimental segments, or noise. Removing these short-lived interests can improve analytical reliability because long-term segments provide more consistent signals. However, my approach would still be to remove them cautiously since some short-lived segments may represent emerging trends.

#### 5. After removing these interests - how many unique interests are there for each month?

```sql
WITH interest_month_counts AS (
SELECT
interest_id,
COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id
),

filtered_metrics AS (
SELECT *
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
SELECT interest_id
FROM interest_month_counts
WHERE total_months >= 8
)
)

SELECT
month_year,
COUNT(DISTINCT interest_id) AS unique_interests
FROM filtered_metrics
GROUP BY month_year
ORDER BY month_year;
```

##### Answer

| month_year | unique_interests|
|------------|-----------------|
| 2018-07-01 |              694|
| 2018-08-01 |              735|
| 2018-09-01 |              759|
| 2018-10-01 |              833|
| 2018-11-01 |              899|
| 2018-12-01 |              952|
| 2019-01-01 |              934|
| 2019-02-01 |              965|
| 2019-03-01 |              960|
| 2019-04-01 |              933|
| 2019-05-01 |              753|
| 2019-06-01 |              728|
| 2019-07-01 |              759|
| 2019-08-01 |              947|
|            |                1|

### Segment Analysis

#### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any `month_year`? Only use the maximum composition value for each interest but you must keep the corresponding `month_year`

```sql
WITH interest_month_counts AS (
SELECT
interest_id,
COUNT(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id
),

filtered_metrics AS (
SELECT *
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
SELECT interest_id
FROM interest_month_counts
WHERE total_months >= 6
)
),

max_composition AS (
SELECT
interest_id,
month_year,
composition,
ROW_NUMBER() OVER(
PARTITION BY interest_id
ORDER BY composition DESC
) AS rn
FROM filtered_metrics
)

SELECT *
FROM max_composition
WHERE rn = 1
ORDER BY composition DESC
LIMIT 10;
```

##### Answer (Top 10)

| interest_id | month_year | composition | rn|
|-------------|------------|-------------|---|
| 21057       | 2018-12-01 |        21.2 |  1|
| 6284        | 2018-07-01 |       18.82 |  1|
| 39          | 2018-07-01 |       17.44 |  1|
| 77          | 2018-07-01 |       17.19 |  1|
| 12133       | 2018-10-01 |       15.15 |  1|
| 5969        | 2018-12-01 |       15.05 |  1|
| 171         | 2018-07-01 |       14.91 |  1|
| 4898        | 2018-07-01 |       14.23 |  1|
| 6286        | 2018-07-01 |        14.1 |  1|
| 4           | 2018-07-01 |       13.97 |  1|

```sql
WITH interest_month_counts AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
),

filtered_metrics AS (
    SELECT *
    FROM fresh_segments.interest_metrics
    WHERE interest_id IN (
        SELECT interest_id
        FROM interest_month_counts
        WHERE total_months >= 6
    )
),

min_composition AS (
    SELECT
        interest_id,
        month_year,
        composition,
        ROW_NUMBER() OVER (
            PARTITION BY interest_id
            ORDER BY composition ASC
        ) AS rn
    FROM filtered_metrics
)

SELECT *
FROM min_composition
WHERE rn = 1
ORDER BY composition ASC
LIMIT 10;
```

##### Answer (Bottom 10)

| interest_id | month_year | composition | rn|
|-------------|------------|-------------|---|
| 45524       | 2019-05-01 |        1.51 |  1|
| 20768       | 2019-05-01 |        1.52 |  1|
| 34083       | 2019-06-01 |        1.52 |  1|
| 44449       | 2019-04-01 |        1.52 |  1|
| 35742       | 2019-06-01 |        1.52 |  1|
| 4918        | 2019-05-01 |        1.52 |  1|
| 39336       | 2019-05-01 |        1.52 |  1|
| 6127        | 2019-05-01 |        1.53 |  1|
| 36877       | 2019-05-01 |        1.53 |  1|
| 6314        | 2019-06-01 |        1.53 |  1|

#### 2. Which 5 interests had the lowest average ranking value?

```sql
SELECT
interest_id,
ROUND(AVG(ranking),2) AS avg_ranking
FROM fresh_segments.interest_metrics
GROUP BY interest_id
ORDER BY avg_ranking
LIMIT 5;
```

##### Answer

| interest_id | avg_ranking|
|-------------|------------|
| 41548       |        1.00|
| 42203       |        4.11|
| 115         |        5.93|
| 48154       |        7.80|
| 171         |        9.36|

#### 3. Which 5 interests had the largest standard deviation in their `percentile_ranking` value?

```sql
SELECT
    interest_id,
    STDDEV(percentile_ranking) AS stddev_percentile
FROM fresh_segments.interest_metrics
WHERE percentile_ranking IS NOT NULL
GROUP BY interest_id
HAVING COUNT(percentile_ranking) >= 2
ORDER BY stddev_percentile DESC
LIMIT 5;
```

##### Answer

| interest_id | stddev_percentile  |
|-------------|--------------------|
| 6260        |  41.27382281785878 |
| 131         | 30.720767894048482 |
| 150         | 30.363974871548024 |
| 23          | 30.175047086403474 |
| 20764       |  28.97491995962485 |

#### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

```sql
WITH stddev_interests AS (
    SELECT
        interest_id,
        STDDEV(percentile_ranking) AS stddev_percentile
    FROM fresh_segments.interest_metrics
    WHERE percentile_ranking IS NOT NULL
    GROUP BY interest_id
    ORDER BY stddev_percentile DESC
    LIMIT 5
),

ranked AS (
    SELECT
        im.interest_id,
        im.month_year,
        im.percentile_ranking,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.percentile_ranking ASC
        ) AS min_rank,
        ROW_NUMBER() OVER (
            PARTITION BY im.interest_id
            ORDER BY im.percentile_ranking DESC
        ) AS max_rank
    FROM fresh_segments.interest_metrics im
    JOIN stddev_interests s
        ON im.interest_id = s.interest_id
    WHERE im.percentile_ranking IS NOT NULL
)

SELECT
    interest_id,
    MAX(CASE WHEN min_rank = 1 THEN percentile_ranking END) AS min_percentile,
    MAX(CASE WHEN min_rank = 1 THEN month_year END) AS min_month,
    MAX(CASE WHEN max_rank = 1 THEN percentile_ranking END) AS max_percentile,
    MAX(CASE WHEN max_rank = 1 THEN month_year END) AS max_month
FROM ranked
GROUP BY interest_id;
```

##### Answer

| interest_id | min_percentile | min_month  | max_percentile | max_month  |
|-------------|----------------|------------|----------------|------------|
| 19626       |           4.25 | 2018-07-01 |           4.25 | 2018-07-01 |
| 34950       |           1.15 | 2018-09-01 |           1.15 | 2018-09-01 |
| 42008       |           0.09 | 2019-03-01 |           0.09 | 2019-03-01 |
| 44461       |           10.7 | 2019-02-01 |           10.7 | 2019-02-01 |
| 5999        |          59.67 | 2018-07-01 |          59.67 | 2018-07-01 |

These interests show high variability in their percentile rankings across different months, with large gaps between their minimum and maximum values. This suggests that their popularity or engagement is highly inconsistent, possibly driven by seasonal trends, short-term events, or sudden spikes in user interest. Unlike stable interests, these topics may experience bursts of relevance followed by periods of low engagement.

#### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

Customers in this segment show strong affinity toward a concentrated set of interests, as indicated by high composition values. Several of these interests also rank highly relative to others, suggesting that these preferences are not only strong within the segment but also broadly significant.

At the same time, some interests exhibit high composition but lower rankings, indicating niche preferences that are distinctive to this group. Overall, this suggests a segment with both mainstream engagement and specific, differentiated interests.

### Index Analysis

> The `index_value` is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

>Average composition can be calculated by dividing the composition column by the `index_value` column rounded to 2 decimal places.

#### 1. What is the top 10 interests by the average composition for each month?

```sql
WITH avg_comp AS (
SELECT
month_year,
interest_id,
AVG(composition) AS avg_composition
FROM fresh_segments.interest_metrics
GROUP BY month_year, interest_id
),

ranked AS (
SELECT
month_year,
interest_id,
avg_composition,
ROW_NUMBER() OVER(
PARTITION BY month_year
ORDER BY avg_composition DESC
) AS rank
FROM avg_comp
)

SELECT
month_year,
interest_id,
avg_composition
FROM ranked
WHERE rank <= 10
ORDER BY month_year, rank;
```

##### Answer

| month_year | interest_id |  avg_composition   |
|------------+-------------+--------------------|
| 2018-07-01 | 6284        |              18.82|
| 2018-07-01 | 39          |              17.44|
| 2018-07-01 | 77          |              17.19|
| 2018-07-01 | 171         |              14.91|
| 2018-07-01 | 4898        |              14.23|
| 2018-07-01 | 6286        |               14.1|
| 2018-07-01 | 4           |              13.97|
| 2018-07-01 | 17786       |              13.67|
| 2018-07-01 | 6184        |              13.35|
| 2018-07-01 | 4897        |              12.93|
| 2018-08-01 | 6284        |               13.9|
| 2018-08-01 | 77          |              12.73|
| 2018-08-01 | 21057       |              12.42|
| 2018-08-01 | 39          |              12.03|
|...|...|...|

#### 2. For all of these top 10 interests - which interest appears the most often?

```sql
WITH avg_comp AS (
SELECT
month_year,
interest_id,
AVG(composition) AS avg_composition
FROM fresh_segments.interest_metrics
GROUP BY month_year, interest_id
),

ranked AS (
SELECT
month_year,
interest_id,
avg_composition,
ROW_NUMBER() OVER(
PARTITION BY month_year
ORDER BY avg_composition DESC
) AS rank
FROM avg_comp
),

top10 AS (
SELECT
month_year,
interest_id
FROM ranked
WHERE rank <= 10
)

SELECT
interest_id,
COUNT(*) AS appearances
FROM top10
GROUP BY interest_id
ORDER BY appearances DESC;
```

##### Answer

| interest_id | appearances|
|-------------|------------|
| 6284        |          12|
| 5969        |          12|
| 12133       |          11|
| 6286        |          11|
| 77          |          10|
| 19298       |          10|
| 10977       |           9|
| 64          |           8|
|...|...|

#### 3. What is the average of the average composition for the top 10 interests for each month?

```sql
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        AVG(composition) AS avg_composition
    FROM fresh_segments.interest_metrics
    GROUP BY month_year, interest_id
),

ranked AS (
    SELECT
        month_year,
        interest_id,
        avg_composition,
        ROW_NUMBER() OVER (
            PARTITION BY month_year
            ORDER BY avg_composition DESC
        ) AS rank
    FROM avg_comp
),

top10 AS (
    SELECT *
    FROM ranked
    WHERE rank <= 10
)

SELECT
    month_year,
    ROUND(AVG(avg_composition)::NUMERIC, 2) AS avg_of_top10
FROM top10
GROUP BY month_year
ORDER BY month_year;
```

##### Answer

| month_year | avg_of_top10|
|------------|-------------|
| 2018-07-01 |        15.06|
| 2018-08-01 |        10.82|
| 2018-09-01 |        12.20|
| 2018-10-01 |        13.67|
| 2018-11-01 |        12.26|
| 2018-12-01 |        13.22|
| 2019-01-01 |        12.11|
| 2019-02-01 |        12.54|
| 2019-03-01 |        10.89|
| 2019-04-01 |         9.55|
| 2019-05-01 |         6.38|
| 2019-06-01 |         5.11|
| 2019-07-01 |         5.82|
| 2019-08-01 |         6.31|
|            |         2.77|

#### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output?

```sql
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        AVG(composition) AS avg_composition
    FROM fresh_segments.interest_metrics
    GROUP BY month_year, interest_id
),

ranked AS (
    SELECT
        month_year,
        interest_id,
        avg_composition,
        ROW_NUMBER() OVER(
            PARTITION BY month_year
            ORDER BY avg_composition DESC
        ) AS rank
    FROM avg_comp
),

top_interest AS (
    SELECT
        month_year,
        interest_id,
        avg_composition
    FROM ranked
    WHERE rank = 1
)

SELECT
    month_year,
    interest_id,
    avg_composition,
    ROUND(
        AVG(avg_composition) OVER (
            ORDER BY month_year
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        )::NUMERIC, 2
    ) AS rolling_3_month_avg
FROM top_interest
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'
ORDER BY month_year;
```

##### Answer

| month_year | interest_id | avg_composition | rolling_3_month_avg|
|------------|-------------|-----------------|--------------------|
| 2018-09-01 | 21057       |           18.18 |               18.18|
| 2018-10-01 | 21057       |           20.28 |               19.23|
| 2018-11-01 | 21057       |           19.45 |               19.30|
| 2018-12-01 | 21057       |            21.2 |               20.31|
| 2019-01-01 | 21057       |           18.99 |               19.88|
| 2019-02-01 | 21057       |           18.39 |               19.53|
| 2019-03-01 | 12133       |           12.64 |               16.67|
| 2019-04-01 | 5969        |           11.01 |               14.01|
| 2019-05-01 | 5969        |            7.53 |               10.39|
| 2019-06-01 | 6284        |            6.94 |                8.49|
| 2019-07-01 | 6284        |            7.19 |                7.22|
| 2019-08-01 | 6284        |             7.1 |                7.08|


#### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

##### Answer

The maximum average composition changes from month to month likely because customer interests naturally fluctuate. Some topics spike in popularity during certain seasons or campaigns. It could also reflect shifts in how engaged the segment is, or minor quirks in the way metrics like composition and index value are calculated. While this variability might suggest that the business relies heavily on a few dominant interests, it isn’t necessarily a red flag. As long as the patterns are explainable, these fluctuations reflect normal shifts in customer behavior rather than a fundamental problem with Fresh Segments’ business model.
