output "elb_dns_name" {
  value       = aws_elb.clb.dns_name
  description = "load balancer DNS name"
}

output "ec2_private_ip" {
  value = aws_instance.backend.0.private_ip
}
