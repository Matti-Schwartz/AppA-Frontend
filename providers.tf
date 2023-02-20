# Configure the AWS Provider
provider "aws" {
  shared_config_files      = ["C:/Users/Matti/.aws/config"]
  shared_credentials_files = ["C:/Users/Matti/.aws/credentials"]
  region                   = "us-east-1"
}