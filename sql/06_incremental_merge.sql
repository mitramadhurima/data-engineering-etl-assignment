-- Idempotent MERGE to support incremental loads
-- Safe for re-runs without duplication

MERGE INTO fact_orders f
USING dedup_orders s
ON f.order_id = s.order_id

WHEN MATCHED THEN
  UPDATE SET
    order_amount = s.order_amount,
    order_status = s.order_status,
    date_id = CAST(s.created_at AS DATE)

WHEN NOT MATCHED THEN
  INSERT (
    order_id,
    customer_id,
    date_id,
    order_amount,
    order_status
  )
  VALUES (
    s.order_id,
    s.customer_id,
    CAST(s.created_at AS DATE),
    s.order_amount,
    s.order_status
  );
