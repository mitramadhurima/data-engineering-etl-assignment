-- Raw transactional orders (Relational source)
CREATE TABLE raw_orders (
  order_id INT,
  customer_id INT,
  order_amount DECIMAL(10,2),
  order_status VARCHAR(20),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Raw event/log data (NoSQL-style source)
CREATE TABLE raw_events (
  event_id VARCHAR(50),
  user_id INT,
  event_type VARCHAR(50),
  event_time TIMESTAMP,
  metadata JSON
);
