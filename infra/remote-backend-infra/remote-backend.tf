#Defines cloud provider as AWS
provider "aws" {
  region  = "us-east-1"
}

#store terraform state file in s3 bucket with encryption and locking
resource "aws_s3_bucket" "tf_state_s3" {
  #s3 bucket name is globally unique across all regions and aws accounts
  #creating bucket names must be unique (E.g. concatenating account ID)
  bucket = "tf-state-s3654762-s3bucket"
  versioning { #To see full revision history of state files
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle { #Ensure it can only be deleted via AWS console, once
    #all contents including old versions have been manually deleted
    prevent_destroy = true
  }
  tags = {
    Name = "TF Remote State S3 Bucket"
  }
}

#supports state locking and consistency checking via DynamoDB
#DynamoDB's distributed key-value store supports strongly-consistent reads
#& conditional writes - ingredients needed for a distributed lock system
resource "aws_dynamodb_table" "tf_state_lock_dynamodb" {
  name           = "tf-state-dynamodb-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "TF Remote State DynamoDB Lock"
  }
}

