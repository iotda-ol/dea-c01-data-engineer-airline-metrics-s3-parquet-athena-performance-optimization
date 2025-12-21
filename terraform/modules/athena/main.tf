/**
 * Athena Module
 * Creates Amazon Athena workgroup configuration
 */

resource "aws_athena_workgroup" "this" {
  name        = "${var.project_name}-workgroup-${var.environment}"
  description = "Workgroup for ${var.project_name} ${var.environment} queries"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.results_bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = var.tags
}

# Sample named queries
resource "aws_athena_named_query" "flight_count" {
  name        = "total_flight_count"
  workgroup   = aws_athena_workgroup.this.name
  database    = var.database_name
  description = "Count total flights in the database"

  query = <<-EOT
    SELECT COUNT(*) as total_flights
    FROM ${var.table_name};
  EOT
}

resource "aws_athena_named_query" "top_delayed_flights" {
  name        = "top_delayed_flights"
  workgroup   = aws_athena_workgroup.this.name
  database    = var.database_name
  description = "Top 10 most delayed flights"

  query = <<-EOT
    SELECT 
      flight_date,
      airline,
      flight_number,
      origin,
      destination,
      arrival_delay_minutes
    FROM ${var.table_name}
    WHERE year = 2024
      AND arrival_delay_minutes > 0
    ORDER BY arrival_delay_minutes DESC
    LIMIT 10;
  EOT
}

resource "aws_athena_named_query" "airline_performance" {
  name        = "airline_performance_summary"
  workgroup   = aws_athena_workgroup.this.name
  database    = var.database_name
  description = "Airline performance summary with average delays"

  query = <<-EOT
    SELECT 
      airline,
      COUNT(*) as total_flights,
      AVG(arrival_delay_minutes) as avg_arrival_delay,
      AVG(departure_delay_minutes) as avg_departure_delay,
      SUM(passengers_count) as total_passengers
    FROM ${var.table_name}
    WHERE year = 2024
    GROUP BY airline
    ORDER BY total_flights DESC;
  EOT
}
