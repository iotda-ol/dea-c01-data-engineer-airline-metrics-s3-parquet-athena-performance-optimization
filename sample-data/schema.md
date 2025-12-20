# Airline Metrics CSV Schema

## Overview
This document describes the schema for the airline metrics CSV files that will be ingested into the data lake.

## CSV File Format

### File Naming Convention
```
airline_metrics_YYYY-MM-DD.csv
```

Example: `airline_metrics_2024-01-15.csv`

### CSV Structure
- **Delimiter**: Comma (`,`)
- **Quote Character**: Double quote (`"`)
- **Header Row**: Yes (first row contains column names)
- **Encoding**: UTF-8
- **Line Endings**: LF (Unix style) or CRLF (Windows style)

## Column Definitions

| Column Name | Data Type | Required | Description | Example |
|------------|-----------|----------|-------------|---------|
| flight_id | STRING | Yes | Unique identifier for the flight | FL20240115001 |
| airline_code | STRING | Yes | IATA airline code | AA, DL, UA, WN |
| airline_name | STRING | Yes | Full airline name | American Airlines |
| flight_number | STRING | Yes | Flight number | 1234 |
| tail_number | STRING | No | Aircraft tail number | N12345 |
| flight_date | STRING | Yes | Flight date (YYYY-MM-DD) | 2024-01-15 |
| scheduled_departure_time | STRING | Yes | Scheduled departure time (HH:MM) | 08:30 |
| actual_departure_time | STRING | No | Actual departure time (HH:MM) | 08:45 |
| scheduled_arrival_time | STRING | Yes | Scheduled arrival time (HH:MM) | 12:00 |
| actual_arrival_time | STRING | No | Actual arrival time (HH:MM) | 12:15 |
| origin_airport_code | STRING | Yes | Origin airport IATA code | JFK, LAX, ORD |
| origin_airport_name | STRING | Yes | Origin airport name | John F. Kennedy International Airport |
| origin_city | STRING | Yes | Origin city | New York |
| origin_state | STRING | Yes | Origin state (2-letter code) | NY |
| destination_airport_code | STRING | Yes | Destination airport IATA code | LAX, ORD, MIA |
| destination_airport_name | STRING | Yes | Destination airport name | Los Angeles International Airport |
| destination_city | STRING | Yes | Destination city | Los Angeles |
| destination_state | STRING | Yes | Destination state (2-letter code) | CA |
| departure_delay_minutes | INTEGER | No | Departure delay in minutes (negative = early) | 15 |
| arrival_delay_minutes | INTEGER | No | Arrival delay in minutes (negative = early) | 10 |
| flight_duration_minutes | INTEGER | No | Total flight duration in minutes | 330 |
| distance_miles | INTEGER | Yes | Flight distance in miles | 2475 |
| taxi_out_minutes | INTEGER | No | Taxi-out time in minutes | 12 |
| taxi_in_minutes | INTEGER | No | Taxi-in time in minutes | 8 |
| air_time_minutes | INTEGER | No | Time in air in minutes | 310 |
| carrier_delay_minutes | INTEGER | No | Delay caused by carrier | 0 |
| weather_delay_minutes | INTEGER | No | Delay caused by weather | 0 |
| nas_delay_minutes | INTEGER | No | Delay caused by National Air System | 0 |
| security_delay_minutes | INTEGER | No | Delay caused by security | 0 |
| late_aircraft_delay_minutes | INTEGER | No | Delay caused by late aircraft | 15 |
| cancelled | BOOLEAN | Yes | Whether flight was cancelled (true/false) | false |
| cancellation_code | STRING | No | Reason code for cancellation (A/B/C/D) | A |
| diverted | BOOLEAN | Yes | Whether flight was diverted (true/false) | false |
| passengers_count | INTEGER | No | Number of passengers | 145 |
| baggage_count | INTEGER | No | Number of baggage items | 178 |
| cargo_weight_lbs | INTEGER | No | Cargo weight in pounds | 2500 |
| flight_status | STRING | Yes | Current flight status | COMPLETED, CANCELLED, DELAYED |

## Cancellation Codes
- **A**: Carrier
- **B**: Weather
- **C**: National Air System (NAS)
- **D**: Security

## Flight Status Values
- **SCHEDULED**: Flight is scheduled
- **BOARDING**: Boarding in progress
- **DEPARTED**: Flight has departed
- **IN_AIR**: Flight is in the air
- **LANDED**: Flight has landed
- **COMPLETED**: Flight completed normally
- **CANCELLED**: Flight was cancelled
- **DELAYED**: Flight is delayed
- **DIVERTED**: Flight was diverted

## Sample CSV Row

```csv
flight_id,airline_code,airline_name,flight_number,tail_number,flight_date,scheduled_departure_time,actual_departure_time,scheduled_arrival_time,actual_arrival_time,origin_airport_code,origin_airport_name,origin_city,origin_state,destination_airport_code,destination_airport_name,destination_city,destination_state,departure_delay_minutes,arrival_delay_minutes,flight_duration_minutes,distance_miles,taxi_out_minutes,taxi_in_minutes,air_time_minutes,carrier_delay_minutes,weather_delay_minutes,nas_delay_minutes,security_delay_minutes,late_aircraft_delay_minutes,cancelled,cancellation_code,diverted,passengers_count,baggage_count,cargo_weight_lbs,flight_status
FL20240115001,AA,American Airlines,1234,N12345,2024-01-15,08:30,08:45,12:00,12:15,JFK,John F. Kennedy International Airport,New York,NY,LAX,Los Angeles International Airport,Los Angeles,CA,15,15,330,2475,12,8,310,0,0,0,0,15,false,,false,145,178,2500,COMPLETED
```

## Data Quality Rules

1. **Required Fields**: Must not be empty or NULL
2. **Date Format**: Must follow YYYY-MM-DD format
3. **Time Format**: Must follow HH:MM format (24-hour)
4. **Numeric Values**: Must be valid integers (no decimals)
5. **Boolean Values**: Must be "true" or "false" (lowercase)
6. **Airport Codes**: Must be valid 3-letter IATA codes
7. **State Codes**: Must be valid 2-letter US state codes
8. **Delay Values**: Can be negative (indicates early arrival/departure)

## S3 Upload Structure

Upload CSV files to S3 in the following structure for date partitioning:

```
s3://bucket-name/airline_metrics/YYYY-MM-DD/
  ├── airline_metrics_2024-01-15.csv
  ├── airline_metrics_2024-01-16.csv
  └── ...
```

This structure allows the Glue ETL job to:
1. Discover files organized by date
2. Extract partition information from the path
3. Process files incrementally using job bookmarks

## Performance Considerations

- **File Size**: Optimal file size is 100MB - 1GB compressed
- **Compression**: Use gzip compression for CSV files in S3
- **Partitioning**: Daily partitions provide good balance between granularity and performance
- **Data Volume**: Expected 10,000 - 100,000 flights per day
- **File Count**: One file per day recommended for simplicity
