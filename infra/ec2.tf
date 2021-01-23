#upload own key pair instead of manually downloading it in UI
#, enabling ssh connection
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key"
  public_key = var.public_key
}

#Prebuilt images that installs operating system onto virtual
#machine
data "aws_ami" "amazon_linux_2" {
  most_recent = true #if >1 result is returned, use most recent AMI
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"] # * means all amzn2-ami-hvm 
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#AWS calls EC2 instance a virtual machine to host application 
#running on linux or windows servers
resource "aws_instance" "app_ec2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  key_name                    = aws_key_pair.ssh_key.key_name
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.ec2_http_ssh_sg.id]
  subnet_id                   = aws_subnet.private_az1.id
  associate_public_ip_address = true
  depends_on                  = [aws_internet_gateway.app_igw]
  count                       = var.instance_count
  tags = { #tag is added so that easily can find it in console later
    Name = "${var.name}-${var.env}-ec2-instance"
  }
}