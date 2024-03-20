terraform {
  backend "s3" {
    bucket         = "sn-jenkin-cicd-remote-state"
    key            = "terraform/state"
    region         = "us-east-1"
    profile        = "default"
    }
}
