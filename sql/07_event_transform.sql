-- =========================================================
-- Event / Log Data Transformation (Silver Layer)
-- =========================================================

CREATE TABLE cleaned_events AS
SELECT
    event_id,
    user_id,
    LOWER(TRIM(event_type)) AS event_type,
    CAST(event_time AS TIMESTAMP) AS event_time,
    metadata
FROM raw_events
WHERE
    event_id IS NOT NULL
    AND user_id IS NOT NULL
    AND event_time IS NOT NULL;
