variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default     = "your-keypair-name"
}

variable "ami_jenkins" {
  description = "AMI for Jenkins instance"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}

variable "ami_sonarqube" {
  description = "AMI for SonarQube instance"
  default     = "ami-0ebc1ac6d1cfb23a9"  # Update with correct AMI ID
}

variable "ami_nexus" {
  description = "AMI for Nexus instance"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}

variable "ami_dev" {
  description = "AMI for Development instances"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}

variable "ami_stage" {
  description = "AMI for Stage instances"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}

variable "ami_prod" {
  description = "AMI for Production instances"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}

variable "ami_prometheus" {
  description = "AMI for Prometheus instance"
  default     = "ami-0ebc1ac6d1cfb23a9"  # Update with correct AMI ID
}

variable "ami_grafana" {
  description = "AMI for Grafana instance"
  default     = "ami-0ebc1ac6d1cfb23a9"  # Update with correct AMI ID
}

variable "ami_splunk" {
  description = "AMI for Splunk/Indexer instance"
  default     = "ami-0a91cd140a1fc148a"  # Update with correct AMI ID
}
