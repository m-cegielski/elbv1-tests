backend_count           = 1
backend_ami_description = "Ubuntu 20.04"
backend_ami_owner       = "000000000002"
backend_ami_root_type   = "instance-store"
backend_instance_type   = "g2.small"
lb_name                 = "testTF"
lb_internal             = false
cert_dns_name           = "testTF.example.com"
aws_profile             = "spc-dev2"
aws_region              = "eu-central-1"
aws_endpoint            = "https://apigw-dev2.eu-central-1.samsungspc.com"