-- ========================================================================
-- Sample Athena Queries for Airline Metrics Analytics
-- ========================================================================
-- These queries demonstrate DEA-C01 best practices including:
-- - Column pruning (selecting only needed columns)
-- - Predicate pushdown (filtering at the data source)
-- - Partition filtering (leveraging year/month/day partitions)
-- ========================================================================

-- ========================================================================
-- Query 1: Column Pruning - Select Only Required Columns
-- ========================================================================
-- Best Practice: Only select columns you need to reduce data scanned
-- This query scans significantly less data than SELECT *

SELECT 
    flight_date,
    airline_name,
    flight_number,
    origin_airport_code,
    destination_airport_code,
    departure_delay_minutes
FROM airline_metrics
WHERE year = 2024 AND month = 1
LIMIT 100;

-- Data Scanned: ~10-20 MB (depending on data volume)
-- vs SELECT * would scan 100+ MB


-- ========================================================================
-- Query 2: Predicate Pushdown - Date Range with Partition Filtering
-- ========================================================================
-- Best Practice: Use partition columns in WHERE clause for efficient filtering
-- This leverages Parquet metadata to skip entire partitions

SELECT 
    flight_date,
    airline_code,
    origin_airport_code,
    destination_airport_code,
    AVG(departure_delay_minutes) AS avg_departure_delay,
    AVG(arrival_delay_minutes) AS avg_arrival_delay,
    COUNT(*) AS total_flights
FROM airline_metrics
WHERE year = 2024 
    AND month = 1 
    AND day BETWEEN 1 AND 7
    AND cancelled = false
GROUP BY 
    flight_date,
    airline_code,
    origin_airport_code,
    destination_airport_code
ORDER BY avg_departure_delay DESC
LIMIT 50;

-- Performance: Scans only 7 days of data instead of entire dataset
-- Cost Savings: 95%+ reduction in data scanned for monthly datasets


-- ========================================================================
-- Query 3: Column Pruning + Predicate Pushdown - Delayed Flights Analysis
-- ========================================================================
-- Best Practice: Combine column selection with partition and value filtering

SELECT 
    airline_name,
    COUNT(*) AS delayed_flights,
    AVG(departure_delay_minutes) AS avg_delay,
    MAX(departure_delay_minutes) AS max_delay
FROM airline_metrics
WHERE year = 2024
    AND month = 1
    AND departure_delay_minutes > 15
    AND cancelled = false
GROUP BY airline_name
ORDER BY delayed_flights DESC;

-- Optimizations Applied:
-- 1. Partition pruning (only January 2024)
-- 2. Predicate pushdown (delay > 15 and cancelled = false)
-- 3. Column pruning (only 4 columns selected)


-- ========================================================================
-- Query 4: Route Performance Analysis with Partition Filtering
-- ========================================================================
-- Best Practice: Use partition columns for time-based analytics

SELECT 
    origin_airport_code || '-' || destination_airport_code AS route,
    COUNT(*) AS total_flights,
    AVG(departure_delay_minutes) AS avg_departure_delay,
    AVG(arrival_delay_minutes) AS avg_arrival_delay,
    AVG(flight_duration_minutes) AS avg_duration,
    SUM(CASE WHEN cancelled THEN 1 ELSE 0 END) AS cancelled_flights,
    ROUND(100.0 * SUM(CASE WHEN cancelled THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate
FROM airline_metrics
WHERE year = 2024
    AND month BETWEEN 1 AND 3  -- Q1 2024
    AND distance_miles > 500   -- Only medium/long-haul flights
GROUP BY origin_airport_code, destination_airport_code
HAVING COUNT(*) >= 10  -- Routes with at least 10 flights
ORDER BY cancellation_rate DESC
LIMIT 25;

-- Performance: Multi-month query with efficient partition pruning
-- Predicate pushdown on distance_miles filters at Parquet level


-- ========================================================================
-- Query 5: Delay Attribution Analysis
-- ========================================================================
-- Best Practice: Select specific columns for aggregation

SELECT 
    airline_name,
    year,
    month,
    SUM(carrier_delay_minutes) AS total_carrier_delay,
    SUM(weather_delay_minutes) AS total_weather_delay,
    SUM(nas_delay_minutes) AS total_nas_delay,
    SUM(security_delay_minutes) AS total_security_delay,
    SUM(late_aircraft_delay_minutes) AS total_late_aircraft_delay,
    COUNT(*) AS total_flights
FROM airline_metrics
WHERE year = 2024
    AND month IN (1, 2, 3)
    AND (carrier_delay_minutes > 0 
         OR weather_delay_minutes > 0 
         OR nas_delay_minutes > 0 
         OR security_delay_minutes > 0 
         OR late_aircraft_delay_minutes > 0)
GROUP BY airline_name, year, month
ORDER BY total_carrier_delay DESC;

-- Optimizations:
-- 1. Partition filtering (Q1 2024)
-- 2. Column-specific selection reduces I/O
-- 3. Predicate pushdown on delay columns


-- ========================================================================
-- Query 6: Top Airports by Passenger Traffic
-- ========================================================================
-- Best Practice: Time-partitioned aggregation with minimal columns

SELECT 
    origin_airport_code,
    origin_city,
    origin_state,
    SUM(passengers_count) AS total_passengers,
    COUNT(DISTINCT airline_code) AS airlines_serving,
    COUNT(*) AS total_flights,
    AVG(departure_delay_minutes) AS avg_delay
FROM airline_metrics
WHERE year = 2024
    AND month = 1
    AND cancelled = false
GROUP BY origin_airport_code, origin_city, origin_state
ORDER BY total_passengers DESC
LIMIT 20;

-- Data Scanned: Only January 2024 partition
-- Efficiency: 12x faster than scanning entire year


-- ========================================================================
-- Query 7: Daily Flight Statistics with Partition Projection
-- ========================================================================
-- Best Practice: Leverage partition projection for date ranges

SELECT 
    year,
    month,
    day,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN cancelled THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN diverted THEN 1 ELSE 0 END) AS diverted,
    AVG(departure_delay_minutes) AS avg_departure_delay,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY departure_delay_minutes) AS median_departure_delay
FROM airline_metrics
WHERE year = 2024
    AND month = 1
    AND day BETWEEN 15 AND 21
GROUP BY year, month, day
ORDER BY year, month, day;

-- Performance: Partition projection eliminates catalog overhead
-- Scans only 7 days of data


-- ========================================================================
-- Query 8: Weather Impact Analysis (Specific Date Range)
-- ========================================================================
-- Best Practice: Precise partition filtering for targeted analysis

SELECT 
    flight_date,
    origin_state,
    COUNT(*) AS total_flights,
    SUM(CASE WHEN weather_delay_minutes > 0 THEN 1 ELSE 0 END) AS weather_affected_flights,
    SUM(weather_delay_minutes) AS total_weather_delay,
    AVG(weather_delay_minutes) AS avg_weather_delay,
    MAX(weather_delay_minutes) AS max_weather_delay
FROM airline_metrics
WHERE year = 2024
    AND month = 1
    AND day BETWEEN 20 AND 25
    AND weather_delay_minutes > 0
GROUP BY flight_date, origin_state
ORDER BY total_weather_delay DESC;

-- Optimizations:
-- 1. Exact partition pruning (6 days only)
-- 2. Predicate pushdown on weather_delay_minutes
-- 3. Column-specific selection


-- ========================================================================
-- Query 9: Cost-Optimized Performance Comparison
-- ========================================================================
-- Example of inefficient vs. efficient query

-- INEFFICIENT (DO NOT USE):
-- SELECT * FROM airline_metrics WHERE flight_date = '2024-01-15';
-- Problem: Scans all columns, no partition filtering

-- EFFICIENT (USE THIS):
SELECT 
    flight_id,
    airline_name,
    flight_number,
    departure_delay_minutes,
    arrival_delay_minutes
FROM airline_metrics
WHERE year = 2024 
    AND month = 1 
    AND day = 15
    AND cancelled = false;

-- Savings: 90%+ reduction in data scanned and query cost


-- ========================================================================
-- Query 10: Complex Analytics with Optimal Filtering
-- ========================================================================
-- Best Practice: Combine all optimization techniques

WITH daily_stats AS (
    SELECT 
        year,
        month,
        day,
        airline_code,
        COUNT(*) AS flights,
        AVG(departure_delay_minutes) AS avg_delay,
        SUM(passengers_count) AS passengers
    FROM airline_metrics
    WHERE year = 2024
        AND month IN (1, 2)
        AND cancelled = false
    GROUP BY year, month, day, airline_code
)
SELECT 
    airline_code,
    SUM(flights) AS total_flights,
    ROUND(AVG(avg_delay), 2) AS overall_avg_delay,
    SUM(passengers) AS total_passengers,
    ROUND(SUM(passengers) * 1.0 / SUM(flights), 0) AS avg_passengers_per_flight
FROM daily_stats
GROUP BY airline_code
ORDER BY total_flights DESC
LIMIT 15;

-- Optimizations Applied:
-- 1. Partition pruning (2 months)
-- 2. Column selection (7 columns)
-- 3. Predicate pushdown (cancelled filter)
-- 4. CTE for query organization
-- Data Scanned: ~5-10% of full dataset


-- ========================================================================
-- Performance Monitoring Query
-- ========================================================================
-- Use this to check query performance and costs

SELECT 
    query_id,
    query,
    state,
    data_scanned_in_bytes / 1024 / 1024 AS data_scanned_mb,
    execution_time_millis / 1000.0 AS execution_time_seconds,
    query_queue_time_millis / 1000.0 AS queue_time_seconds,
    total_execution_time_millis / 1000.0 AS total_time_seconds
FROM athena_query_execution_history
WHERE submission_date_time >= CURRENT_DATE - INTERVAL '7' DAY
ORDER BY data_scanned_in_bytes DESC
LIMIT 20;

-- Note: This requires Athena query history to be enabled
