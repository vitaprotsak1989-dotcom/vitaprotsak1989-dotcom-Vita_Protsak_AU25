-- =====================================================
-- Task 2 — PostgreSQL table_to_delete Investigation
-- =====================================================

-- =========================
-- Step 1: Create the table
-- =========================
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

-- Initial state:
-- Rows: 10,000,000
-- Execution time: 30s
-- Table size: 575 M

-- =======================================
-- Step 2: Check table size before DELETE
-- =======================================
SELECT *, 
       pg_size_pretty(total_bytes) AS total,
       pg_size_pretty(index_bytes) AS index,
       pg_size_pretty(toast_bytes) AS toast,
       pg_size_pretty(table_bytes) AS table
FROM ( 
    SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
    FROM (
        SELECT c.oid,
               nspname AS table_schema,
               relname AS table_name,
               c.reltuples AS row_estimate,
               pg_total_relation_size(c.oid) AS total_bytes,
               pg_indexes_size(c.oid) AS index_bytes,
               pg_total_relation_size(reltoastrelid) AS toast_bytes
        FROM pg_class c
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE relkind = 'r'
    ) a
) a
WHERE table_name LIKE '%table_to_delete%';

-- =========================
-- Step 3: DELETE 1/3 of rows
-- =========================

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

-- Conclusions:
-- Rows remaining: 6,666,667
-- Execution time: 22s
-- Table size: ~575 MB
-- Note: DELETE does not physically reduce the table size on disk.

-- =========================
-- Step 4: VACUUM FULL
-- =========================

VACUUM FULL VERBOSE table_to_delete;

-- Conclusions VACUUM FULL:
-- Rows: 6,666,667
-- Execution time: 12s
-- Table size: physically reduced
-- Note: VACUUM FULL frees up disk space after DELETE.

-- =========================
-- Step 5: TRUNCATE table
-- =========================

TRUNCATE table_to_delete;

-- Conclusions TRUNCATE:
-- Rows: 0
-- Execution time: 1s
-- Table size: minimal
-- Note: TRUNCATE removes all rows instantly and frees disk space.

-- =========================
-- Step 6: Summary Table
-- =========================

-- Operation      | Rows       | Execution Time | Table Size
-- ---------------------------------------------------------
-- Initial state  | 10,000,000 | 30 s           | 575 MB
-- DELETE 1/3     | 6,666,667  | 22 s           | 575 MB
-- VACUUM FULL    | 6,666,667  | 12 s           | significantly smaller
-- TRUNCATE       | 0          | 1 s            | minimal

-- =========================
-- Step 7: Conclusions
-- =========================
-- 1. DELETE removes rows logically but does NOT reduce physical table size.
-- 2. VACUUM FULL actually frees up disk space after DELETE.
-- 3. TRUNCATE removes all rows very quickly and frees space immediately.
-- 4. For massive table cleanups, TRUNCATE is more efficient than DELETE.