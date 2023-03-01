# Configure the AWS Provider
provider "aws" {
  shared_credentials_files = "$HOME/.aws/credentials"
  region  = "us-east-1"
  profile = "default"
}