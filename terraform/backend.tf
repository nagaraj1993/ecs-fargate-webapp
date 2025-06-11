terraform {
  backend "s3" {
    bucket         = "awshandson-bucket-eu-central-1" # The bucket you created
    key            = "my-handson-project/terraform.tfstate"
    region         = "eu-central-1" # Region of the bucket
    encrypt        = true
    dynamodb_table = "terraform_state_lock" # Necessary if we work in team to establish locking mechanism
  }
}