data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "default-for-az"
    values = [true]
  }
}

resource "aws_security_group" "backend" {
  vpc_id = data.aws_vpc.vpc.id
  name   = format("%s-backend-%s", var.lb_name, var.id)
  tags   = { "Name" : format("%s-backend-%s", var.lb_name, var.id) }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ssh" {
  count = var.configure_ssh ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}


resource "aws_security_group" "sg" {
  vpc_id = data.aws_vpc.vpc.id
  name   = format("%s-%s", var.lb_name, var.id)
  tags   = { "Name" : format("%s-%s", var.lb_name, var.id) }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ami" {
  filter {
    name   = "description"
    values = ["${var.backend_ami_description}*"]
  }

  filter {
    name   = "root-device-type"
    values = [var.backend_ami_root_type]
  }

  owners      = [var.backend_ami_owner]
  most_recent = true
}

resource "aws_acm_certificate" "cert" {
  count = var.iam_cert || var.pre_provisioned_cert ? 0 : 1

  domain_name       = var.cert_dns_name
  validation_method = "DNS"
}

data "aws_acm_certificate" "cert" {
  count = var.pre_provisioned_cert ? 1 : 0

  domain = var.cert_dns_name
}

resource "aws_elb" "clb" {
  name                      = format("%s-%s", var.lb_name, var.id)
  internal                  = var.lb_internal
  subnets                   = data.aws_subnets.subnets.ids
  cross_zone_load_balancing = true

  security_groups = [
    aws_security_group.sg.id,
  ]

  listener {
    lb_protocol        = "https"
    lb_port            = 443
    instance_protocol  = "http"
    instance_port      = 80
    ssl_certificate_id = var.iam_cert ? aws_iam_server_certificate.this.0.arn : try(aws_acm_certificate.cert.0.arn, data.aws_acm_certificate.cert.0.arn)
  }

  listener {
    lb_protocol       = "http"
    lb_port           = 80
    instance_protocol = "http"
    instance_port     = 80
  }

  listener {
    lb_protocol       = "tcp"
    lb_port           = 8080
    instance_protocol = "tcp"
    instance_port     = 80
  }
}

resource "aws_instance" "backend" {
  count = var.backend_count

  ami                         = data.aws_ami.ami.id
  instance_type               = var.backend_instance_type
  subnet_id                   = data.aws_subnets.subnets.ids[count.index % length(data.aws_subnets.subnets.ids)]
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = true
  key_name                    = var.configure_ssh ? aws_key_pair.this.0.id : null
  tags                        = { "Name" : "${format("%s-backend-%s-%02d", var.lb_name, var.id, count.index + 1)}" }
  user_data                   = <<-USERDATA
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl daemon-reload
    systemctl enable --now nginx
    echo '<html><body><h1>'$(hostname)'</h1></body></html>' >/var/www/html/index.html
  USERDATA
}

resource "aws_elb_attachment" "clb_attachment" {
  count = length(aws_instance.backend)

  elb      = aws_elb.clb.id
  instance = aws_instance.backend[count.index].id
}

resource "tls_private_key" "this" {
  count = var.iam_cert ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "this" {
  count = var.iam_cert ? 1 : 0

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.this.0.private_key_pem

  subject {
    common_name = var.cert_dns_name
  }

  dns_names = [var.cert_dns_name]

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "this" {
  count = var.iam_cert ? 1 : 0

  name             = "test_cert"
  certificate_body = tls_self_signed_cert.this.0.cert_pem
  private_key      = tls_private_key.this.0.private_key_pem
}

resource "tls_private_key" "kp" {
  count = var.configure_ssh ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  count = var.configure_ssh ? 1 : 0

  key_name   = "kp"
  public_key = tls_private_key.kp.0.public_key_openssh
}
