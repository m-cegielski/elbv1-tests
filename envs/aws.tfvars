backend_count           = 1
backend_ami_description = "Canonical, Ubuntu, 20.04 LTS, amd64"
backend_ami_owner       = "099720109477"
backend_ami_root_type   = "ebs"
backend_instance_type   = "t2.small"
lb_name                 = "testTF"
lb_internal             = false
cert_dns_name           = "testTF.example.com"
iam_cert                = true
aws_profile             = "elb-tests"
aws_region              = "eu-west-1"
