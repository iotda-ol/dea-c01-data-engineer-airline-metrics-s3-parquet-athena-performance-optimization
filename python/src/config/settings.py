"""
Configuration Module
Centralized configuration management for the data pipeline
"""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class AWSConfig:
    """AWS-specific configuration"""
    region: str
    account_id: str


@dataclass
class S3Config:
    """S3 bucket configuration"""
    raw_bucket: str
    processed_bucket: str
    results_bucket: str


@dataclass
class GlueConfig:
    """AWS Glue configuration"""
    database_name: str
    table_name: str
    job_name: str


@dataclass
class AppConfig:
    """Application configuration"""
    aws: AWSConfig
    s3: S3Config
    glue: GlueConfig
    environment: str


def load_config() -> AppConfig:
    """
    Load configuration from environment variables
    
    Returns:
        AppConfig: Application configuration object
    """
    return AppConfig(
        aws=AWSConfig(
            region=os.getenv('AWS_REGION', 'us-east-1'),
            account_id=os.getenv('AWS_ACCOUNT_ID', '')
        ),
        s3=S3Config(
            raw_bucket=os.getenv('RAW_BUCKET', ''),
            processed_bucket=os.getenv('PROCESSED_BUCKET', ''),
            results_bucket=os.getenv('RESULTS_BUCKET', '')
        ),
        glue=GlueConfig(
            database_name=os.getenv('GLUE_DATABASE', 'airline_metrics'),
            table_name=os.getenv('GLUE_TABLE', 'flights'),
            job_name=os.getenv('GLUE_JOB_NAME', '')
        ),
        environment=os.getenv('ENVIRONMENT', 'dev')
    )


def get_config() -> AppConfig:
    """Get application configuration (convenience function)"""
    return load_config()
