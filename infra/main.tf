provider "aws" {
  version = "~>2.23"
  region  = "us-east-1"
}

#configure terraform to store state in s3 bucket with encryption and locking
terraform {      #enable remote backend terraform state file storage
  backend "s3" { #configures remote backend to utilise S3 and DynamoDB
    encrypt        = true
    key            = "maininfra-tfremotestatefile"
    bucket         = "tf-state-s3654762-s3bucket"
    region         = "us-east-1"
    dynamodb_table = "tf-state-dynamodb-lock"
  }
}