"""
CSV to Parquet ETL Module
Modular ETL transformation for converting CSV files to optimized Parquet format
"""

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import year, month, dayofmonth, to_date, col
from typing import List, Optional


class CSVToParquetETL:
    """Convert CSV to Parquet with partitioning and optimization"""
    
    def __init__(self, spark: SparkSession):
        """
        Initialize ETL processor
        
        Args:
            spark: Spark session
        """
        self.spark = spark
        self._configure_spark()
        
    def _configure_spark(self):
        """Configure Spark for optimal Parquet writing"""
        self.spark.conf.set("spark.sql.parquet.compression.codec", "snappy")
        self.spark.conf.set("spark.sql.parquet.filterPushdown", "true")
        self.spark.conf.set("spark.sql.parquet.mergeSchema", "false")
        self.spark.conf.set("spark.sql.files.maxPartitionBytes", "134217728")  # 128 MB
        
    def read_csv(self, path: str, header: bool = True, infer_schema: bool = True) -> DataFrame:
        """
        Read CSV files from S3
        
        Args:
            path: S3 path to CSV files
            header: Whether CSV has header row
            infer_schema: Whether to infer schema automatically
            
        Returns:
            Spark DataFrame
        """
        df = self.spark.read.csv(
            path,
            header=header,
            inferSchema=infer_schema
        )
        print(f"✅ Read {df.count()} rows from {path}")
        return df
        
    def add_partition_columns(
        self, 
        df: DataFrame, 
        date_column: str = 'flight_date',
        date_format: str = 'yyyy-MM-dd'
    ) -> DataFrame:
        """
        Add partition columns (year, month, day) from date column
        
        Args:
            df: Source DataFrame
            date_column: Name of the date column
            date_format: Format of the date string
            
        Returns:
            DataFrame with partition columns added
        """
        df = df.withColumn('flight_date_parsed', to_date(col(date_column), date_format))
        df = df.withColumn('year', year(col('flight_date_parsed')))
        df = df.withColumn('month', month(col('flight_date_parsed')))
        df = df.withColumn('day', dayofmonth(col('flight_date_parsed')))
        df = df.drop('flight_date_parsed')
        
        print(f"✅ Added partition columns: year, month, day")
        return df
        
    def cast_numeric_columns(
        self, 
        df: DataFrame, 
        numeric_columns: List[str],
        data_type: str = 'int'
    ) -> DataFrame:
        """
        Cast numeric columns to appropriate type for better compression
        
        Args:
            df: Source DataFrame
            numeric_columns: List of column names to cast
            data_type: Target data type ('int', 'double', 'float')
            
        Returns:
            DataFrame with casted columns
        """
        for col_name in numeric_columns:
            if col_name in df.columns:
                df = df.withColumn(col_name, col(col_name).cast(data_type))
                
        print(f"✅ Casted {len(numeric_columns)} columns to {data_type}")
        return df
        
    def write_parquet(
        self,
        df: DataFrame,
        path: str,
        partition_cols: Optional[List[str]] = None,
        mode: str = 'overwrite'
    ):
        """
        Write DataFrame to Parquet format
        
        Args:
            df: DataFrame to write
            path: S3 path for output
            partition_cols: List of partition column names
            mode: Write mode ('overwrite', 'append')
        """
        writer = df.write.mode(mode).option('compression', 'snappy')
        
        if partition_cols:
            writer = writer.partitionBy(*partition_cols)
            print(f"✅ Partitioning by: {', '.join(partition_cols)}")
            
        writer.parquet(path)
        print(f"✅ Written Parquet files to {path}")
        
    def process(
        self,
        source_path: str,
        target_path: str,
        numeric_columns: Optional[List[str]] = None
    ):
        """
        Complete ETL process: CSV to Parquet with partitioning
        
        Args:
            source_path: S3 path to source CSV files
            target_path: S3 path for output Parquet files
            numeric_columns: List of numeric column names to optimize
        """
        print(f"🚀 Starting ETL: {source_path} → {target_path}")
        
        # Read CSV
        df = self.read_csv(source_path)
        
        # Add partition columns
        df = self.add_partition_columns(df)
        
        # Cast numeric columns if specified
        if numeric_columns:
            df = self.cast_numeric_columns(df, numeric_columns)
        else:
            # Default numeric columns for airline data
            default_numeric_cols = [
                'departure_delay_minutes',
                'arrival_delay_minutes',
                'flight_duration_minutes',
                'distance_miles',
                'passengers_count',
                'baggage_count'
            ]
            df = self.cast_numeric_columns(df, default_numeric_cols)
        
        # Write Parquet
        self.write_parquet(df, target_path, partition_cols=['year', 'month', 'day'])
        
        print(f"✅ ETL process completed successfully!")
