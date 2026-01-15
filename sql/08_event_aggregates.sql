-- =========================================================
-- Event-Level Business Aggregations (Gold Layer)
-- =========================================================

CREATE TABLE fact_event_metrics AS
SELECT
    e.user_id,
    CAST(e.event_time AS DATE) AS event_date,
    COUNT(*) AS total_events,
    COUNT(CASE WHEN e.event_type = 'page_view' THEN 1 END) AS page_views,
    COUNT(CASE WHEN e.event_type = 'checkout' THEN 1 END) AS checkouts
FROM cleaned_events e
GROUP BY
    e.user_id,
    CAST(e.event_time AS DATE);
