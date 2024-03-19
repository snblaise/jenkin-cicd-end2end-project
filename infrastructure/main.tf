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

# Attach AmazonEC2FullAccess policy to IAM role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# EC2 Instances
resource "aws_instance" "Jenkins_instance" {
  ami           = var.ami_jenkins
  instance_type = "t2.medium"
  key_name      = var.key_name
  security_groups = ["jenkins-security-group"]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  user_data     = file("jenkins-install.sh")  # Update with correct file path
  tags = {
    Name = "Jenkins/Maven/Ansible"
  }
}

resource "aws_instance" "sonarqube_instance" {
  ami           = var.ami_sonarqube
  instance_type = "t2.medium"
  key_name      = var.key_name
  security_groups = ["sonarqube-security-group"]
  user_data     = file("sonarqube-install.sh")  # Update with correct file path
  tags = {
    Name = "SonarQube"
  }
}

resource "aws_instance" "nexus_instance" {
  ami           = var.ami_nexus
  instance_type = "t2.medium"
  key_name      = var.key_name
  security_groups = ["nexus-security-group"]
  user_data     = file("nexus-install.sh")  # Update with correct file path
  tags = {
    Name = "Nexus"
  }
}

resource "aws_instance" "dev_instance" {
  ami               = var.ami_dev
  instance_type     = "t2-micro"
  key_name          = var.key_name
  security_groups   = ["dev-stag-prod_sg"]
  tags              = {
    Name = "Dev-Env"
    Environment = "dev"
  }
  
}

resource "aws_instance" "stage_instance" {
  ami               = var.ami_dev
  instance_type     = "t2-micro"
  key_name          = var.key_name
  security_groups   = ["dev-stag-prod_sg"]
  tags              = {
    Name = "Stage-Env"
    Environment = "stage"
  }
  
}

resource "aws_instance" "prod_instance" {
  ami               = var.ami_dev
  instance_type     = "t2-micro"
  key_name          = var.key_name
  security_groups   = ["dev-stag-prod_sg"]
  tags              = {
    Name = "Prod-Env"
    Environment = "prod"
  }
  
}

# Define other EC2 instances similarly

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
        protocol    = "-1"  # Allow all outbound traffic
        cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nexus_sg" {
  name        = "jenkins-security-group"
  description = "Security group for Jenkins"

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
        protocol    = "-1"  # Allow all outbound traffic
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
        protocol    = "-1"  # Allow all outbound traffic
        cidr_blocks = ["0.0.0.0/0"]
  }
}
# Define other security groups similarly

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
