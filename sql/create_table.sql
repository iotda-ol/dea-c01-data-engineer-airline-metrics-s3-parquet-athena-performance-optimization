-- ========================================================================
-- Athena DDL for Airline Metrics Table
-- ========================================================================
-- This script creates an external table in Athena pointing to the Parquet
-- data in S3. The table is partitioned by year, month, and day for optimal
-- query performance using predicate pushdown.
--
-- Replace <PROCESSED_BUCKET_NAME> with your actual S3 bucket name
-- Replace <DATABASE_NAME> with your Glue database name
-- ========================================================================

CREATE EXTERNAL TABLE IF NOT EXISTS airline_metrics (
    -- Flight Identification
    flight_id STRING COMMENT 'Unique identifier for the flight',
    airline_code STRING COMMENT 'IATA airline code',
    airline_name STRING COMMENT 'Full airline name',
    flight_number STRING COMMENT 'Flight number',
    tail_number STRING COMMENT 'Aircraft tail number',
    
    -- Flight Schedule
    flight_date STRING COMMENT 'Flight date in YYYY-MM-DD format',
    scheduled_departure_time STRING COMMENT 'Scheduled departure time',
    actual_departure_time STRING COMMENT 'Actual departure time',
    scheduled_arrival_time STRING COMMENT 'Scheduled arrival time',
    actual_arrival_time STRING COMMENT 'Actual arrival time',
    
    -- Airports
    origin_airport_code STRING COMMENT 'Origin airport IATA code',
    origin_airport_name STRING COMMENT 'Origin airport name',
    origin_city STRING COMMENT 'Origin city',
    origin_state STRING COMMENT 'Origin state',
    destination_airport_code STRING COMMENT 'Destination airport IATA code',
    destination_airport_name STRING COMMENT 'Destination airport name',
    destination_city STRING COMMENT 'Destination city',
    destination_state STRING COMMENT 'Destination state',
    
    -- Flight Metrics
    departure_delay_minutes INT COMMENT 'Departure delay in minutes',
    arrival_delay_minutes INT COMMENT 'Arrival delay in minutes',
    flight_duration_minutes INT COMMENT 'Total flight duration in minutes',
    distance_miles INT COMMENT 'Flight distance in miles',
    taxi_out_minutes INT COMMENT 'Taxi-out time in minutes',
    taxi_in_minutes INT COMMENT 'Taxi-in time in minutes',
    air_time_minutes INT COMMENT 'Time in air in minutes',
    
    -- Delay Reasons
    carrier_delay_minutes INT COMMENT 'Delay caused by carrier',
    weather_delay_minutes INT COMMENT 'Delay caused by weather',
    nas_delay_minutes INT COMMENT 'Delay caused by National Air System',
    security_delay_minutes INT COMMENT 'Delay caused by security',
    late_aircraft_delay_minutes INT COMMENT 'Delay caused by late aircraft',
    
    -- Operational
    cancelled BOOLEAN COMMENT 'Whether flight was cancelled',
    cancellation_code STRING COMMENT 'Reason code for cancellation',
    diverted BOOLEAN COMMENT 'Whether flight was diverted',
    
    -- Passenger and Cargo
    passengers_count INT COMMENT 'Number of passengers',
    baggage_count INT COMMENT 'Number of baggage items',
    cargo_weight_lbs INT COMMENT 'Cargo weight in pounds',
    
    -- Flight Status
    flight_status STRING COMMENT 'Current flight status'
)
PARTITIONED BY (
    year INT COMMENT 'Year of the flight',
    month INT COMMENT 'Month of the flight (1-12)',
    day INT COMMENT 'Day of the flight (1-31)'
)
STORED AS PARQUET
LOCATION 's3://<PROCESSED_BUCKET_NAME>/airline_metrics/'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'projection.enabled'='true',
    'projection.year.type'='integer',
    'projection.year.range'='2020,2030',
    'projection.year.digits'='4',
    'projection.month.type'='integer',
    'projection.month.range'='1,12',
    'projection.month.digits'='2',
    'projection.day.type'='integer',
    'projection.day.range'='1,31',
    'projection.day.digits'='2',
    'storage.location.template'='s3://<PROCESSED_BUCKET_NAME>/airline_metrics/year=${year}/month=${month}/day=${day}',
    'classification'='parquet',
    'has_encrypted_data'='false'
);

-- ========================================================================
-- Add Partitions (if not using partition projection)
-- ========================================================================
-- If partition projection is not enabled, you need to run MSCK REPAIR TABLE
-- or add partitions manually after loading data

-- MSCK REPAIR TABLE airline_metrics;

-- Or add partitions manually:
-- ALTER TABLE airline_metrics ADD IF NOT EXISTS
-- PARTITION (year=2024, month=1, day=1)
-- LOCATION 's3://<PROCESSED_BUCKET_NAME>/airline_metrics/year=2024/month=1/day=1/';
