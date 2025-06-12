Use this command to apply and remove AWS resouces using terraform:

terraform plan -var-file="environments/non-prod.tfvars" -var-file="secrets.tfvars"  
terraform apply -var-file="environments/non-prod.tfvars" -var-file="secrets.tfvars"  

Useful commands:
export AWS_PROFILE="vscode-user" 
git rebase -i HEAD~1
   
terraform force-unlock <LockID> #For example: bd42079d-713e-ad34-02b9-848bc51f2759 
rm -rf .terraform/                                                                                                                                     ✔  03:11:24 PM 
rm -f .terraform.lock.hcl
terraform workspace new prod
terraform workspace new non-prod   
terraform workspace show                                                                                             ✔  vscode-user eu-central-1   03:15:35 PM 
terraform workspace select non-prod  

ECR:
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 976863527497.dkr.ecr.eu-central-1.amazonaws.com
docker build -t mywebapp-non-prod-webapp .                                                                                                             ✔  03:11:24 PM 
docker tag mywebapp-non-prod-webapp:latest 976863527497.dkr.ecr.eu-central-1.amazonaws.com/mywebapp-non-prod-webapp:latest   
docker push 976863527497.dkr.ecr.eu-central-1.amazonaws.com/mywebapp-non-prod-webapp:latest      
docker images

For SSH: See Gemini chat
nano ~/.ssh/config 
cat ~/.ssh/config

