#provide public URL endpoint accessible via internet browser
output "alb_endpoint" {
  value = aws_lb.app_alb.dns_name
}

//[*] signifies all ec2 instances as it is a count.index there needs to be at least a number
output "instance_public_ip" {
  value = aws_instance.app_ec2[*].public_ip
}

output "db_username" {
  value = aws_rds_cluster.db_cluster.master_username
}

output "db_password" {
  value     = aws_rds_cluster.db_cluster.master_password
  sensitive = true #not printed in plaintext when outputted
}

output "db_name" {
  value = aws_rds_cluster.db_cluster.database_name
}

output "db_port" {
  value = aws_rds_cluster.db_cluster.port
}

output "db_host" {
  value = aws_rds_cluster.db_cluster.endpoint
}




