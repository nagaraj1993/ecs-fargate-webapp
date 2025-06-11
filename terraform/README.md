terraform plan -var-file="environments/non-prod.tfvars" -var-file="secrets.tfvars"  
terraform apply -var-file="environments/non-prod.tfvars" -var-file="secrets.tfvars"  