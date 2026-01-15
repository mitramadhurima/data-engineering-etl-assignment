-- =========================================================
-- Pipeline Execution Logging
-- =========================================================

CREATE TABLE pipeline_run_log (
    pipeline_name VARCHAR(100),
    run_id VARCHAR(50),
    run_start_time TIMESTAMP,
    run_end_time TIMESTAMP,
    status VARCHAR(20),
    records_processed INT,
    error_message VARCHAR(500)
);

-- Example log entry (simulated)
INSERT INTO pipeline_run_log VALUES (
    'orders_etl_pipeline',
    'run_20250101_01',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'SUCCESS',
    250,
    NULL
);
