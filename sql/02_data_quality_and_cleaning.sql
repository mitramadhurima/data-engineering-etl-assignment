-- Reject table for bad records
CREATE TABLE rejected_orders (
  order_id INT,
  rejection_reason VARCHAR(100)
);

-- Cleaned orders with validation
CREATE TABLE cleaned_orders AS
SELECT
  order_id,
  customer_id,
  order_amount,
  UPPER(TRIM(order_status)) AS order_status,
  created_at,
  updated_at
FROM raw_orders
WHERE
  order_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND order_amount > 0;

-- Capture rejected records
INSERT INTO rejected_orders
SELECT order_id, 'Missing customer_id or invalid amount'
FROM raw_orders
WHERE customer_id IS NULL OR order_amount <= 0;
