# Configure provider
provider "aws" {
  region = var.aws_region
}

/* resource "aws_s3_bucket" "cicd_bucket" {
  bucket = "sn-jenkin-cicd-remote-state"
}

resource "aws_s3_object" "cicd_bucket_object" {
  bucket = aws_s3_bucket.cicd_bucket.id
  key    = "terraform/state"

} */

resource "aws_dynamodb_table" "dynamodb-terraform-lock" {
  name           = "terraform-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name               = "AWS-EC2FullAccess-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


# RSA key of size 4096 bits
resource "tls_private_key" "rsa-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.rsa-key.public_key_openssh
}

resource "local_file" "tf_key" {
  content  = tls_private_key.rsa-key.private_key_pem
  filename = var.file_name
}


# Attach AmazonEC2FullAccess policy to IAM role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Jenkins/Maven/Ansible server Instance.
resource "aws_instance" "Jenkins_instance" {
  ami                  = var.ami_jenkins
  instance_type        = "t2.medium"
  key_name             = var.key_pair_name
  security_groups      = ["jenkins-security-group"]
  iam_instance_profile = "ec2-instance-profile"
  user_data            = <<-EOF
                #!/bin/bash
                curl -fsSL https://github.com/snblaise/jenkin-cicd-end2end-project/blob/installationScripts/jenkens-install.sh | sudo bash
                EOF
  tags = {
    Name = "Jenkins/Maven/Ansible"
  }
}

# SonarQube Server Instance.
resource "aws_instance" "sonarqube_instance" {
  ami             = var.ami_sonarqube
  instance_type   = "t2.medium"
  key_name        = var.key_pair_name
  security_groups = ["sonarqube-security-group"]
  user_data       = <<-EOF
                #!/bin/bash
                curl -fsSL https://github.com/snblaise/jenkin-cicd-end2end-project/blob/installationScripts/sonarqube-install.sh | sudo bash
                EOF
  tags = {
    Name = "SonarQube"
  }
}

# Nexus Server Instance
resource "aws_instance" "nexus_instance" {
  ami             = var.ami_nexus
  instance_type   = "t2.medium"
  key_name        = var.key_pair_name
  security_groups = ["nexus-security-group"]
  user_data       = <<-EOF
                #!/bin/bash
                curl -fsSL https://github.com/snblaise/jenkin-cicd-end2end-project/blob/installationScripts/nexus-install.sh | sudo bash
                EOF
  tags = {
    Name = "Nexus"
  }
}

# Dev server instance
resource "aws_instance" "dev_instance" {
  count           = 1 # value can be modified during deployment.
  ami             = var.ami_dev
  instance_type   = "t2.micro"
  key_name        = var.key_pair_name
  security_groups = ["dev-security-group"]
  tags = {
    Name        = "Dev-Env-${count.index + 1}"
    Environment = "dev"
  }
}

# Staging Server instance
resource "aws_instance" "stage_instance" {
  ami             = var.ami_dev
  instance_type   = "t2.micro"
  key_name        = var.key_pair_name
  security_groups = ["dev-security-group"]
  tags = {
    Name        = "Stage-Env"
    Environment = "stage"
  }

}

# Prod server instance
resource "aws_instance" "prod_instance" {
  count           = 1 #modify value to meet the demand.
  ami             = var.ami_dev
  instance_type   = "t2.micro"
  key_name        = var.key_pair_name
  security_groups = ["dev-security-group"]
  tags = {
    Name        = "Prod-Env-${count.index + 1}"
    Environment = "prod"
  }

}

# Prometheus Server Instace 
resource "aws_instance" "promotheus_instance" {
  ami                  = var.ami_prometheus
  instance_type        = "t2.micro"
  key_name             = var.key_pair_name
  security_groups      = ["promotheus-security-group"]
  iam_instance_profile = "ec2-instance-profile"
  tags = {
    Name = "Promotheus"
  }
}

# Grafana Server Instace 
resource "aws_instance" "grafana_instance" {
  ami             = var.ami_grafana
  instance_type   = "t2.micro"
  key_name        = var.key_pair_name
  security_groups = ["grafana-security-group"]
  tags = {
    Name = "Grafana"
  }
}

# Splunk Server Instace 
resource "aws_instance" "splunk_instance" {
  ami             = var.ami_grafana
  instance_type   = "t2.micro"
  key_name        = var.key_pair_name
  security_groups = ["splunk-security-group"]
  tags = {
    Name = "Splunk"
  }
}

###############################
#       Security Groups       #
###############################

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-security-group"
  description = "Security group for Jenkins"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-security-group"
  description = "Security group for SonarQube"
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nexus_sg" {
  name        = "nexus-security-group"
  description = "Security group for Nexus"

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dev-stage-prod_sg" {
  name        = "dev-security-group"
  description = "Security group for Dev"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "promotheus_sg" {
  name        = "promotheus-security-group"
  description = "Security group for Promotheus"
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "grafana_sg" {
  name        = "grafana-security-group"
  description = "Security group for Grafana"
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "splunk_sg" {
  name        = "splunk-security-group"
  description = "Security group for Splunk"
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Egress rules (outgoing traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}