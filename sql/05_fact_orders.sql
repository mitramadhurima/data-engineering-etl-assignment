-- Fact table: one row per order (Grain = order)
CREATE TABLE fact_orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  date_id DATE,
  order_amount DECIMAL(10,2),
  order_status VARCHAR(20)
);
