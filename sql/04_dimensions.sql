-- Customer Dimension
CREATE TABLE dim_customer AS
SELECT DISTINCT
  customer_id,
  MIN(created_at) AS first_order_date
FROM dedup_orders
GROUP BY customer_id;

-- Date Dimension
CREATE TABLE dim_date AS
SELECT DISTINCT
  CAST(created_at AS DATE) AS date_id,
  EXTRACT(YEAR FROM created_at) AS year,
  EXTRACT(MONTH FROM created_at) AS month,
  EXTRACT(DAY FROM created_at) AS day
FROM dedup_orders;
