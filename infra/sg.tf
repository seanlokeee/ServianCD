#To see app must setup security group because aws by default 
#denies all access unless specifically stated items can have access

#Load balancer should not be allowed ssh connection
resource "aws_security_group" "alb_http_sg" {
  name        = "${var.name}-${var.env}-alb-sg"
  description = "Allow HTTP Inbound Traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "HTTP From Internet"
    from_port   = 80 #All request on other ports will be denied access
    to_port     = 80
    protocol    = "TCP" #Other traffic types not allowed access
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { #tag is added so that easily can find it in console later
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

resource "aws_security_group" "ec2_http_ssh_sg" {
  name        = "${var.name}-${var.env}-ec2-sg"
  description = "Allow SSH And ALB SG HTTP Inbound Traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "SSH From Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress { #ensures app is not accessible via HTTP through public IP address
    #or via any VPC service that doesn't have required SG attached
    description     = "HTTP From ALB Security Group" #only ALB SG HTTP traffic
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups = [aws_security_group.alb_http_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-${var.env}-ec2-sg"
  }
}

resource "aws_security_group" "db_http_sg" {
  name        = "${var.name}-${var.env}-db-sg"
  description = "Allow Postgres EC2 SG Inbound Traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress { #allow specified traffic from a service with required SG attached
    ##ensures that only the ec2 instance that requires the database can access it
    description     = "Postgres From EC2 Security Group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.ec2_http_ssh_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  tags = {
    Name = "${var.name}-${var.env}-db-sg"
  }
}

