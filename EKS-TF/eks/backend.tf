terraform {
  backend "s3" {
    bucket = "my-ews-bucket-39343094"
    region = "ap-south-1"
    key = "DevOpsified-AWS/EKS-TF/terraform.tfstate"
    encrypt = true
  }
}