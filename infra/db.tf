#Adding DNS and endpoints add secure ways to access s3 buckets
#Process DB migration through CircleCI, deploy infrastructure
#then run db update scripts
resource "aws_rds_cluster" "db_cluster" {
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 7
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  engine_version          = "10.7"
  skip_final_snapshot     = true
  cluster_identifier      = "${var.name}-${var.env}-db-cluster"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_http_sg.id]
  scaling_configuration {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 2
    seconds_until_auto_pause = 300
  }
}

#Do not deploy database in public space as that is where all 
#information is and is bad if 3rd party broke in and access it
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "postgresql-subnet-group"
  description = "Database Subnet Group"
  subnet_ids  = [aws_subnet.data_az1.id, aws_subnet.data_az2.id, aws_subnet.data_az3.id]
  tags = { #tag is added so that easily can find it in console later
    Name = "postgresql-subnet-group"
  }
}

