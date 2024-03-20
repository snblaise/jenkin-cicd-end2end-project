# Configure provider
provider "aws" {
  region = var.aws_region
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

# Jenkins/Maven/Ansible Instance.
resource "aws_instance" "Jenkins_instance" {
  ami           = var.ami_jenkins
  instance_type = "t2.micro"
  key_name      = var.key_pair_name
  security_groups = ["jenkins-security-group"]
  iam_instance_profile = "ec2-instance-profile"
  user_data     = <<-EOF
                #!/bin/bash
                curl -fsSL https://github.com/snblaise/jenkin-cicd-end2end-project/blob/installationScripts/jenkens-install.sh | sudo bash
                EOF
  tags = {
    Name = "Jenkins/Maven/Ansible"
  }
}



# Security Groups
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
        protocol    = "-1"  # Allow all outbound traffic
        cidr_blocks = ["0.0.0.0/0"]
  }
}

