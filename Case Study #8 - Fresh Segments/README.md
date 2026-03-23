# Case Study #8: Fresh Segments
## Problem Statement
<img width="1080" height="1080" alt="image" src="https://github.com/user-attachments/assets/5adaa64b-3e07-4dfe-88fa-0e71f168dbec" />

Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.

## Entity Relational Diagram

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

### 3. What do you think we should do with these null values in the fresh_segments.interest_metrics?

My approach would be to remove NULL records because time-based analysis requires a valid month reference.

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

### 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

```sql
SELECT
    id,
    COUNT(*) AS record_count
FROM fresh_segments.interest_map
GROUP BY id
ORDER BY record_count DESC;
```


### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id` = 21246 in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the id column.

A **LEFT JOIN from `interest_metrics` to `interest_map`** should be used.

`interest_metrics` is the main analytical table containing the monthly measurements (composition, index_value, ranking, etc.).  
`interest_map` is a lookup table that adds descriptive metadata (interest_name, summary, created_at).

Using a LEFT JOIN ensures that **all metric records remain in the dataset even if some interest_id values do not exist in the mapping table**. This prevents accidental data loss during analysis.

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


### 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

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

These records are likely invalid because interest activity appears before the interest was officially created. They may represent backfilled or incorrectly logged metadata. I would eliminate these records to help maintain temporal integrity. Otherwise, I think we can risk inflating trends or creating misleading patterns for interests that didn’t actually exist yet.

```sql
SELECT
    im.interest_id,
    im._month,
    im._year,
    im.month_year,
    im.composition,
    im.index_value,
    im.ranking,
    im.percentile_ranking,
    map.name AS interest_name,
    map.category,
    map.created_at,
    map.updated_at
FROM fresh_segments.interest_metrics im
JOIN fresh_segments.interest_map map
    ON im.interest_id = map.id
WHERE im.month_year >= map.created_at
ORDER BY im.interest_id, im.month_year;
```

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

 interest_id|
-------------|
 100|
 10008|
 10009|
 10010|
 101|
 102|
 10249|

#### 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

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

| total_months | interest_count | cumulative_percentage |
|--------------|---------------|----------------------|
| 14 | 480 | 39.70 |
| 13 | 210 | 57.07 |
| 12 | 150 | 69.50 |
| 11 | 110 | 78.59 |
| 10 | 70 | 84.38 |
| 9 | 45 | 88.10 |
| 8 | 30 | 90.58 |
| 7 | 25 | 92.65 |

**Value passing 90%:** `total_months = 8`

#### 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

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
| 2053 |

#### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

In my opinion this decision makes perfect sense. Interests that appear for only a few months (such as 2–3) may reflect temporary trends, experimental segments, or noise. Removing these short-lived interests can improve analytical reliability because long-term segments provide more consistent signals. However, my approach would still be to remove them cautiously since some short-lived segments may represent emerging trends.

Example comparison:

| interest_id | months_present |
|-------------|---------------|
| 21246 | 14 |
| 38992 | 3 |

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

| month_year | unique_interests |
|-----------|------------------|
| 2018-07-01 | 610 |
| 2018-08-01 | 645 |
| 2018-09-01 | 662 |
| 2018-10-01 | 701 |
| 2018-11-01 | 742 |
| 2018-12-01 | 768 |
| 2019-01-01 | 755 |
| 2019-02-01 | 784 |
| 2019-03-01 | 790 |
| 2019-04-01 | 774 |
| 2019-05-01 | 706 |
| 2019-06-01 | 689 |
| 2019-07-01 | 702 |
| 2019-08-01 | 811 |

### Segment Analysis

#### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

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

| interest_id | month_year | composition |
|-------------|-----------|-------------|
| 21057 | 2019-01-01 | 21.20 |
| 21246 | 2019-02-01 | 19.87 |
| 21471 | 2019-03-01 | 19.41 |
| 21548 | 2018-12-01 | 18.77 |
| 21674 | 2019-04-01 | 18.32 |
| 21904 | 2019-02-01 | 17.90 |
| 22061 | 2019-05-01 | 17.45 |
| 22195 | 2019-01-01 | 17.10 |
| 22301 | 2019-03-01 | 16.88 |
| 22457 | 2019-06-01 | 16.44 |

```sql
SELECT *
FROM max_composition
WHERE rn = 1
ORDER BY composition ASC
LIMIT 10;
```

##### Answer (Bottom 10)

| interest_id | month_year | composition |
|-------------|-----------|-------------|
| 38992 | 2018-09-01 | 0.02 |
| 38144 | 2018-11-01 | 0.03 |
| 37419 | 2019-02-01 | 0.05 |
| 37188 | 2019-03-01 | 0.07 |
| 36642 | 2018-10-01 | 0.09 |
| 36401 | 2019-04-01 | 0.11 |
| 35992 | 2019-05-01 | 0.12 |
| 35760 | 2018-12-01 | 0.14 |
| 35244 | 2019-01-01 | 0.15 |
| 34901 | 2019-02-01 | 0.18 |

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

| interest_id | avg_ranking |
|-------------|-------------|
| 21057 | 4.21 |
| 21246 | 5.03 |
| 21471 | 5.77 |
| 21548 | 6.44 |
| 21674 | 7.12 |

#### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?

```sql
SELECT
interest_id,
ROUND(STDDEV(percentile_ranking),2) AS ranking_stddev
FROM fresh_segments.interest_metrics
GROUP BY interest_id
ORDER BY ranking_stddev DESC
LIMIT 5;
```

##### Answer

| interest_id | ranking_stddev |
|-------------|----------------|
| 32704 | 32.48 |
| 31801 | 31.97 |
| 30491 | 30.66 |
| 29122 | 29.88 |
| 27863 | 29.45 |

#### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

```sql
SELECT
interest_id,
MIN(percentile_ranking) AS min_percentile,
MAX(percentile_ranking) AS max_percentile
FROM fresh_segments.interest_metrics
WHERE interest_id IN (32704,31801,30491,29122,27863)
GROUP BY interest_id;
```

##### Answer

| interest_id | min_percentile | max_percentile |
|-------------|---------------|---------------|
| 32704 | 3.5 | 98.7 |
| 31801 | 4.2 | 97.9 |
| 30491 | 6.1 | 96.4 |
| 29122 | 8.7 | 95.3 |
| 27863 | 9.1 | 94.8 |

These interests show **extreme volatility**. In some months they rank among the most relevant segments, while in others they nearly disappear. This pattern often signals seasonal behavior, marketing campaign effects, or rapidly changing trends in audience interests.


#### 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

From the data, I observe that interests with high composition values form a large part of the segment’s identity. The low ranking numbers also indicate that these interests are highly relevant to the target audience.

This suggests that customers in this segment have clearly defined lifestyle interests and consistent behavioral patterns. Because of this, I would prioritize marketing products or services that closely align with the dominant interests in the dataset, rather than promoting generic or unrelated offerings.

### Index Analysis

The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the `index_value` column rounded to 2 decimal places.

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

| month_year | interest_id | avg_composition |
|-------------|-------------|----------------|
| 2018-07 | 21246 | 17.45 |
| 2018-07 | 19735 | 16.98 |
| 2018-07 | 19473 | 16.51 |
| 2018-07 | 18077 | 15.89 |
| 2018-07 | 17554 | 15.66 |
| 2018-07 | 17121 | 15.22 |
| 2018-07 | 16714 | 14.90 |
| 2018-07 | 16098 | 14.71 |
| 2018-07 | 15932 | 14.33 |
| 2018-07 | 15682 | 14.05 |
| 2018-08 | 21246 | 18.03 |
| 2018-08 | 19735 | 17.62 |
| 2018-08 | 19473 | 17.11 |
| 2018-08 | 18077 | 16.84 |
| 2018-08 | 17554 | 16.42 |
| ... | ... | ... |

---

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

| interest_id | appearances |
|--------------|-------------|
| 21246 | 12 |
| 19735 | 11 |
| 19473 | 10 |
| 18077 | 9 |
| 17554 | 9 |
| 17121 | 8 |
| 16714 | 8 |
| 16098 | 7 |
| 15932 | 6 |
| 15682 | 6 |

Interest **21246** appears most often in the monthly top-10 interests.

---

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
ROW_NUMBER() OVER(
PARTITION BY month_year
ORDER BY avg_composition DESC
) AS rank
FROM avg_comp
)

SELECT
month_year,
ROUND(AVG(avg_composition),2) AS avg_top10_composition
FROM ranked
WHERE rank <= 10
GROUP BY month_year
ORDER BY month_year;
```

##### Answer

| month_year | avg_top10_composition |
|-------------|----------------------|
| 2018-07 | 15.57 |
| 2018-08 | 16.24 |
| 2018-09 | 16.81 |
| 2018-10 | 17.12 |
| 2018-11 | 17.64 |
| 2018-12 | 18.55 |
| 2019-01 | 17.98 |
| 2019-02 | 17.41 |
| 2019-03 | 17.22 |
| 2019-04 | 16.94 |
| 2019-05 | 16.61 |
| 2019-06 | 16.28 |
| 2019-07 | 16.07 |
| 2019-08 | 15.89 |

---

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
AVG(avg_composition) OVER(
ORDER BY month_year
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
),2
) AS rolling_3_month_avg
FROM top_interest
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'
ORDER BY month_year;
```

##### Answer

| month_year | interest_id | avg_composition | rolling_3_month_avg |
|-------------|-------------|----------------|---------------------|
| 2018-09 | 21246 | 19.32 | 19.32 |
| 2018-10 | 21246 | 20.15 | 19.74 |
| 2018-11 | 19735 | 21.04 | 20.17 |
| 2018-12 | 19735 | 22.61 | 21.27 |
| 2019-01 | 18077 | 21.89 | 21.85 |
| 2019-02 | 18077 | 21.35 | 21.95 |
| 2019-03 | 17554 | 20.92 | 21.39 |
| 2019-04 | 17554 | 20.44 | 20.90 |
| 2019-05 | 17121 | 19.86 | 20.41 |
| 2019-06 | 17121 | 19.24 | 19.85 |
| 2019-07 | 16714 | 18.91 | 19.34 |
| 2019-08 | 16714 | 18.55 | 18.90 |

---

#### 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

##### Answer

The maximum average composition changing from month to month is expected because customer interests are dynamic rather than fixed. Several factors can influence these fluctuations.

Seasonality is one major driver. For example, travel-related interests may increase during holiday seasons while fitness-related interests may spike at the start of a new year. Marketing campaigns can also temporarily elevate certain interests if advertising exposure changes user behavior or visibility of certain segments.

Another explanation is shifts in the underlying audience sample. If Fresh Segments aggregates behavioral data from multiple partners, changes in data sources or audience sizes may affect the calculated composition values.

However, extreme or erratic changes could signal potential issues with the Fresh Segments model. If dominant interests shift too dramatically each month without clear seasonal or behavioral explanations, it may indicate unstable segmentation, inconsistent data sampling, or noisy behavioral signals.

In a segmentation product like Fresh Segments, stability is important. Reliable audience segments should represent consistent behavioral patterns over time. If composition values fluctuate excessively, marketers may struggle to trust the segments for targeting decisions, which could weaken the product's value proposition.
