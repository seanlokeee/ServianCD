#Load balancer for this server so that IP continuously changes
#so that can connect to servers when they are scaled up and down
#without knowing exact IP of the server
resource "aws_lb" "app_alb" {
  name = "${var.name}-${var.env}-alb"
  #internet facing, public facing application
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_http_sg.id]
  #In case, an az dies the load balancer can live in another one
  subnets = [aws_subnet.public_az1.id, aws_subnet.public_az2.id, aws_subnet.public_az3.id]
  tags = { #tag is added so that easily can find it in console later
    Name = "${var.name}-${var.env}-alb"
  }
}

#Created to define which virtual machines (instances that exist
#in the cluster) can receive traffic/requests from load balancers
#LB forwards traffic to target groups based on predefined rules
resource "aws_lb_target_group" "app_tg" {
  name = "${var.name}-${var.env}-tg"
  #LB forwards all HTTP traffic on port 80 to one specific target group
  port     = 80 #only rule defined for this lb
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  tags = {
    Name = "${var.name}-${var.env}-tg"
  }
}

#Target group attached to EC2 instance, passing on traffic to port 80
resource "aws_alb_target_group_attachment" "ec2_tg" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_ec2[count.index].id
  port             = 80
}

#Used to define routing, and ties the port and protocol to the 
#instances in the target group from the load balancer
resource "aws_lb_listener" "app_alb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}