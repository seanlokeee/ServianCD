#Load balancer should not be allowed ssh connection
resource "aws_security_group" "alb_http_sg" {
  name        = "${var.name}-${var.env}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "HTTP From Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
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

#To see app must setup security group because aws by default 
#denies all access unless u specifically said u can have access
resource "aws_security_group" "ec2_http_ssh_sg" {
  name        = "${var.name}-${var.env}-ec2-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "SSH From Internet"
    from_port   = 22
    to_port     = 22
    #type traffic allowed, other types are not allowed access
    protocol = "TCP"
    #if don't do this, have to go to instance itself
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP From Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
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
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id
  ingress {
    description = "HTTP From Internet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-${var.env}-db-sg"
  }
}

