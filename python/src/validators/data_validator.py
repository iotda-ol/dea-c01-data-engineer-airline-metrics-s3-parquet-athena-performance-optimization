"""
Data Validator Module
Reusable data quality validation functions
"""

from pyspark.sql import DataFrame
from pyspark.sql.functions import col, count, when, isnan, isnull
from typing import Dict, List, Tuple


class DataValidator:
    """Data quality validation utilities"""
    
    @staticmethod
    def check_nulls(df: DataFrame, columns: List[str]) -> Dict[str, int]:
        """
        Check for null values in specified columns
        
        Args:
            df: Spark DataFrame
            columns: List of column names to check
            
        Returns:
            Dictionary with column names and null counts
        """
        null_counts = {}
        for column in columns:
            if column in df.columns:
                null_count = df.filter(
                    col(column).isNull() | isnan(col(column))
                ).count()
                null_counts[column] = null_count
        return null_counts
        
    @staticmethod
    def check_duplicates(df: DataFrame, key_columns: List[str]) -> int:
        """
        Check for duplicate rows based on key columns
        
        Args:
            df: Spark DataFrame
            key_columns: List of columns that define uniqueness
            
        Returns:
            Number of duplicate rows
        """
        total_rows = df.count()
        unique_rows = df.dropDuplicates(key_columns).count()
        return total_rows - unique_rows
        
    @staticmethod
    def check_range(df: DataFrame, column: str, min_val: float, max_val: float) -> int:
        """
        Check values outside expected range
        
        Args:
            df: Spark DataFrame
            column: Column name to check
            min_val: Minimum acceptable value
            max_val: Maximum acceptable value
            
        Returns:
            Number of values out of range
        """
        out_of_range = df.filter(
            (col(column) < min_val) | (col(column) > max_val)
        ).count()
        return out_of_range
        
    @staticmethod
    def check_format(df: DataFrame, column: str, pattern: str) -> int:
        """
        Check if column values match expected pattern
        
        Args:
            df: Spark DataFrame
            column: Column name to check
            pattern: Regex pattern
            
        Returns:
            Number of values not matching pattern
        """
        invalid_count = df.filter(
            ~col(column).rlike(pattern)
        ).count()
        return invalid_count
        
    @staticmethod
    def get_data_quality_report(df: DataFrame) -> Dict:
        """
        Generate comprehensive data quality report
        
        Args:
            df: Spark DataFrame
            
        Returns:
            Dictionary with quality metrics
        """
        report = {
            'total_rows': df.count(),
            'total_columns': len(df.columns),
            'columns': df.columns,
            'schema': df.schema.simpleString(),
            'null_counts': {}
        }
        
        # Check nulls for all columns
        for column in df.columns:
            null_count = df.filter(col(column).isNull()).count()
            if null_count > 0:
                report['null_counts'][column] = null_count
                
        return report
        
    @staticmethod
    def validate_schema(df: DataFrame, expected_columns: List[str]) -> Tuple[bool, List[str]]:
        """
        Validate DataFrame has expected columns
        
        Args:
            df: Spark DataFrame
            expected_columns: List of expected column names
            
        Returns:
            Tuple of (is_valid, missing_columns)
        """
        actual_columns = set(df.columns)
        expected_set = set(expected_columns)
        missing = list(expected_set - actual_columns)
        is_valid = len(missing) == 0
        return is_valid, missing
