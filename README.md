# Data Engineering Assignment – ETL & Data Modeling

## 1. Overview
This repository demonstrates an **end-to-end data engineering solution** covering ingestion, transformation, data modeling, and reliability considerations. The solution simulates a real-world analytics pipeline handling **transactional (relational) data** and **event/log (semi-structured) data**, following industry-standard ETL practices.

The design emphasizes:
- Incremental processing
- SQL-based transformations
- Clear separation of raw, processed, and analytics layers
- Practical decision-making between SQL and NoSQL data stores

---

## 2. High-Level Architecture

**Sources**
- Transactional relational data (CSV / RDBMS extract)
- Event/log data (JSON – semi-structured)

**Pipeline Flow**
1. Ingest data incrementally using Azure Data Factory (ADF – mocked)
2. Store raw data in a NoSQL-style landing zone (JSON files)
3. Transform and cleanse data using SQL
4. Load analytics-ready tables into a relational database

**Storage Layers**
- **Raw / Bronze**: JSON files (simulating NoSQL document store)
- **Curated / Silver**: Cleaned relational staging tables
- **Analytics / Gold**: Fact and Dimension tables

Transactional Source → ADF Pipeline
New or updated transactional records are extracted incrementally from the relational source using a watermark (updated_at). This avoids full reloads and improves pipeline efficiency.

Event / Log Source → ADF Pipeline
Semi-structured event or log data (JSON) is ingested as-is. No transformations are applied at this stage to preserve schema flexibility.

ADF Pipeline → Raw / Bronze (NoSQL Store)
Ingested data is landed into a raw storage layer that preserves the original structure. Transactional data is stored in raw relational tables, while event data is stored as JSON documents. This layer acts as a system-of-record.

Raw / Bronze → Silver (SQL Transformations)
Raw data is cleaned, validated, standardized, and deduplicated using SQL. Invalid records are filtered or routed to reject tables, and semi-structured event data is parsed into structured columns.

Silver → Gold (Fact & Dimension Tables)
Cleaned data is transformed into analytics-ready fact and dimension tables. Business-level aggregations are applied, and primary/foreign key relationships are established to support reporting and BI use cases.

Gold → BI / Reporting
BI tools and analytics users query the Gold layer directly. This layer provides stable schemas, optimized performance, and reliable metrics without requiring complex transformations at query time.

Incremental MERGE (Gold Layer Updates)
MERGE-based logic ensures idempotent loads, allowing the pipeline to be safely re-run while correctly handling late-arriving or updated records.

---

## 3. Technology Choices (Mocked)

| Layer | Technology | Reasoning |
|-----|-----------|-----------|
| Ingestion | Azure Data Factory (ADF) | Industry-standard orchestration, supports incremental loads |
| Raw Storage | NoSQL-style JSON (Data Lake / Cosmos-like) | Flexible schema, supports semi-structured event data |
| Transformation | SQL | Strong for joins, aggregations, window functions |
| Analytics Store | Relational DB (PostgreSQL / Azure SQL) | Optimized for reporting and BI |

---

## 4. Data Sources & Assumptions

### 4.1 Transactional Data (Relational)
Assumed source table: `orders`

| Column | Type | Description |
|------|-----|-------------|
| order_id | INT | Primary key |
| customer_id | INT | Customer identifier |
| order_amount | DECIMAL | Order value |
| order_status | VARCHAR | COMPLETED / CANCELLED |
| created_at | TIMESTAMP | Order creation time |
| updated_at | TIMESTAMP | Last update time |

Assumptions:
- `updated_at` is used for incremental loads
- One record per order

---

### 4.2 Event / Log Data (NoSQL)
Assumed event structure (JSON):
```json
{
  "event_id": "evt_001",
  "user_id": 101,
  "event_type": "page_view",
  "event_time": "2025-01-01T10:00:00Z",
  "metadata": { "page": "/checkout" }
}
```

Assumptions:
- Schema may evolve
- High volume
- Stored as raw JSON

---

## 5. Data Modeling

### 5.1 Analytics (Relational – Star Schema)

#### Dimension Tables

**dim_customer**
- customer_id (PK)
- first_order_date

**dim_date**
- date_id (PK)
- calendar_date
- year
- month
- day

#### Fact Table

**fact_orders**
- order_id (PK)
- customer_id (FK)
- date_id (FK)
- order_amount
- order_status

**Why Star Schema?**
- Optimized for analytics
- Simple joins
- BI-friendly

---

### 5.2 NoSQL Model

Chosen model: **Document-based (JSON)**

Reasoning:
- Event data is semi-structured
- Schema evolution is expected
- Write-heavy workload
- Query patterns are exploratory

---

## 6. ETL Pipeline Design

This section explains **how each SQL script participates in the ETL flow**, mapped clearly to pipeline stages. The pipeline processes **both transactional data and event/log data**

### 6.1 Raw Ingestion (Bronze Layer)

**SQL File:** `sql/01_raw_load.sql`

Purpose:
- Creates raw landing tables for transactional (orders) and event/log data
- No business logic applied at this stage
- Data is stored exactly as received from source systems

Transactional data follows schema-on-write, while event data follows schema-on-read principles.

---

### 6.2 Data Quality & Cleaning – Transactional Data (Silver Layer)

**SQL File:** `sql/02_data_quality_and_cleaning.sql`

Purpose:
- Validates mandatory fields (order_id, customer_id, order_amount)
- Standardizes text fields (order_status)
- Routes invalid records to a dedicated reject table (`rejected_orders`)

This ensures only trusted data flows into analytics layers.

---

### 6.3 Event / Log Data Transformation (Silver Layer)

**SQL File:** `sql/07_event_transform.sql`

Purpose:
- Parses semi-structured event data into relational columns
- Standardizes event types and timestamps
- Filters malformed or incomplete event records

Event data is retained in raw form in the NoSQL layer while also producing structured views for analytics.

---

### 6.4 Deduplication & Late-Arriving Data Handling

**SQL File:** `sql/03_deduplication.sql`

Purpose:
- Removes duplicate transactional records using window functions
- Retains the latest version of each order based on updated_at
- Handles late-arriving updates safely

---

### 6.5 Dimension Modeling (Gold Layer)

**SQL File:** `sql/04_dimensions.sql`

Purpose:
- Builds analytics-ready dimension tables with explicit primary keys
- `dim_customer` supports customer-level analysis
- `dim_date` enables time-series analysis

Primary and foreign key relationships are defined to ensure referential integrity.

---

### 6.6 Fact Table Creation – Business Metrics

**SQL Files:**
- `sql/05_fact_orders.sql`
- `sql/08_event_aggregates.sql`

Purpose:
- `fact_orders` stores order-level business metrics
- `fact_event_metrics` aggregates event data (e.g., events per user per day)

This demonstrates business-level SQL transformations using joins and aggregations.

---

### 6.7 Incremental, Idempotent Loads & Pipeline Logging

**SQL Files:**
- `sql/06_incremental_merge.sql`
- `sql/09_pipeline_logging.sql`

Purpose:
- Performs MERGE-based upserts for idempotent processing
- Tracks pipeline execution status, row counts, and errors
- Enables safe retries and operational monitoring

This design supports production-grade reliability and observability.

---

### 6.2 Transformation (SQL)

#### Data Cleaning
- Remove NULL `customer_id`
- Filter invalid order amounts
- Normalize status values

```sql
CREATE TABLE staging_orders AS
SELECT
  order_id,
  customer_id,
  order_amount,
  UPPER(order_status) AS order_status,
  created_at,
  updated_at
FROM raw_orders
WHERE customer_id IS NOT NULL
  AND order_amount > 0;
```

---

#### Deduplication Using Window Functions

```sql
CREATE TABLE dedup_orders AS
SELECT * FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) AS rn
  FROM staging_orders
) t
WHERE rn = 1;
```

---

### 6.3 Load (Idempotent)

```sql
MERGE INTO fact_orders f
USING dedup_orders s
ON f.order_id = s.order_id
WHEN MATCHED THEN
  UPDATE SET
    order_amount = s.order_amount,
    order_status = s.order_status
WHEN NOT MATCHED THEN
  INSERT (order_id, customer_id, date_id, order_amount, order_status)
  VALUES (s.order_id, s.customer_id, CAST(s.created_at AS DATE), s.order_amount, s.order_status);
```

---

## 7. Data Quality & Reliability

### Validation Checks
- Null checks on primary and foreign keys
- Duplicate detection using window functions
- Schema validation for semi-structured event data

### Error Handling & Logging
- Invalid transactional records written to reject tables
- Event parsing failures excluded from analytics views
- Pipeline execution metadata captured in a run-log table (start time, end time, status, row counts)

### Idempotency
- MERGE-based loads for fact tables
- Watermark-driven incremental ingestion for both transactional and event data
- Safe re-runs without data duplication

---

## 8. How to Run / Simulate the Pipeline

1. Clone the repository
2. Load sample input files from `/data`
3. Execute SQL scripts in the following order:

   1. `sql/01_raw_load.sql`
   2. `sql/02_data_quality_and_cleaning.sql`
   3. `sql/03_deduplication.sql`
   4. `sql/04_dimensions.sql`
   5. `sql/05_fact_orders.sql`
   6. `sql/06_incremental_merge.sql`

4. Review outputs under `/data/output`
   - `fact_orders.csv`
   - `rejected_orders.csv`

No cloud account is required; the pipeline can be fully simulated locally using any SQL-compatible database.

---

## 9. Assumptions & Limitations

### Assumptions
- Source data contains reliable timestamps
- Single-region deployment
- Batch-based processing

### Limitations
- No real-time streaming
- Mocked cloud services
- Security and IAM not implemented

---

## 10. How This Would Scale in Production

If this pipeline were deployed in production:
- ADF would orchestrate scheduled and event-based triggers
- Raw JSON would land in cloud object storage (ADLS / S3)
- Transformations could move to Spark SQL for large volumes
- Metadata tables would track pipeline runs and SLAs
- BI tools (Power BI / Tableau) would query the Gold layer


