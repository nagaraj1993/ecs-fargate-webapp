## For TF state locking
# resource "aws_dynamodb_table" "terraform_state_lock" {
#   name         = "terraform_state_lock"
#   hash_key     = "LockID"
#   billing_mode = "PAY_PER_REQUEST"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }