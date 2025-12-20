"""
S3 Utilities Module
Reusable functions for S3 operations
"""

import boto3
from typing import List, Optional
from botocore.exceptions import ClientError


class S3Utils:
    """Utility class for S3 operations"""
    
    def __init__(self, region: str = 'us-east-1'):
        """
        Initialize S3 client
        
        Args:
            region: AWS region
        """
        self.s3_client = boto3.client('s3', region_name=region)
        self.s3_resource = boto3.resource('s3', region_name=region)
        
    def upload_file(self, file_path: str, bucket: str, key: str) -> bool:
        """
        Upload file to S3
        
        Args:
            file_path: Local file path
            bucket: S3 bucket name
            key: S3 object key
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.upload_file(file_path, bucket, key)
            print(f"✅ Uploaded {file_path} to s3://{bucket}/{key}")
            return True
        except ClientError as e:
            print(f"❌ Error uploading file: {e}")
            return False
            
    def download_file(self, bucket: str, key: str, file_path: str) -> bool:
        """
        Download file from S3
        
        Args:
            bucket: S3 bucket name
            key: S3 object key
            file_path: Local file path to save
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.download_file(bucket, key, file_path)
            print(f"✅ Downloaded s3://{bucket}/{key} to {file_path}")
            return True
        except ClientError as e:
            print(f"❌ Error downloading file: {e}")
            return False
            
    def list_objects(self, bucket: str, prefix: str = '') -> List[str]:
        """
        List objects in S3 bucket with prefix
        
        Args:
            bucket: S3 bucket name
            prefix: Object key prefix
            
        Returns:
            List of object keys
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=bucket,
                Prefix=prefix
            )
            return [obj['Key'] for obj in response.get('Contents', [])]
        except ClientError as e:
            print(f"❌ Error listing objects: {e}")
            return []
            
    def delete_object(self, bucket: str, key: str) -> bool:
        """
        Delete object from S3
        
        Args:
            bucket: S3 bucket name
            key: S3 object key
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.s3_client.delete_object(Bucket=bucket, Key=key)
            print(f"✅ Deleted s3://{bucket}/{key}")
            return True
        except ClientError as e:
            print(f"❌ Error deleting object: {e}")
            return False
            
    def object_exists(self, bucket: str, key: str) -> bool:
        """
        Check if object exists in S3
        
        Args:
            bucket: S3 bucket name
            key: S3 object key
            
        Returns:
            True if exists, False otherwise
        """
        try:
            self.s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except ClientError:
            return False
            
    def get_object_size(self, bucket: str, key: str) -> Optional[int]:
        """
        Get object size in bytes
        
        Args:
            bucket: S3 bucket name
            key: S3 object key
            
        Returns:
            Size in bytes or None if object doesn't exist
        """
        try:
            response = self.s3_client.head_object(Bucket=bucket, Key=key)
            return response['ContentLength']
        except ClientError:
            return None
